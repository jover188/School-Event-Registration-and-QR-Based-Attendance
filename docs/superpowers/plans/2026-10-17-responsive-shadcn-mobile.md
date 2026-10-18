# Responsive shadcn Flutter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the existing 21-screen Flutter client into a consistent shadcn interface that adapts to phones, tablets, and desktop/web.

**Architecture:** Keep the existing role entrypoints, `ApiClient`, models, and single navigator. Add one token source, a shadcn/Material theme bridge, reusable responsive components, and a controlled role shell. Migrate complete role journeys after the shared foundation.

**Tech Stack:** Existing Flutter/Dart toolchain; `shadcn_ui ^0.57.2`; `intl ^0.20.3`; existing QR, HTTP, storage, and image packages.

**Spec:** [Responsive shadcn Flutter design](../specs/2026-10-17-responsive-shadcn-mobile-design.md)

**Status:** Proposed implementation sequence. This planning task changes documentation only. Review the design before beginning the UI refactor.

## Global Constraints

- Exact user palette: `#4338CA`, `#EC4899`, `#22D3EE`, `#FDF4FF`, `#18181B`; use the supporting token values in the spec.
- Use the existing `shadcn_ui` dependency; no replacement UI library, font download, router, state-management, or layout-scaling package.
- Light theme only. Use one token source and a `context.design` accessor for new application styling.
- Width classes: `<600`, `600–1023`, `>=1024` logical pixels; navigation widths 88 and 240; content maximum 1200.
- All interactive targets at least 48×48; respect text scaling, keyboard insets, safe areas, and reduced motion.
- One root navigator; preserve its key, session termination, institutional login, role routing, and existing back behavior.
- Management cannot mutate events, registrations, attendance, or users. Existing account and notification operations retain their separate permissions.
- The server owns attendance results, capacity, waiting-list promotion, QR revocation, and event authorization.
- No backend/schema/API changes. No offline mutation queue, new cancellation-review workflow, export persistence feature, or deep-link migration in this refactor.
- Preserve the current `mobile/pubspec.yaml` and lockfile installation changes. Do not overwrite unrelated work.
- Verification commands run from `mobile/` with `/home/thea/development/flutter/bin/flutter`.

## Review Focus

1. Resize during typing, searching, or scanning: keep controller state and prevent duplicate requests. Owned by Tasks 2, 3, 5.
2. Long text, 320-wide screens, 2× text, and short landscape: keep actions and QR/scan results reachable. Owned by Tasks 2–5.
3. Session termination with a modal or destination open: return to login without leaving protected content reachable. Owned by Tasks 1–2.
4. Shared staff screens opened by management: no cancellation, manual marking, correction, or scan actions. Owned by Tasks 5 and 7.
5. Partial network failures and unsupported cameras: preserve truthful state and provide recovery. Owned by Tasks 4, 5, 7.

## File structure and ownership

| File(s) | Responsibility |
|---|---|
| `mobile/lib/core/theme/app_tokens.dart` (new) | Canonical palette, semantic status pairs, spacing, type, shape, motion, layout constants, and `AppDesignTokens` extension |
| `mobile/lib/core/theme/app_theme.dart` | Derive shadcn and Material themes; temporary legacy aliases |
| `mobile/lib/core/layout/responsive_layout.dart` (new) | Width classification, constrained pages, intrinsic-height responsive collections |
| `mobile/lib/core/navigation/app_destination.dart`, `mobile/lib/core/widgets/app_shell.dart` (new) | Role destination definitions and controlled adaptive shell |
| `mobile/lib/core/widgets/app_button.dart`, `app_pressable.dart` (new) | Shared button sizing/loading; accessible non-button interaction surfaces |
| Existing six `mobile/lib/core/widgets/*.dart` components | Retain their public behavior while applying new tokens and shadcn rendering |
| Existing `mobile/lib/screens/{auth,common,student,organizer,admin,management}/` | Migrate role workflows; extract body widgets adjacent to their screens as needed |
| `mobile/test/support/app_test_host.dart` (new) | Production-equivalent shadcn test host and viewport setup/cleanup |
| `mobile/test/{core,screens}/` (new test files below) | Behavioral, responsive, and accessibility regression tests |
| `mobile/lib/main.dart` | Root theme bridge and existing session/navigator ownership |

Extract presentation bodies only when shell composition or tests need them. Keep network calls in the existing state owners. Presentation bodies receive real models, loading/error state, and callbacks. Do not create a new data layer merely to test the visual migration.

## Task 1: Theme bridge and common controls

**Files:** Create `core/theme/app_tokens.dart`, `core/widgets/app_button.dart`, `core/widgets/app_pressable.dart`, `test/support/app_test_host.dart`, `test/core/app_theme_test.dart`, `test/core/app_controls_test.dart`. Modify `core/theme/app_theme.dart`, `main.dart`, and the host setup in `test/widget_test.dart`. Paths are relative to `mobile/`.

**Interfaces:**

- `AppTheme.lightTheme` continues to return `ThemeData`; add `AppTheme.shadTheme` returning `ShadThemeData`.
- `AppDesignTokens extends ThemeExtension<AppDesignTokens>` provides the spec's named roles; `BuildContext.design` retrieves it.
- `AppButton({required String label, VoidCallback? onPressed, bool isLoading = false, AppButtonVariant variant = AppButtonVariant.primary})`; enum values `primary`, `outline`, `ghost`, `destructive`.
- `AppPressable({required Widget child, required String semanticLabel, VoidCallback? onPressed, bool selected = false})` handles non-button interactions.
- `AppTestHost({required Widget child})` mounts the same theme bridge as production. Tests control viewport and `MediaQuery` separately.

- [ ] Add failing integration tests: a shadcn button and dialog inherit the same custom scheme; Material routes retain localization and the navigator key; dialogs/toasts can find their overlay host.
- [ ] Add behavior tests: button loading blocks repeat callbacks; a disabled pressable ignores pointer/keyboard input; Enter and Space each activate once; focus is visible and labeled; reduced motion removes the custom press animation.
- [ ] Implement the token source and theme mapping from the design. Legacy `AppColors`/`AppTheme`/spacing/radius/typography references forward to canonical definitions until migrated.
- [ ] Mount `ShadApp.custom(appBuilder: ...)` around the current `MaterialApp`, and put `ShadAppBuilder` in its builder. Check installed 0.57.2 localization, scroll behavior, and overlay requirements. Explicitly use light mode.
- [ ] Preserve `navigatorKey`, `_resolveInitialScreen`, the single-session callback, and login routing. Ensure the initial resolution future is stable across theme/window rebuilds.
- [ ] Run `flutter test test/core/app_theme_test.dart test/core/app_controls_test.dart` and the existing suite. Verify session-expiry recovery in a local authenticated walkthrough. Record results before moving on.

## Task 2: Responsive foundation and shell

**Files:** Create `core/layout/responsive_layout.dart`, `core/navigation/app_destination.dart`, `core/widgets/app_shell.dart`, `test/core/responsive_layout_test.dart`, `test/core/app_shell_test.dart`, `test/core/shared_widgets_test.dart`. Modify all six existing shared widget files.

**Interfaces:**

- `enum AppWindowClass { compact, medium, expanded }`; `AppWindowClass windowClassFor(double width)`.
- `AppResponsivePage({required Widget child, double maxWidth = 1200})` applies class-based padding and a width cap.
- `ResponsiveCardSliver({required int itemCount, required IndexedWidgetBuilder itemBuilder, double minItemWidth = 300, int maxColumns = 3})` builds lazy intrinsic-height rows using local sliver constraints.
- `AppDestination({required String id, required String label, required IconData icon, bool compactPrimary = true})`.
- `AppShell({required String title, required List<AppDestination> destinations, required String selectedId, required ValueChanged<String> onDestinationSelected, required Widget body, List<Widget> actions = const []})`. The caller owns selection, data, and page state; the shell never requests data.
- Preserve constructors for `EventCard`, `StatMetricCard`, `StatusBadge`, `SectionHeader`, `EmptyStateView`, `ErrorStateView`.

- [ ] Add failing tests for classification at 599/600/1023/1024 and navigation switching at those widths; assert all destinations remain reachable and the selected ID persists.
- [ ] Test 320×568 and 844×390 at 2× text with long titles, metric labels, status labels, and errors. Assert no overflow, no lost actions, and correct focus/semantic labels.
- [ ] Implement content caps and grid rules from the spec. Use `SliverLayoutBuilder` for sliver dimensions; do not calculate inner card columns from the full window width.
- [ ] Implement the shell with one destination model for bottom navigation, rail, sidebar, and the compact More sheet. Navigation is controlled by IDs, not index assumptions that change with width.
- [ ] Restyle shared widgets with shadcn components and intrinsic heights. If a card has independent trailing actions, make its main information area the navigation target instead of nesting buttons inside a whole-card pressable.
- [ ] Test a shell with a stateful body: type a search, scroll, open a destination, resize, and return. Confirm state retention; session termination still clears access through the root navigator.
- [ ] Run `flutter test test/core/`; inspect a fixture page at 390, 768, and 1440 widths before role migration.

## Task 3: Authentication and shared account screens

**Files:** Modify `screens/auth/login_screen.dart`, `screens/common/profile_screen.dart`, `notifications_screen.dart`, `notification_preferences_screen.dart`. Create `test/screens/account_layout_test.dart`.

**Consumes:** Theme, buttons, page constraints, and feedback components from Tasks 1–2. **Produces:** Existing screen constructors and callback/navigation behavior, with responsive content.

- [x] Add regression tests for institutional login controls (no self-registration, no self-service forgot-password), password visibility, first-invalid-field focus, and retained input after resize or a rejected submission. Reuse existing form tests where they already prove these behaviors.
- [x] Apply 440-wide auth and 720-wide profile caps. Keep the entire form scrollable above keyboard insets; persistent labels and errors must wrap.
- [x] Keep existing validators and autofill behavior. Use shadcn inputs only with an equivalent validation/controller integration; do not substitute `ShadForm` mechanically for a working `Form`.
- [x] Restyle the inbox and preferences; preserve read/unread actions, retention copy where present, and locked mandatory notifications with explanations.
- [x] Test keyboard-open, 320 width, short landscape, and 2× text. Verify profile upload still uses the existing cross-platform byte/path behavior.
- [x] Run `flutter test test/screens/account_layout_test.dart test/widget_test.dart`; inspect login with the keyboard visible.

## Task 4: Student journey

**Files:** Modify all five `screens/student/*.dart` files. Create `test/screens/student_flow_layout_test.dart` and `test/screens/permanent_qr_layout_test.dart`. Extract `screens/student/widgets/student_events_content.dart` if needed for presentation testing.

**Consumes:** `AppShell`, `ResponsiveCardSliver`, existing `EventModel` and API responses. **Produces:** Student destinations with stable IDs `events`, `registrations`, `qr`, `history`; existing detail routes remain available.

- [ ] Add tests with registered, waiting-list, full, cancelled, and empty event fixtures. Confirm correct server-backed status labels and reachable allowed actions.
- [ ] Reorganize the dashboard into the four destinations. Store their bodies/controllers above responsive branches; lazily initialize destinations and keep loaded bodies alive with stable keys.
- [ ] Use one scroll region for the event heading, metrics, search, and cards. Keep profile and notifications in the shared header. Use loaded data only; do not invent a next-event recommendation or event categories.
- [ ] Migrate details and registrations with clear primary action, consequence confirmations, and the responsive action-pane rules. Distinguish a waiting-list outcome from confirmed registration.
- [ ] Size the permanent QR from available width, capped at 280, with a square black/white render and explicit quiet zone. At 320 width, reduce surrounding decoration before reducing the usable code. Show the code in a scrollable layout, not a shrinking `FittedBox` around the whole page.
- [ ] Preserve reissue confirmation and server response handling. History uses readable rows/cards and actual attendance states.
- [ ] Test partial dashboard failure, long event names, 2× text, tab/resize state retention, and QR fitting at 320. Confirm decoded test QR data equals the opaque token if a decoding harness already exists; otherwise schedule a physical scan check in Task 8 without adding a decoder dependency.
- [ ] Run the two student test files and inspect events, details, and QR at compact/medium/expanded sizes.

## Task 5: Organizer and shared attendance workflows

**Files:** Modify all five `screens/organizer/*.dart` files. Create `test/screens/organizer_layout_test.dart`, `test/screens/scanner_states_test.dart`, `test/screens/attendance_permissions_test.dart`. Extract `screens/organizer/widgets/scan_result_content.dart` for a camera-free result fixture if needed.

**Consumes:** Existing event models, scan responses, shell, forms, cards. **Produces:** Organizer destinations `overview`, `events`, `reports`; the existing `canCancel` and `canCorrect` contracts remain intact.

- [ ] Test form retention and the distinct save-draft/submit actions. Test attendance fixtures with correction permitted and denied; a reason remains mandatory.
- [ ] Separate overview metrics from the owned-event destination without duplicating fetch state. Keep creation, editing, submission, cancellation requests, staff cancellation, manual attendance marking, and corrections reachable.
- [ ] Group event fields into details, schedule, attendance rules. Use two columns only at local width 640+ and text scale below 1.5. Keep descriptions/errors full width.
- [ ] Restyle registration and attendance lists with searchable records, filters, metrics, and explicit refresh. Keep their read-only flags and use “Attendance” rather than implying continuous live updates.
- [ ] Make scan controls responsive and event-scoped. Disable scan entry for event states other than published/ongoing with readable explanation; server checks remain authoritative.
- [ ] Calculate the reticle from available width and height. Use a scrollable result sheet on compact windows and a constrained result pane when wide enough. Keep photo/name/ID/status and check-in or check-out time visible. Preserve camera switch/flash when supported and “Scan next” after result review.
- [ ] Add camera-denied, camera-unavailable, request-in-progress, rejected-scan, and successful-check-out fixtures. On unsupported Linux, do not instantiate the camera plugin. Keep the existing submission lock and controller lifetime independent of layout branches.
- [ ] Test mode/result labels, callback locking, large names, 844×390 at 2× text, and management's lack of cancellation/manual-mark/correction actions. Plugin behavior itself is verified on hardware in Task 8.
- [ ] Run the three organizer/attendance test files; inspect the form, record list, and result fixtures.

## Task 6: Administrator journey

**Files:** Modify all four `screens/admin/*.dart` files. Create `test/screens/admin_layout_test.dart`.

**Consumes:** Shell and shared controls; existing user, approval, QR, and log responses. **Produces:** Destination IDs `overview`, `reviews`, `users`, `qr-records`, `reports`, `activity`. Last three are compact More entries.

- [ ] Test existing publishing review actions and remarks; status change, password reset, and QR replacement require their existing confirmations. Verify protected actions cannot leak into other role menus.
- [ ] Split overview and publishing reviews using existing payloads. Preserve administrator event creation and announcement composition, including audience selection, as labeled actions.
- [ ] Restyle user forms, student QR current/history views, and log filters. The QR records destination reuses user/student selection before opening `StudentQrInspectScreen`; do not assume a new directory endpoint.
- [ ] Use stacked records on narrow layouts; permit bounded tables when space/data suit them. Confirmation dialogs and long log details must scroll at 2× text.
- [ ] Keep cancellation review recorded as a separate missing workflow. Do not add a decorative tab with no functioning action.
- [ ] Run `flutter test test/screens/admin_layout_test.dart`; inspect reviews and one destructive confirmation at 320 and 1440 widths.

## Task 7: Management and reports

**Files:** Modify `screens/management/management_dashboard_screen.dart`, `screens/common/reports_screen.dart`. Create `test/screens/management_layout_test.dart`, `test/screens/reports_layout_test.dart`.

**Consumes:** Read-only shared attendance/registration screens, shell, report data and existing export callbacks. **Produces:** Management destinations `overview`, `events`, `reports`; preserved `ReportsScreen({int? initialEventId})`.

- [ ] Add tests showing that management cannot reach event/user mutations or attendance operations, including More menus and wide layouts. Preserve profile/notification permissions separately.
- [ ] Separate management overview and event browsing using the existing dataset. Continue passing `canCancel: false` and `canCorrect: false`.
- [ ] Reflow report filters according to local available width. Keep all seven types, conditional event/student targeting, date/department/year filters, and existing format restrictions.
- [ ] Replace the fixed-aspect-ratio summary grid with content-sized metric groups. Render actual results without stretching narrative text across the entire desktop window.
- [ ] Test loading, invalid filter values, empty results, partial response/error, and export failure. Successful byte receipt must not display “Saved to Downloads.”
- [ ] Run both new test files and `test/screens/attendance_permissions_test.dart`; inspect reports with long labels and 2× text.

## Task 8: Cross-platform verification and handoff

**Files:** Refine only affected UI/test files. Add `docs/superpowers/reviews/2026-10-17-responsive-shadcn-mobile-verification.md` during implementation. Update the root implementation plan and context to describe completed work only after evidence exists.

- [ ] Run the entire width/scale/state matrix in the design. Capture actual before/after or final screenshots for login, events, details, QR, event form, scan result, and reports. Record viewport and text scale with each capture.
- [ ] Walk through each role with local test data. Confirm state retention, back navigation, session expiry, permitted actions, and understandable failures.
- [ ] On Android hardware, verify black-on-white QR readability, permissions, camera lifecycle, duplicate scan protection, and check-in/check-out identity results. If unavailable, record the check as outstanding rather than passing it.
- [ ] In a browser, check keyboard focus, Enter/Space, Escape, tab order, zoom, overlay dismissal, and form scrolling. Use `CHROME_EXECUTABLE=/usr/bin/brave` when launching Flutter web. Deep links/browser-history redesign are outside this change.
- [ ] Check Linux scanner fallback. Record iOS as unverified until its project and build host are available.
- [ ] From `mobile/`, run `/home/thea/development/flutter/bin/flutter analyze`, `/home/thea/development/flutter/bin/flutter test`, and `/home/thea/development/flutter/bin/flutter build web`. Required result: zero analyzer issues, all tests pass, web compilation succeeds.
- [ ] Review touched widgets for duplicated color literals, unintended default Material styling, lost functionality, inaccessible text/targets, and phantom actions. Shared tokens and intentional QR/camera colors are valid exceptions.
- [ ] Record results, remaining platform constraints, and any pre-existing failures. Review the final diff and update documentation. Commit task-sized changes only when committing is part of the agreed execution workflow.

## Execution order

Tasks 1 and 2 are shared dependencies. Tasks 3, 4, and 6 can run independently afterward with separate file ownership. Task 5 owns shared attendance screens; Task 7 follows their finalized interfaces. Coordinate access to shared theme/widgets and `main.dart` through one owner. Finish with Task 8.

The first visual checkpoint is the theme plus login and student events at 390, 768, and 1440 widths. Evaluate hierarchy, contrast, navigation, and spacing there before applying the same patterns across operational screens.
