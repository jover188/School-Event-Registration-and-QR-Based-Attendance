# Responsive shadcn Flutter design

Date: 2026-10-17  
Status: Design proposal for review; implementation has not started.  
Scope: The existing Flutter client, all four roles, phones, tablets, and desktop/web.

## 1. Intent and decisions

Make school event discovery, registration, QR presentation, and attendance operations clear at every window size. Students provide the visual reference. Staff screens use the same components with denser information where space permits.

The user selected `#4338CA`, `#EC4899`, `#22D3EE`, `#FDF4FF`, and `#18181B`. The user also confirmed phones, tablets, and desktop/web. Use the installed **`shadcn_ui ^0.57.2`**, with `intl ^0.20.3`; this is the package installed in this repository.

The following are proposed design decisions, not previously approved requirements: a light theme, white cards, role-specific adaptive navigation, system typography, and the supporting semantic colors below. Keep the app's existing name and school identity.

Design principles:

1. Put the current task and next action ahead of dashboard metrics.
2. Make the permanent QR available from a stable student destination.
3. Keep event identity and scan mode visible throughout attendance scanning.
4. Change layout using available space, while retaining user state.
5. Give every status a readable label and every failure a recovery action.
6. Use one shared theme and component library across all roles.

This proposal changes presentation and navigation organization. It does not change API contracts, authorization, database rules, or attendance decisions. Offline queues, push setup, new reporting capabilities, URL deep-link routing, and a dark palette remain separate work.

## 2. Current implementation and evidence

The client has 21 screens, imperative `MaterialPageRoute` navigation, and four dashboard entrypoints. `mobile/lib/main.dart` owns session resolution and the navigator used by the session-termination handler.

`mobile/lib/core/theme/app_theme.dart` already defines `AppColors`, `AppSpacing`, `AppRadius`, and `AppTypography`. Its current palette is navy/teal/amber. Six reusable widgets live under `mobile/lib/core/widgets/`.

The screen audit found no `LayoutBuilder` or `MediaQuery` adaptation in current screens. Dashboard action bars are crowded. Student and organizer metrics use fixed rows. Report metrics use a fixed two-column grid. Forms and lists lack useful wide-window limits. These are source observations, not results from a rendered-device audit.

Important existing gaps:

- Administrator publishing review exists; cancellation-review API constants exist, but the mobile review workflow is absent. Do not invent a working cancellation tab during styling.
- `LiveAttendanceScreen` loads on initialization, refresh, and filters. It does not continuously poll. Label the UI “Attendance” with an explicit refresh action.
- Reports receive export bytes but do not implement a complete file-save/share experience. Do not claim a file was saved to Downloads.
- Offline attendance synchronization is roadmap work. Show a connection failure and recovery, never a fictitious “saved offline” result.
- Existing platform folders are Android, Linux, and web. The SRS also specifies iOS, but there is no generated iOS project. Preserve iOS-compatible design without promising an iOS build in this refactor.
- The installed `mobile_scanner 5.2.3` declares Android/iOS/macOS/web support, not Linux. Linux gets an explanatory scanner-unavailable state and access to existing attendance views.

Sources consulted: `AGENTS.md`; `context.md`; both root project plans; SRS usability, compatibility, permissions and workflows; architecture overview; REST standards and OpenAPI paths; app root, theme, models, shared widgets, screens, existing tests; installed package source. Backend controllers and database internals were not audited because this proposal does not change them.

| Research source | Relevant finding | Design effect / evidence limit |
|---|---|---|
| [Flutter adaptive guidance](https://docs.flutter.dev/ui/adaptive-responsive/general) | Window and parent constraints determine usable space. | Use one destination model with width-dependent navigation; exact proposed breakpoints remain project decisions. |
| [Flutter accessibility](https://docs.flutter.dev/ui/accessibility) | Check targets, scaling, semantics, and assistive technology. | Use 48×48 minimum targets, expandable text, keyboard focus, and manual screen-reader checks. |
| [WCAG text contrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) | Normal text needs 4.5:1 contrast. | Choose foregrounds from calculated pairs; rendered controls still need inspection. |
| [shadcn Flutter setup](https://mariuti.com/flutter-shadcn-ui/) | `ShadApp.custom` supports an existing Material application. | Preserve the navigator and platform behavior; verify APIs against installed 0.57.2 source. |

## 3. Visual system

Use a soft canvas, white outlined cards, a clear indigo action, and small pink/cyan accents. Avoid large decorative regions that push events or QR actions down the screen. Use a colored date tile on event cards; the current event model does not provide event artwork or categories.

### Brand and supporting tokens

| Proposed token | Value | Role |
|---|---|---|
| `primary` / `primaryForeground` | `#4338CA` / `#FFFFFF` | Main buttons, selected navigation, links, focus rings |
| `brandPink` / `brandPinkForeground` | `#EC4899` / `#18181B` | Occasional accent blocks and highlights |
| `brandCyan` / `brandCyanForeground` | `#22D3EE` / `#18181B` | Supporting information accents |
| `background` / `foreground` | `#FDF4FF` / `#18181B` | Page canvas and primary text |
| `card`, `popover` | `#FFFFFF` | Content and overlay surfaces; foreground `#18181B` |
| `muted` / `mutedForeground` | `#F4F4F5` / `#52525B` | Quiet surfaces and secondary text |
| `secondary`, `accent`, `selection` | `#EEF2FF` | Quiet interactive tint; foreground `#4338CA` |
| `border` / `input` | `#E4E4E7` / `#71717A` | Decorative separators / visible control boundaries |
| `destructive` / `destructiveForeground` | `#B91C1C` / `#FFFFFF` | Destructive buttons; never use brand pink for danger |

Map shadcn `ring` to `primary`. Map `cardForeground` and `popoverForeground` to `foreground`. Brand pink and cyan are custom tokens; shadcn's generic `accent` is an interaction role, not the pink brand swatch.

Calculated sRGB contrast: white on indigo **7.90:1**; dark on pink **5.02:1**; dark on cyan **9.80:1**; dark on background **16.50:1**. White on pink is **3.53:1** and white on cyan **1.81:1**, so neither is a normal-text pairing. Decorative borders are not substitutes for identifiable control boundaries.

Preserve status meanings with proposed accessible foreground/background pairs:

| Meaning | Foreground / background | Examples |
|---|---|---|
| Success | `#166534` / `#F0FDF4` | present, registered, published, active, approved |
| Warning | `#92400E` / `#FFFBEB` | late, pending_approval |
| Danger | `#B91C1C` / `#FEF2F2` | absent, cancelled, revoked, inactive, suspended, rejected |
| Information | `#1E40AF` / `#EFF6FF` | ongoing, walk_in |
| Waiting | `#6B21A8` / `#FAF5FF` | waiting_list |
| Excused | `#155E75` / `#ECFEFF` | excused |
| Neutral / completed | `#52525B` / `#F4F4F5`; indigo / `#EEF2FF` | draft or unknown / completed |

Each badge includes text. QR modules remain black on white with the generator's quiet zone preserved.

### Type, space, shape, motion

Use the existing platform font stack, without a font download. Proposed roles: page title 28/34 at weight 700, compact page title 24/30, section title 20/28 at 600, card title 18/26 at 600, body/input 16/24, supporting text 14/20, and badge text 12/16 at 600. These are logical pixels before system text scaling. Allow labels and content to grow vertically.

Retain spacing values 4, 8, 16, 24, 32, 48; add a named 12-unit gap. Controls use radius 12, cards 16, dialogs/sheets 24. Prefer borders over shadows; overlays may use one subtle shadow. Controls have minimum height 48, not fixed height 48. Use Lucide icons exported by shadcn at 20–24, with a 48×48 hit area.

Interaction feedback lasts 100 ms; overlays last 180 ms. Disable nonessential motion when `MediaQuery.disableAnimationsOf(context)` is true. Keep existing platform route transitions. Do not animate camera success in a way that delays verification.

## 4. Responsive layout contract

All dimensions below are Flutter logical pixels. Breakpoints use the app window; inner columns use the remaining parent width after navigation and padding. Device names are shorthand, never runtime device checks.

| Window width | Navigation | Content |
|---|---|---|
| `<600` | Bottom destinations; 16 outer padding | One event column; full-width controls; scrollable sheets |
| `600–1023` | 88-wide rail with labels; 24 padding | One or two content columns when they fit |
| `>=1024` | 240-wide labeled sidebar; 32 padding | Centered content, maximum 1200 wide; up to three event columns |

Use intrinsic-height list rows, not fixed-aspect-ratio cards. At normal text size, event columns require at least 300 usable pixels each and 16 gaps. Metrics require 150 each, with 12 gaps, capped at four columns. At text scale 1.5 or above, event and metric groups become one column. Use lazy scrolling for long lists; do not eagerly build every record into a `Wrap`.

Login/recovery width is capped at 440. Profile and event forms are capped at 720. A form uses two columns only when its own content area is at least 640 wide and text is below 1.5 scale. Descriptions and errors always span the full row.

Detail screens may use a 320-wide action/summary pane only when their content area is at least 960 wide. Otherwise the summary stacks. A mobile detail action stays above the bottom safe area, with matching scroll padding. With a keyboard open or available height under 500, put sticky controls into the scroll flow so they cannot obscure fields.

Dialogs are centered up to 480 wide. Compact action/filter sheets fill the available width and scroll above keyboard insets. Return focus to the invoking control when dismissed. At large text sizes, the tablet rail widens with its labels or falls back to a labeled navigation sheet; do not clip labels. On narrow phones at large text, use two essential destinations plus a labeled “More” sheet that retains every destination.

The two essential destinations are Events/My QR for students, Overview/My events for organizers, Overview/Reviews for administrators, and Overview/Reports for management. Show the selected destination's title even when it is accessed through More.

Size the permanent QR from local constraints, capped at 280, including a preserved quiet zone. Reduce decorative padding before shrinking the code. Keep its identity and reissue controls in a scrollable page. Calculate the scanner reticle from both usable width and height; scroll its identity-result sheet so long names and check-out details remain reachable.

Reports, registrations, attendance, users, and logs use readable stacked records on narrow content areas. Use bounded `ShadTable` views with pagination only when existing data/loading supports it. Required columns must remain reachable through an explicitly scrollable table viewport, never page-wide overflow. Do not invent API pagination or statistics for unloaded records.

## 5. Navigation and screen coverage

Keep notification access and a profile menu in the shared header. Put profile, notification preferences, and logout in that menu. Preserve current profile permissions. Management remains read-only for events, registrations, attendance, and users; its existing account/notification actions remain separate.

| Role | Compact destinations | Wide destinations and key tasks |
|---|---|---|
| Student | Events, My events, My QR, History | Same four labels; browse, register, track waiting position, present permanent QR |
| Organizer | Overview, My events, Reports | Same labels; event creation, draft editing, submission, event-scoped registration/attendance/scanning |
| Administrator | Overview, Reviews, Users, More | Expand More into QR records, Reports, Activity; Reviews covers existing publishing review |
| Management | Overview, Events, Reports | Same labels; view event registrations and attendance with mutation controls absent |

Each existing role dashboard remains an entrypoint while its body is separated from navigation chrome. Reuse content sections for Overview, Events, and Reviews; these are reorganizations of existing data, not new endpoints. Existing drill-down screens remain regular routes. A detail route preserves parent context and back behavior. App-level destinations retain selection, search, filters, and scroll position across tab changes and window resize.

Screen coverage:

- **Authentication:** `LoginScreen`. Show institutional SIS account guidance, persistent labels, and password visibility toggle. No sign-up or self-service forgot-password call to action.
- **Student:** `StudentDashboardScreen`, `EventDetailScreen`, `MyRegistrationsScreen`, `PermanentQrScreen`, `MyAttendanceHistoryScreen`. Lead with events; show registration state and waiting position from the server. QR page includes a readable identity card and secondary reissue action with explicit revocation confirmation.
- **Organizer:** `OrganizerDashboardScreen`, `EventFormScreen`, `EventRegistrationsScreen`, `LiveAttendanceScreen`, `QrScannerScreen`. Separate form sections for details, schedule, and attendance rules. Keep draft/save/submit meanings distinct, and preserve cancellation requests, staff cancellation, manual attendance marking, and corrections. Scanning is always scoped to a selected event; retain supported flash/camera controls and result review before scanning next.
- **Administrator:** `AdminDashboardScreen`, `UserManagementScreen`, `StudentQrInspectScreen`, `ActivityLogsScreen`. Separate review queues, identity administration, and audit information. Preserve event creation, staff creation, and announcement composition with audience selection. Require confirmation for status changes, password resets, and QR replacement.
- **Management:** `ManagementDashboardScreen`. Reuse view-only registration/attendance surfaces with `canCancel: false` and `canCorrect: false`.
- **Shared:** `ProfileScreen`, `NotificationsScreen`, `NotificationPreferencesScreen`, `ReportsScreen`. Retain the seven report types and their actual filters. Critical notification preferences display a lock and explanation.

### Student reference wireframe

These are structural sketches, not rendered screenshots. Compact screens use four planning columns, with ordinary regions spanning all four.

```text
PHONE                         DESKTOP
┌───────────────────────┐     ┌────────────┬─────────────────────────────────┐
│ Campus Events   🔔  ○ │     │ School     │ Campus Events              🔔 ○ │
│ [Search events…]      │     │ Events     │ [Search events…]                │
│ Your activity         │     │ My events  │ [Registered] [Attended] [Alerts] │
│ [metrics reflow]      │     │ My QR      │                                 │
│ Available events      │     │ History    │ Available events                │
│ [Date | Event title]  │     │            │ [Event]   [Event]   [Event]     │
│ [Venue · time · state]│     │            │ [Event]   [Event]   [Event]     │
│ [More events: scroll] │     │            │                                 │
├───────────────────────┤     │            │                                 │
│ Events My events QR  │     │ Profile    │                                 │
│               History│     └────────────┴─────────────────────────────────┘
└───────────────────────┘
  bottom nav [sticky]           content [scroll], sidebar persistent
```

The sketch represents four labeled navigation items on one row at normal text size. Large-text behavior follows the More-sheet rule above. Event cards show only actual event fields; omit unavailable metadata rather than substituting invented values.

## 6. States and interaction contracts

| State | Visible behavior and recovery |
|---|---|
| Initial loading | Stable page heading and a labeled progress region; never placeholder counts presented as data |
| Ready / empty | Real content, or a specific empty message with browse/create/reset-filter action as permitted |
| Refresh failure / offline | Retain available content, show it may be outdated, provide Retry; no queued mutation claim |
| Submitting | Lock that action, keep inputs, show progress; prevent duplicate requests |
| Validation / rejected action | Persistent field or inline explanation, preserve input, focus the first error |
| Success | Update from the response, readable confirmation; announce critical scan status |
| Forbidden / session ended | Explain access or session loss and use the existing global login recovery |
| Disabled by event state | Explain eligibility; server still validates the request |
| Camera denied / unsupported | Explain the actual platform or permission limitation and offer retry/back as applicable |
| Partial data | Keep successful sections; show failed sections independently with retry |

Interaction details:

1. **Register:** open an event, submit once, show the server's registered or waiting-list result. Never calculate a guaranteed place locally.
2. **Cancel/reissue:** state the consequence in a confirmation dialog. On failure, keep the original state. Reissuing revokes the old permanent QR.
3. **Scan:** show event and mode, permit only published/ongoing events, pause acceptance while processing, and show returned photo/name/ID/status/time. Check-out displays its returned timestamp. A rejected scan offers retry; it does not look recorded.
4. **Correct attendance:** keep the existing correction permissions, require a reason, and display the saved response. Management has no correction action.
5. **Form save:** preserve input through server errors and layout changes. Do not silently submit for approval when saving a draft.
6. **Search/filter/refresh:** retain selections, identify the loaded result count, and keep previous content if refreshing fails.
7. **Export:** preserve supported report/format combinations and existing download requests. Do not label received bytes as a saved file or invent a share action.
8. **Navigation/session:** preserve the navigator key, authenticated role resolution, global 401 handling, and logout. Resizing must not reauthenticate, repeat a mutation, or create another camera controller.

Use 48×48 targets, visible indigo focus rings, semantic labels, text status announcements, and keyboard activation. Do not rely on hover. Keep existing date parsing and English copy, with locale-aware formatting where already supported; show times consistently without introducing timezone reinterpretation. New analytics and translations are outside this plan.

## 7. shadcn integration and component boundaries

Mount `ShadApp.custom` around the existing `MaterialApp`, with `ShadAppBuilder` in its builder. Keep one navigator. Use the installed source to configure localization delegates, overlay hosts, and scroll behavior correctly. Explicitly use the light theme.

Introduce one token source in `core/theme/app_tokens.dart`. Mount an `AppDesignTokens` extension through the Material bridge and expose `context.design`. Generate `ShadThemeData` and `ThemeData` from those values. Existing static color/spacing aliases temporarily forward to the token source so migration can happen screen by screen; they must not duplicate literals.

Use `ShadButton`, `ShadInput`/form fields, `ShadSelect`, `ShadCard`, `ShadBadge`, `ShadTabs`, `ShadDialog`, `ShadSheet`, `ShadAlert`, `ShadToast`, `ShadSwitch`, and `ShadTable` where appropriate. Preserve existing form validation during migration. Prefer shadcn's built-in keyboard and focus behavior over wrapping its controls in another gesture detector.

Create a small `AppPressable` only for whole-card and navigation interactions that lack a suitable shadcn control. It must implement disabled behavior, focus, Enter/Space activation, semantics, and reduced motion. Use one interaction surface per action. Avoid nesting a card-wide tap action around separate action buttons.

Restyle the six existing shared widgets rather than replacing their public contracts. Add shared responsive page, grid, shell, and button primitives only where multiple screens need them. Keep `ApiClient()` and endpoint constants as the networking entrypoint. No new state-management, layout-scaling, routing, icon, or chart dependency is necessary.

## 8. Verification and approval record

Verify widths 320, 390, 600, 768, 1024, and 1440; breakpoint boundaries 599/600 and 1023/1024; short landscape 844×390; text scales 1.0, 1.5, and 2.0. Test loading, empty, long text, failure, permissions, keyboard, and camera-unavailable states. Render at least login, student events, event details, permanent QR, event form, scanning results, and reports.

Check browser keyboard/zoom behavior and Android TalkBack. QR scanning and physical readability require an Android device check. iOS verification requires its missing platform setup and a compatible host. Preserve the Linux scanner fallback. A source review or screenshot alone does not prove successful scanning.

Before completion of implementation, run `flutter analyze`, `flutter test`, and a web build. Use the repository's absolute Flutter path. Record any environment-blocked visual or hardware verification honestly.

Usability walkthroughs: a student finds an event, registers or joins its waiting list, then presents QR; an organizer verifies scan mode and handles rejection; an administrator reviews a publishing request; management finds attendance without mutation controls. Include a keyboard-only user and a large-text user. Success means task completion and understandable recovery, not an unmeasured speed claim.

Approval record: palette and device coverage are user-specified. Layout, tokens, navigation grouping, and migration sequence remain proposed. This planning deliverable does not claim a shipped redesign.
