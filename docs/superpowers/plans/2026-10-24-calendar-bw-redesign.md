# Attendify Flutter Calendar — Black & White UI Implementation Plan

## Goal
Refactor and elevate the `CalendarScreen` and related calendar UI components in the Attendify Flutter application (`mobile/`) to strictly follow a polished Black-and-White (monochrome) design system matching the Attendify reference design, with zero colored accents, real Laravel backend integration, monochrome event category cards, notification badges, and full responsive support.

## Color Palette Tokens (Strict Grayscale)
- Primary black: `#09090B`
- Dark surfaces: `#121214`
- Primary white: `#FFFFFF`
- Light background: `#FAFAFA`
- Secondary gray: `#F4F4F5`
- Borders and dividers: `#E4E4E7`
- Muted text: `#71717A`
- Dark-mode borders: `#27272A`
- Absolute restriction: No teal (`#14B8A6`), blue, purple, green, orange, or other colors.

## Tasks & Steps

### Step 1: Monochrome Calendar Palette & Tokens
- Define `CalendarBwPalette` constants in `calendar_screen.dart` (or imported tokens) guaranteeing the exact hex codes required.
- Configure all `TableCalendar` styles to use monochrome decorations:
  - Selected day: Solid `#09090B` (light) / `#FFFFFF` (dark) circle with white / black bold text.
  - Today (unselected): Circular border `#09090B` / `#FFFFFF` (1.5px) with bold text.
  - Event indicator markers: Solid black `#09090B` dot on light mode, solid white `#FFFFFF` dot on dark mode.
  - Weekday labels: MON, TUE, WED, THU, FRI, SAT, SUN in `#71717A` uppercase typography.
  - Outside days: Inactive muted `#A1A1AA`.

### Step 2: Attendify Header, Notification Bell & View Controls
- Header section:
  - Attendify logo mark badge with "Attendify" branding, subtitle "Event Calendar • Browse campus events by schedule".
  - Notification bell button with unread count badge (monochrome `#09090B` badge with `#FFFFFF` text).
  - Tapping bell navigates to `NotificationsScreen`.
- View & Navigation Controls:
  - Prev (`<`) and Next (`>`) navigation icon buttons for browsing months / weeks.
  - Current Month & Year display (e.g. "October 2026") in clear bold typography.
  - "Today" button with clean monochrome outline/pill styling.
  - Segmented View Selector ("Month" | "Week") in a monochrome pill container:
    - Active view: Solid black `#09090B` background with white `#FFFFFF` text.
    - Inactive view: Neutral background `#F4F4F5` with `#71717A` text.
    - Tapping seamlessly switches format and preserves selected date.

### Step 3: Monochrome Event Cards & Category Icons
- Build an enhanced monochrome event card `_BwEventCard`:
  - Monochrome category icon mapped from event type / title keywords:
    - Academic / Seminar: `LucideIcons.graduationCap`
    - Workshop / Tech: `LucideIcons.wrench` / `LucideIcons.laptop`
    - Sports / Athletics: `LucideIcons.trophy`
    - Cultural / Arts: `LucideIcons.palette`
    - Social / Community: `LucideIcons.users`
    - General: `LucideIcons.calendarDays`
  - Icon container: Square rounded box with `#F4F4F5` background, `#E4E4E7` border, `#09090B` icon (light mode) or `#27272A` background with `#FFFFFF` icon (dark mode).
  - Title: Bold typography `#09090B` (light) / `#FFFFFF` (dark).
  - Venue: `LucideIcons.mapPin` with venue string in `#71717A`.
  - Date & Time: `LucideIcons.clock` with time string in `#71717A`.
  - Status badge: Strict monochrome status badge (e.g. `#F4F4F5` / `#27272A` background, `#E4E4E7` / `#27272A` border, `#09090B` / `#FFFFFF` text, monochrome status icon).
  - Chevron indicator: `LucideIcons.chevronRight` in `#71717A`.
  - Card background: `#FFFFFF` with `#E4E4E7` border (light mode) / `#121214` with `#27272A` border (dark mode).
  - Tap handler: Navigates to `EventDetailScreen(eventId: event.id, event: event)`.

### Step 4: Notification Screen Monochrome Polish
- Ensure `NotificationsScreen` uses monochrome snackbar (`#09090B`) instead of `AppColors.present`.
- Ensure all notification badges in `NotificationsScreen` adhere to monochrome colors.

### Step 5: Responsive Design & Layout Optimization
- Max-width responsive container (e.g. up to 1080px) centered on tablet, desktop, and web.
- Responsive calendar and card padding.
- Ensure no layout overflows at 320px width and at 2x text scaling.

### Step 6: Testing & Verification
- Update `mobile/test/screens/calendar_screen_test.dart` to verify:
  - All existing 5 tests continue to pass.
  - Add tests for:
    - Black & white category icon rendering.
    - Month/week segmented pill toggle.
    - Previous and Next month navigation.
    - Notification bell and unread badge.
    - Event card tap opening `EventDetailScreen`.
- Run `flutter analyze` -> `No issues found!`.
- Run `flutter test` -> all tests green.
- Run `php artisan test` -> 44 backend tests green.
