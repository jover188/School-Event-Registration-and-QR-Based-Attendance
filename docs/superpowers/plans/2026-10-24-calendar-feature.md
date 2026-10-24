# Attendify Calendar Feature — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a shared event calendar screen to the Flutter app that renders real events from the existing Laravel API, integrates into every role's navigation shell, and reuses all existing design-system primitives, notification infrastructure, and role-based access control.

**Architecture:** A new `CalendarScreen` widget (Flutter, `table_calendar` package) replaces no existing screen but is inserted as an additional destination in each role's `_destinations` list. The backend already supports date-range filtering via `date_from`/`date_to` query params on `GET /api/v1/events`; no new endpoint is required. Notification delivery for calendar events reuses the existing `NotificationService` which is already triggered by `EventController` on publish/cancel; no backend changes are needed. FCM background delivery depends on existing per-device token registration and is documented but not modified.

**Tech Stack:** Flutter 3.x / Dart 3.x · `table_calendar ^3.x` (new dependency) · `intl ^0.20.3` (already present) · `shadcn_ui ^0.57.2` (already present) · Laravel 11 `GET /api/v1/events?date_from=&date_to=` (existing endpoint, existing filters) · AetherUI `AppDesignTokens`, `AppShell`, `AppDestinationStack`, `AppPressable`, `EventCard`, `AppButton`

**Spec:** `context.md`, `AGENTS.md`, and the existing `REST_API_Specification.md` in the project root.

---

## Global Constraints

- Flutter binary: `flutter` (Windows path: whatever is on `PATH`; project at `mobile/`)
- Dart SDK: `>=3.0.0 <4.0.0`
- `table_calendar`: `^3.1.2` (latest stable, compatible with Flutter 3.x)
- All new Dart files must pass `flutter analyze` with **0 issues**
- All new test files must pass `flutter test` with **0 failures**
- Backend tests must pass `php artisan test` (SQLite in-memory) with **0 failures** — no backend changes are planned; run tests only to confirm no regression
- Do NOT add AI/LLM runtime features (AGENTS.md §2 rule 9)
- Do NOT self-register students; student accounts are pre-provisioned
- Role filter: students see only `published`/`ongoing`; organizer/admin/management see all statuses — this is enforced by the existing backend; the Flutter calendar must not duplicate or bypass it
- Existing `EventDetailScreen` is the sole event detail view; do not create a second one
- Calendar must follow AetherUI tokens (`AppDesignTokens.light`/`.dark`), `AppPressable`, and `NoSplash.splashFactory`

---

## Review Focus

1. **Rapid month switching** (user taps forward/back 12 months quickly): calendar must not fire >1 concurrent API requests per focused month; debounce or cancel-previous logic required.
2. **Empty months** (no events in the selected month/week): must show a clear empty state below the calendar, not a blank area.
3. **Role boundary** (management user opens calendar): must see all statuses the backend returns, not be blocked by student-only filter on the Flutter side.
4. **Large text scale** (`textScaleFactor >= 1.5`): event dot indicators must remain visible; event list tiles must not overflow.
5. **Notification tap → calendar day**: a push notification with `payload.event_date` must deep-link to the correct day on the calendar and auto-open that event's `EventDetailScreen`.

---

## File Structure

### New files
| File | Responsibility |
|---|---|
| `mobile/lib/screens/common/calendar_screen.dart` | Calendar UI — month/week toggle, date navigation, event dots, selected-day event list, opens `EventDetailScreen` |
| `mobile/test/calendar_screen_test.dart` | Widget tests for `CalendarScreen` |

### Modified files
| File | Change |
|---|---|
| `mobile/pubspec.yaml` | Add `table_calendar: ^3.1.2` dependency |
| `mobile/lib/screens/student/student_dashboard_screen.dart` | Add `calendar` destination; wire to `CalendarScreen` |
| `mobile/lib/screens/organizer/organizer_dashboard_screen.dart` | Add `calendar` destination; wire to `CalendarScreen` |
| `mobile/lib/screens/management/management_dashboard_screen.dart` | Add `calendar` destination; wire to `CalendarScreen` |
| `mobile/lib/screens/admin/admin_dashboard_screen.dart` | Add `calendar` destination; wire to `CalendarScreen` |

No backend files are modified. No new API constants are needed; `ApiConstants.events` with `date_from`/`date_to` query params is sufficient.

---

## Task 1: Add `table_calendar` dependency

**Files:**
- Modify: `mobile/pubspec.yaml`

**Interfaces:**
- Produces: `table_calendar` importable as `package:table_calendar/table_calendar.dart`

- [ ] **Step 1: Add dependency**

  In `mobile/pubspec.yaml`, under `dependencies:`, add:
  ```yaml
  table_calendar: ^3.1.2
  ```

- [ ] **Step 2: Fetch packages**

  Run from `mobile/`:
  ```
  flutter pub get
  ```
  Expected: exits 0, `table_calendar` appears in `.dart_tool/package_config.json`

- [ ] **Step 3: Verify analysis still passes**

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 4: Commit**

  ```
  git add mobile/pubspec.yaml mobile/pubspec.lock
  git commit -m "chore(mobile): add table_calendar dependency"
  ```

---

## Task 2: Implement `CalendarScreen`

**Files:**
- Create: `mobile/lib/screens/common/calendar_screen.dart`

**Interfaces:**
- Consumes:
  - `ApiClient().get(ApiConstants.events, queryParams: {'date_from': 'YYYY-MM-DD', 'date_to': 'YYYY-MM-DD', 'per_page': '100'})` → `ApiResponse` with `data` as `List` of event JSON maps
  - `EventModel.fromJson(Map<String, dynamic>)` from `models/event_model.dart`
  - `EventDetailScreen({eventId, event})` from `screens/student/event_detail_screen.dart`
  - `AppDesignTokens` via `context.design`
  - `AppPressable`, `AppButton`, `AppSpinner`, `EmptyStateView`, `ErrorStateView`, `EventCard`, `SectionHeader`, `StatusBadge` from `core/widgets/`
- Produces:
  - `class CalendarScreen extends StatefulWidget` with `const CalendarScreen({super.key, this.embedded = false, this.initialEvents})`
  - `embedded` — when `true`, the widget is hosted inside `AppDestinationStack`; when `false`, it can be pushed as a standalone route
  - `initialEvents` — `List<EventModel>?` fixture injection for widget tests

**Calendar data model (internal):**
- `Map<DateTime, List<EventModel>> _eventsByDay` — keyed by `DateTime(year, month, day)` (UTC-normalised, no time component)
- `DateTime _focusedDay` — currently displayed month/week; initialised to `DateTime.now()`
- `DateTime? _selectedDay` — day tapped by user; null means no selection
- `CalendarFormat _calendarFormat` — `CalendarFormat.month` or `CalendarFormat.week`
- `bool _isLoading`, `String? _errorMessage`

**Fetch strategy:**
- On init and on focused-month change: call `_loadEventsForMonth(DateTime month)`
- `_loadEventsForMonth` computes `date_from = first day of month` and `date_to = last day of month` (ISO-8601 `YYYY-MM-DD`), then calls `GET /api/v1/events` with those params and `per_page=100`
- Cancel-previous: track `_currentMonthKey` (a `String` like `'2026-10'`); ignore responses that arrive for a stale month
- On success: merge returned events into `_eventsByDay` (do NOT clear the map first — keep adjacent months in cache)
- On error: set `_errorMessage`; do not clear existing cached events

**UI layout:**
```
[Header: month/week toggle buttons aligned right]
[TableCalendar]
  - format: _calendarFormat
  - focusedDay: _focusedDay
  - selectedDayPredicate: (day) => isSameDay(day, _selectedDay)
  - eventLoader: (day) => _eventsByDay[DateTime(day.year, day.month, day.day)] ?? []
  - calendarBuilders: markerBuilder → 1–3 teal dots (d.primary) below date cell
  - onDaySelected: update _selectedDay, _focusedDay
  - onPageChanged: update _focusedDay, trigger _loadEventsForMonth
  - headerStyle: hide built-in arrows (use custom Today button + Flutter navigation)
[Today button — small AppButton.ghost — resets _focusedDay and _selectedDay to now]
[Divider]
[Selected-day event list OR loading OR empty state]
  - If _isLoading and _eventsByDay.isEmpty → AppSpinner
  - If _errorMessage != null and _eventsByDay.isEmpty → ErrorStateView(onRetry: ...)
  - If _selectedDay is null → EmptyStateView("Select a day to see events")
  - If events for selected day are empty → EmptyStateView("No events on this day")
  - Else → ListView of EventCard widgets (showEventStatusBadge: true, showCapacity: true)
    - onTap → Navigator.push(EventDetailScreen(eventId: event.id, event: event))
```

**Theming:**
- Use `context.design` (`AppDesignTokens`) for all colors, spacing, and radius
- Dot color: `d.primary` (teal `#14B8A6`)
- Calendar background: `d.card`
- Selected day decoration: filled circle with `d.primary`
- Today decoration: outlined circle with `d.primary`
- `calendarStyle.outsideDaysVisible = false`
- `daysOfWeekStyle.weekdayStyle` and `weekendStyle` use `d.supporting` text style
- Table calendar header: hide default; replace with a `Row` above `TableCalendar` showing the current month/year in `d.sectionTitle` style + today button

- [ ] **Step 1: Write failing widget tests** (see Task 3 below, write test file first)

- [ ] **Step 2: Run tests to verify they fail**

  ```
  flutter test test/calendar_screen_test.dart
  ```
  Expected: compilation error (CalendarScreen not found)

- [ ] **Step 3: Implement `CalendarScreen` in `mobile/lib/screens/common/calendar_screen.dart`**

  Key signatures:
  ```dart
  class CalendarScreen extends StatefulWidget {
    const CalendarScreen({super.key, this.embedded = false, this.initialEvents});
    final bool embedded;
    final List<EventModel>? initialEvents;
    @override State<CalendarScreen> createState() => _CalendarScreenState();
  }
  ```

  ```dart
  class _CalendarScreenState extends State<CalendarScreen> {
    final Map<DateTime, List<EventModel>> _eventsByDay = {};
    DateTime _focusedDay = DateTime.now();
    DateTime? _selectedDay;
    CalendarFormat _calendarFormat = CalendarFormat.month;
    bool _isLoading = false;
    String? _errorMessage;
    String _currentMonthKey = '';

    @override void initState() { ... }
    void _loadEventsForMonth(DateTime month) async { ... }
    List<EventModel> _getEventsForDay(DateTime day) { ... }
    void _onDaySelected(DateTime selectedDay, DateTime focusedDay) { ... }
    void _onFormatChanged(CalendarFormat format) { ... }
    void _onPageChanged(DateTime focusedDay) { ... }
    void _goToToday() { ... }
    void _openEventDetail(EventModel event) { ... }
    @override Widget build(BuildContext context) { ... }
  }
  ```

  `_loadEventsForMonth` algorithm:
  1. Compute `monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}'`
  2. If `_currentMonthKey == monthKey` return (already loading or loaded)
  3. Set `_currentMonthKey = monthKey`, `_isLoading = true`, `_errorMessage = null`
  4. Compute `dateFrom`, `dateTo` (last day = `DateTime(month.year, month.month + 1, 0)`)
  5. Await `ApiClient().get(ApiConstants.events, queryParams: {...})`
  6. If widget is not mounted, return
  7. On success: iterate items, parse `EventModel.fromJson`, bucket into `_eventsByDay` by `DateTime(e.year, e.month, e.day)` (parsed from `event.eventDate`)
  8. On error: set `_errorMessage`
  9. Set `_isLoading = false`, call `setState`

- [ ] **Step 4: Run tests to verify they pass**

  ```
  flutter test test/calendar_screen_test.dart
  ```
  Expected: all pass

- [ ] **Step 5: Run full analysis**

  ```
  flutter analyze
  ```
  Expected: `No issues found!`

- [ ] **Step 6: Commit**

  ```
  git add mobile/lib/screens/common/calendar_screen.dart
  git commit -m "feat(mobile): implement CalendarScreen with table_calendar"
  ```

---

## Task 3: Write `CalendarScreen` widget tests

**Files:**
- Create: `mobile/test/calendar_screen_test.dart`

**Interfaces:**
- Consumes: `CalendarScreen` (Task 2), `EventModel`, existing `AppTestHost` from `test/helpers/app_test_host.dart` (or equivalent test scaffold pattern used in existing tests)

- [ ] **Step 1: Implement test file `mobile/test/calendar_screen_test.dart`**

  Tests to include (each as a separate `testWidgets` block):

  ```dart
  // 1. Renders calendar grid and header
  testWidgets('CalendarScreen renders month grid', (tester) async {
    await tester.pumpWidget(/* wrap in ShadApp.custom + AppTestHost */);
    await tester.pumpWidget(CalendarScreen(initialEvents: []));
    // Expect: finds a widget with text matching current month name
  });

  // 2. Shows empty state when a day with no events is selected
  testWidgets('CalendarScreen shows empty state for day with no events', ...);

  // 3. Shows EventCard for day with injected events
  testWidgets('CalendarScreen renders event card for selected day with events', ...);
  // Use initialEvents with one EventModel whose eventDate == today
  // Tap today cell, expect EventCard showing event.title

  // 4. Today button resets focused day
  testWidgets('CalendarScreen today button resets focus to today', ...);

  // 5. Format toggle switches between month and week
  testWidgets('CalendarScreen toggles between month and week view', ...);
  ```

  Use fixture data (`initialEvents` list) so no real HTTP calls are made.

  Look at `mobile/test/student_flow_layout_test.dart` to copy the test scaffold (`pumpWidget` setup, `ShadApp.custom` wrapper, `AppTheme`).

- [ ] **Step 2: Run tests**

  ```
  flutter test test/calendar_screen_test.dart -v
  ```
  Expected: all 5 tests pass

- [ ] **Step 3: Commit**

  ```
  git add mobile/test/calendar_screen_test.dart
  git commit -m "test(mobile): add CalendarScreen widget tests"
  ```

---

## Task 4: Wire `CalendarScreen` into all role dashboards

**Files:**
- Modify: `mobile/lib/screens/student/student_dashboard_screen.dart`
- Modify: `mobile/lib/screens/organizer/organizer_dashboard_screen.dart`
- Modify: `mobile/lib/screens/management/management_dashboard_screen.dart`
- Modify: `mobile/lib/screens/admin/admin_dashboard_screen.dart`

**Interfaces:**
- Consumes: `CalendarScreen` from `../common/calendar_screen.dart`
- Produces: `'calendar'` destination available in each role's `AppDestinationStack`

**Changes per dashboard:**

For **each** of the four dashboard files:

1. Add import: `import '../common/calendar_screen.dart';`
2. Add to the `_destinations` list constant (insert after the primary home destination, before any secondary ones):
   ```dart
   AppDestination(
     id: 'calendar',
     label: 'Calendar',
     icon: LucideIcons.calendarDays,
   ),
   ```
3. Add to the `AppDestinationStack.builders` map:
   ```dart
   'calendar': (_) => const CalendarScreen(embedded: true),
   ```
4. Update `_currentTitle` (or equivalent title getter) to include:
   ```dart
   'calendar' => 'Event Calendar',
   ```

**Student dashboard** — insert `calendar` destination between `events` and `registrations`.
**Organizer dashboard** — insert `calendar` destination between `events` and `reports`.
**Management dashboard** — inspect file, add in a sensible position (after main dashboard view).
**Admin dashboard** — inspect file, add in a sensible position.

- [ ] **Step 1: Read each dashboard file to find exact insertion points**

- [ ] **Step 2: Apply changes to `student_dashboard_screen.dart`**

- [ ] **Step 3: Apply changes to `organizer_dashboard_screen.dart`**

- [ ] **Step 4: Apply changes to `management_dashboard_screen.dart`**

- [ ] **Step 5: Apply changes to `admin_dashboard_screen.dart`**

- [ ] **Step 6: Run analysis**

  ```
  flutter analyze
  ```
  Expected: `No issues found!`

- [ ] **Step 7: Run all Flutter tests**

  ```
  flutter test
  ```
  Expected: all 59+ tests pass (54 existing + 5 new)

- [ ] **Step 8: Commit**

  ```
  git add mobile/lib/screens/student/student_dashboard_screen.dart \
          mobile/lib/screens/organizer/organizer_dashboard_screen.dart \
          mobile/lib/screens/management/management_dashboard_screen.dart \
          mobile/lib/screens/admin/admin_dashboard_screen.dart
  git commit -m "feat(mobile): add Calendar destination to all role dashboards"
  ```

---

## Task 5: Backend regression check

**Files:**
- No changes — verification only

**Interfaces:**
- Consumes: existing `GET /api/v1/events?date_from=&date_to=` route in `backend/routes/api.php` and `EventController::index`

- [ ] **Step 1: Verify date-range filters work**

  From `backend/`:
  ```
  php artisan test --filter EventController
  ```
  Expected: passes (or no test class — then confirm the filter params exist in `EventController::index` lines 41–47 which already handle `date_from` and `date_to`)

- [ ] **Step 2: Run full backend test suite**

  ```
  php artisan test
  ```
  Expected: 44 tests, 226 assertions, 0 failures

- [ ] **Step 3: Commit (no code changes — just log)**

  No commit needed if no changes were made. Document result in PR description.

---

## Task 6: Notification tap deep-link to calendar day

**Files:**
- Modify: `mobile/lib/screens/common/notifications_screen.dart`

**Interfaces:**
- Consumes: existing `NotificationsScreen`, notification `payload` JSON with optional `event_id` and `event_date` fields
- Produces: tapping a notification with `payload.event_id` navigates to `EventDetailScreen(eventId: payload['event_id'])`; tapping one with `payload.event_date` (no `event_id`) opens `CalendarScreen` scrolled to that date (nice-to-have, implement if payload structure supports it)

- [ ] **Step 1: Read `mobile/lib/screens/common/notifications_screen.dart` to understand existing tap handling**

- [ ] **Step 2: Locate the notification tap handler**

  Find the `onTap` or `_handleNotificationTap` method (or the list tile `onTap`).

- [ ] **Step 3: Add event navigation**

  If `payload` is a `Map` and contains `event_id` (non-null int), push `EventDetailScreen(eventId: payload['event_id'])`.
  Existing tap that marks as read must still fire first.

- [ ] **Step 4: Write a widget test for notification tap navigation**

  In an existing or new test file, add:
  ```dart
  testWidgets('notification with event_id navigates to EventDetailScreen', (tester) async {
    // build NotificationsScreen with initialNotifications fixture
    // containing one notification with payload: '{"event_id": 42}'
    // tap the notification tile
    // expect EventDetailScreen in the widget tree
  });
  ```

- [ ] **Step 5: Run tests**

  ```
  flutter test
  ```
  Expected: all pass

- [ ] **Step 6: Run analysis**

  ```
  flutter analyze
  ```

- [ ] **Step 7: Commit**

  ```
  git add mobile/lib/screens/common/notifications_screen.dart
  git commit -m "feat(mobile): notification tap navigates to EventDetailScreen"
  ```

---

## Task 7: Final verification

- [ ] **Step 1: Run full Flutter test suite**

  ```
  flutter test --coverage
  ```
  Expected: 0 failures

- [ ] **Step 2: Run Flutter analysis**

  ```
  flutter analyze
  ```
  Expected: `No issues found!`

- [ ] **Step 3: Run backend tests**

  From `backend/`:
  ```
  php artisan test
  ```
  Expected: 44 tests, 226 assertions, 0 failures

- [ ] **Step 4: Build web target (smoke)**

  From `mobile/`:
  ```
  flutter build web --no-tree-shake-icons
  ```
  Expected: build succeeds with no errors

- [ ] **Step 5: Commit final state**

  ```
  git add -A
  git commit -m "feat: Attendify Calendar — all tasks complete, tests green"
  ```

---

## Setup Notes (for developers running this for the first time)

- **FCM background delivery**: existing setup; no changes needed. Ensure `firebase_options.dart` is present (generated by `flutterfire configure`) and `google-services.json` is in `android/app/` for push delivery on Android. The `NotificationService` backend class already dispatches FCM tokens from `device_tokens`; only foreground in-app notifications are guaranteed without native Firebase integration in Flutter.
- **`table_calendar` version**: if `^3.1.2` is unavailable, use the latest `3.x` stable. The API used (`TableCalendar`, `CalendarFormat`, `calendarBuilders`, `headerStyle`) is stable across `3.x`.
- **Date parsing**: `EventModel.eventDate` is a `String` (`YYYY-MM-DD`). Parse with `DateTime.parse(event.eventDate)` and normalise to `DateTime(y, m, d)` for map keys.
