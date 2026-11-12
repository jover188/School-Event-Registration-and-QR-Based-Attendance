# Simplify Bottom Navigation Across All Dashboards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign and simplify the bottom navigation bar across all four Attendify dashboards (Admin, Organizer, Student, Management) to display EXACTLY THREE items per dashboard with equal spacing, removing "More", moving secondary features to the sidebar, and eliminating redundant navigation between bottom navigation and sidebar.

**Architecture:** Update `AppShell` to enforce exactly three primary bottom navigation items without the "More" button by default (`showCompactMore = false`), and optimize the mobile drawer to surface sidebar/secondary features without duplicating the bottom navigation bar. Update `_destinations` in `AdminDashboardScreen`, `OrganizerDashboardScreen`, `StudentDashboardScreen`, and `ManagementDashboardScreen` to configure the exact 3 required bottom navigation destinations with `compactPrimary: true` and all secondary destinations with `compactPrimary: false`.

**Tech Stack:** Flutter 3, Dart 3, Shadcn/AetherUI black-and-white design system.

**Spec:** User prompt specifications for Attendify – Simplify Bottom Navigation Across All Dashboards.

## Global Constraints
- Exactly THREE bottom navigation items per dashboard.
- Equal spacing between the three items (`Expanded` flex 1:1:1).
- Consistent icon sizes (20px), centered alignment, and non-truncating labels.
- Black-and-white minimalist design (`#09090B`, `#FFFFFF`, `#FAFAFA`).
- Secondary features remain fully accessible via the sidebar/drawer.
- Role-based permissions and all existing screens remain intact.
- Do not commit or push to GitHub.

## Review Focus
- **Case 1: Admin bottom navigation.** Must have exactly Overview, Reviews, Users (3 items). "More" must not appear. Calendar, QR Records, Reports, and Activity Logs must be in the Admin sidebar.
- **Case 2: Organizer bottom navigation.** Must have exactly Overview, Calendar, My Events (3 items). Reports must be in the sidebar.
- **Case 3: Student bottom navigation.** Must have exactly Events, Calendar, My Registration (3 items). My QR must be in the sidebar.
- **Case 4: Management bottom navigation.** Must have exactly Overview, Events, Calendar (3 items). Reports must be in the sidebar.
- **Case 5: Mobile drawer & desktop sidebar accessibility.** On mobile, tapping the header drawer button must show the sidebar/secondary destinations. On desktop, the sidebar must retain full navigation capability.

---

### Task 1: Update AppShell Bottom Navigation & Mobile Drawer

**Files:**
- Modify: `mobile/lib/core/widgets/app_shell.dart`
- Test: `mobile/test/core/app_shell_test.dart`

- [ ] **Step 1.1: Update AppShell showCompactMore default to false**
  - Change `showCompactMore` default from `true` to `false` so "More" is not appended to the bottom navigation bar.
  - In `build()`, ensure `primary` items are not clamped/truncated below 3 on large text scale (keep all 3 primary items).
- [ ] **Step 1.2: Refine mobile slide-over drawer in AppShell**
  - When opened on mobile (`side == false`), if secondary destinations exist (`destinations.where((item) => !item.compactPrimary)`), present the secondary items in the drawer so mobile users have direct access to features moved to the sidebar without redundant duplication of the bottom bar items.
- [ ] **Step 1.3: Run app_shell_test.dart and verify**
  - Run `flutter test test/core/app_shell_test.dart`.

---

### Task 2: Update Organizer Dashboard Navigation

**Files:**
- Modify: `mobile/lib/screens/organizer/organizer_dashboard_screen.dart`
- Test: `mobile/test/screens/organizer_layout_test.dart`

- [ ] **Step 2.1: Update _destinations in OrganizerDashboardScreen**
  - Configure exactly 3 bottom navigation items (`compactPrimary: true`):
    1. `overview`: 'Overview' (LucideIcons.layoutDashboard)
    2. `calendar`: 'Calendar' (LucideIcons.calendarDays)
    3. `events`: 'My Events' (LucideIcons.calendarRange)
  - Move Reports to sidebar (`compactPrimary: false`):
    4. `reports`: 'Reports' (LucideIcons.chartBar)
  - Ensure `AppShell` receives `showCompactMore: false`.
- [ ] **Step 2.2: Update and run organizer_layout_test.dart**
  - Verify bottom bar contains exactly 3 items: Overview, Calendar, My Events.
  - Verify Reports is accessible via sidebar.
  - Run `flutter test test/screens/organizer_layout_test.dart`.

---

### Task 3: Update Admin Dashboard Navigation

**Files:**
- Modify: `mobile/lib/screens/admin/admin_dashboard_screen.dart`
- Test: `mobile/test/screens/admin_layout_test.dart`

- [ ] **Step 3.1: Update _destinations in AdminDashboardScreen**
  - Order and configure exactly 3 bottom navigation items (`compactPrimary: true`):
    1. `overview`: 'Overview' (LucideIcons.layoutDashboard)
    2. `reviews`: 'Reviews' (LucideIcons.folderCheck)
    3. `users`: 'Users' (LucideIcons.users)
  - Move all other items to sidebar (`compactPrimary: false`):
    4. `calendar`: 'Calendar' (LucideIcons.calendarDays)
    5. `qr-records`: 'QR Records' (LucideIcons.scanLine)
    6. `reports`: 'Reports' (LucideIcons.chartBar)
    7. `activity`: 'Activity' (LucideIcons.scrollText)
  - Ensure `AppShell` receives `showCompactMore: false`.
- [ ] **Step 3.2: Update and run admin_layout_test.dart**
  - Verify bottom bar has exactly 3 items: Overview, Reviews, Users.
  - Verify "More" button is gone.
  - Verify Calendar, QR Records, Reports, Activity are accessible in the sidebar.
  - Run `flutter test test/screens/admin_layout_test.dart`.

---

### Task 4: Update Student Dashboard Navigation

**Files:**
- Modify: `mobile/lib/screens/student/student_dashboard_screen.dart`
- Test: `mobile/test/screens/student_flow_layout_test.dart`

- [ ] **Step 4.1: Update _destinations in StudentDashboardScreen**
  - Configure exactly 3 bottom navigation items (`compactPrimary: true`):
    1. `events`: 'Events' (LucideIcons.calendar)
    2. `calendar`: 'Calendar' (LucideIcons.calendarDays)
    3. `registrations`: 'My Registration' (LucideIcons.clipboardCheck)
  - Move My QR to sidebar (`compactPrimary: false`):
    4. `qr`: 'My QR' (LucideIcons.qrCode, compactPrimary: false)
    5. `profile`: 'My Profile' (LucideIcons.user, compactPrimary: false)
    6. `history`: 'History' (LucideIcons.history, compactPrimary: false)
  - Ensure `AppShell` receives `showCompactMore: false`.
- [ ] **Step 4.2: Update and run student_flow_layout_test.dart**
  - Verify bottom bar has exactly 3 items: Events, Calendar, My Registration.
  - Verify My QR, My Profile, and History are accessible in the sidebar.
  - Run `flutter test test/screens/student_flow_layout_test.dart`.

---

### Task 5: Update Management Dashboard Navigation

**Files:**
- Modify: `mobile/lib/screens/management/management_dashboard_screen.dart`
- Test: `mobile/test/screens/management_layout_test.dart`

- [ ] **Step 5.1: Update _destinations in ManagementDashboardScreen**
  - Configure exactly 3 bottom navigation items (`compactPrimary: true`):
    1. `overview`: 'Overview' (LucideIcons.layoutDashboard)
    2. `events`: 'Events' (LucideIcons.calendarRange)
    3. `calendar`: 'Calendar' (LucideIcons.calendarDays)
  - Move Reports to sidebar (`compactPrimary: false`):
    4. `reports`: 'Reports' (LucideIcons.chartBar)
  - Ensure `AppShell` receives `showCompactMore: false`.
- [ ] **Step 5.2: Update and run management_layout_test.dart**
  - Verify bottom bar has exactly 3 items: Overview, Events, Calendar.
  - Verify Reports is accessible in the sidebar.
  - Run `flutter test test/screens/management_layout_test.dart`.

---

### Task 6: Dedicated 3-Item Bottom Navigation Verification Test & Regression Suite

**Files:**
- Create: `mobile/test/screens/dashboard_bottom_nav_simplification_test.dart`

- [ ] **Step 6.1: Create comprehensive 4-dashboard test suite**
  - Tests all four dashboards independently at compact mobile size (390x844):
    - Admin: exactly 3 items (Overview, Reviews, Users).
    - Organizer: exactly 3 items (Overview, Calendar, My Events).
    - Student: exactly 3 items (Events, Calendar, My Registration).
    - Management: exactly 3 items (Overview, Events, Calendar).
  - Tests that sidebar opens and allows navigating to secondary features.
- [ ] **Step 6.2: Run full Flutter test suite and static analysis**
  - Run `flutter test`.
  - Run `dart analyze mobile/lib`.
