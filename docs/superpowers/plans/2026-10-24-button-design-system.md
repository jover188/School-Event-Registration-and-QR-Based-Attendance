# Attendify Global Button UI/UX Consistency and Responsive Design Implementation Plan

> **For agentic workers:** Implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a unified, accessible, and responsive button design system across all Attendify Flutter screens adhering strictly to the black-and-white AetherUI identity.

**Architecture:** Extend `AppDesignTokens` with standard button dimension tokens (compact: 38px, standard: 46px, large: 50px, radius: 12px, icon: 18px), expand `AppButton` with `AppButtonSize`, `AppButtonVariant.secondary`, `isFullWidth`, and standard icon sizing, introduce `AppIconButton` for uniform icon touch targets (min 44x44px), update Material theme button themes (`ElevatedButtonTheme`, `OutlinedButtonTheme`, `TextButtonTheme`, `IconButtonTheme`) to eliminate inconsistent pill shapes and stadium borders, and audit all 29 screens/dialogs to standardize actions.

**Tech Stack:** Flutter 3.x, Dart 3.x, `shadcn_ui`, Lucide Icons Flutter, `AppDesignTokens` ThemeExtension.

---

## Global Constraints

- Strict black-and-white AetherUI palette: `#09090B` primary black, `#FFFFFF` white, `#FAFAFA` light background, neutral grays for borders (`#E4E4E7` / `#27272A`) and muted foreground (`#71717A` / `#A1A1AA`). No colored accents.
- Standard button dimensions:
  - Standard height: 46px (within 44–48px range)
  - Compact height: 38px (within 36–40px range)
  - Large primary action height: 50px (within 48–52px range)
  - Standard corner radius: 12px (rounded, not stadium pills, not sharp)
  - Horizontal padding: 12px (compact), 16px (standard), 20px (large)
  - Icon-to-label spacing: 8px
  - Normal text size: 14px (standard), 13px (compact), 15px (large)
  - Icon size: 18px (standard), 16px (compact), 20px (large)
  - Accessible hit target: at least 44x44px minimum constraint
- Five standardized button types:
  1. Primary: Black background, white text/icons, 12px radius, medium/semibold weight.
  2. Secondary: Light neutral background (`#F4F4F5` / `#27272A`), dark text, subtle border (`#E4E4E7`).
  3. Outlined: Transparent/card background, thin neutral-gray border, dark text.
  4. Destructive: Clearly distinguishable restrained destructive action with high-contrast label.
  5. Icon-only: Consistent 18-20px icon, minimum 44x44px hit area, rounded rectangle (12px) or circular shape.
- Strict preservation of callbacks, form submission, navigation, loading states, and async operations.
- STRICT RESTRICTIONS: **DO NOT COMMIT, PUSH, DEPLOY, PUBLISH, OR UPLOAD ANYTHING.** Keep all changes local.

---

## Review Focus

1. **Compact viewports (320px width)**: Button labels wrap or flex cleanly without `RenderFlex` overflow errors.
2. **Accessible touch targets**: Every interactive button and icon button has a hit area >= 44x44 logical pixels.
3. **No hardcoded stadium borders**: All dialog and screen buttons use the unified 12px radius rather than `StadiumBorder` or `radiusPill`.
4. **Preserved actions and form states**: `isLoading`, `onPressed == null` (disabled), confirmation dialog results, and form validations work identically.
5. **Zero static analysis warnings**: `flutter analyze` returns `No issues found!`.

---

## Implementation Tasks

### Task 1: Centralize Button Design Tokens & Material Themes
**Files:**
- Modify: `mobile/lib/core/theme/app_tokens.dart`
- Modify: `mobile/lib/core/theme/app_theme.dart`
- Test: `mobile/test/core/app_theme_test.dart`

**Steps:**
- [ ] Define button height, radius, padding, icon spacing, and icon sizing tokens in `AppDesignTokens`.
- [ ] Update `ElevatedButtonThemeData`, `OutlinedButtonThemeData`, `TextButtonThemeData`, and `IconButtonThemeData` in `AppTheme._buildMaterialTheme` to use standard 12px radius and 46px height instead of `d.radiusPill`.
- [ ] Verify `mobile/test/core/app_theme_test.dart` passes.

---

### Task 2: Enhance Shared `AppButton` & Introduce `AppIconButton`
**Files:**
- Modify: `mobile/lib/core/widgets/app_button.dart`
- Test: `mobile/test/core/app_button_test.dart` (new test suite)

**Steps:**
- [ ] Add `AppButtonSize` enum (`compact`, `standard`, `large`).
- [ ] Add `AppButtonVariant.secondary` with `#F4F4F5` surface, `#18181B` text, and `#E4E4E7` border.
- [ ] Add `isFullWidth` (boolean) parameter and responsive layout handling.
- [ ] Apply standard dimensions (heights: 38/46/50px, icon size: 16/18/20px, icon spacing: 8px, horizontal padding: 12/16/20px, corner radius: 12px).
- [ ] Introduce `AppIconButton` with minimum 44x44px hit area, accessible semantics, tooltip, and optional badge support.
- [ ] Create unit/widget tests for `AppButton` and `AppIconButton` covering all sizes, variants, loading state, disabled state, and full-width layout.

---

### Task 3: Standardize Dialog & Modal Action Buttons
**Files:**
- Modify: `mobile/lib/main.dart`
- Modify: `mobile/lib/screens/student/event_detail_screen.dart`
- Modify: `mobile/lib/screens/student/my_registrations_screen.dart`
- Modify: `mobile/lib/screens/student/permanent_qr_screen.dart`
- Modify: `mobile/lib/screens/organizer/event_form_screen.dart`
- Modify: `mobile/lib/screens/organizer/event_registrations_screen.dart`
- Modify: `mobile/lib/screens/organizer/live_attendance_screen.dart`

**Steps:**
- [ ] Replace hardcoded `ElevatedButton(shape: const StadiumBorder())` and raw `TextButton` in dialogs with standardized `AppButton` (or properly themed button actions) using `AppButtonVariant.ghost` for cancel and `AppButtonVariant.destructive` / `primary` for confirm.
- [ ] Ensure all dialog actions wrap responsively with `Wrap(spacing: d.sm, runSpacing: d.sm)`.

---

### Task 4: Standardize Screen Actions & Form Buttons Across Dashboards
**Files:**
- Modify: `mobile/lib/screens/auth/login_screen.dart`
- Modify: `mobile/lib/screens/common/calendar_screen.dart`
- Modify: `mobile/lib/screens/common/notifications_screen.dart`
- Modify: `mobile/lib/screens/common/notification_preferences_screen.dart`
- Modify: `mobile/lib/screens/common/profile_screen.dart`
- Modify: `mobile/lib/screens/common/reports_screen.dart`
- Modify: `mobile/lib/screens/admin/admin_dashboard_screen.dart`
- Modify: `mobile/lib/screens/admin/user_management_screen.dart`
- Modify: `mobile/lib/screens/admin/activity_logs_screen.dart`
- Modify: `mobile/lib/screens/admin/student_qr_inspect_screen.dart`
- Modify: `mobile/lib/screens/organizer/organizer_dashboard_screen.dart`
- Modify: `mobile/lib/screens/organizer/qr_scanner_screen.dart`
- Modify: `mobile/lib/screens/organizer/widgets/scan_result_content.dart`
- Modify: `mobile/lib/screens/management/management_dashboard_screen.dart`
- Modify: `mobile/lib/screens/student/student_dashboard_screen.dart`
- Modify: `mobile/lib/core/widgets/empty_state_view.dart`
- Modify: `mobile/lib/core/widgets/error_state_view.dart`
- Modify: `mobile/lib/core/widgets/section_header.dart`

**Steps:**
- [ ] Standardize login screen button to large primary action (`AppButtonSize.large`, 50px height, 12px radius, full width).
- [ ] Standardize dashboard quick action buttons and filter chips across Admin, Organizer, Student, and Management roles.
- [ ] Replace ad-hoc icon buttons with `AppIconButton` (or themed `IconButton`) ensuring minimum 44x44px hit area and tooltips.
- [ ] Align report export action buttons (CSV, PDF, Excel) to standard secondary/outline variants.
- [ ] Ensure all action pairs (e.g. Save / Cancel, Submit / Back) use matching heights, radii, and clear primary vs. secondary visual hierarchy.

---

### Task 5: Verification, Responsive Auditing & Accessibility Validation
**Steps:**
- [ ] Run `flutter analyze` from `mobile/` and verify zero issues.
- [ ] Run all Flutter widget and unit tests: `flutter test`.
- [ ] Verify 320x568 compact layout and 1024px tablet/desktop responsive rendering without overflows.
- [ ] Verify hot-reload / runtime rendering on the local web server (`http://127.0.0.1:3000`).
- [ ] Produce final audit and verification report.
