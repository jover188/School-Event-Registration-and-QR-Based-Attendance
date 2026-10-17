# School Event Registration & QR-Based Attendance — Project Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement the continuation tasks in this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the remaining backend reporting/auth/notification features and full Flutter mobile UI workflows for the School Event Registration and QR-Based Attendance Management System.

**Architecture:** Decoupled client-server architecture consisting of a Laravel 11 REST API backend (`backend/`) with Sanctum single-session token authentication and MySQL 8.0 / MariaDB storage (SQLite `:memory:` for automated tests), paired with a Flutter 3.x cross-platform client (`mobile/`).

**Tech Stack:** Laravel 11 (PHP 8.3+), Laravel Sanctum 4.x, `barryvdh/laravel-dompdf`, `maatwebsite/excel`, MySQL 8.0+ / MariaDB, Flutter 3.x (Dart 3.x), `qr_flutter`, `mobile_scanner`, `flutter_secure_storage`, `http`, `image_picker`, `cached_network_image`.

**Spec:** [`School_Event_Attendance_SRS_v1.0.md`](./School_Event_Attendance_SRS_v1.0.md), [`System_Architecture_and_Database_Design.md`](./System_Architecture_and_Database_Design.md), [`REST_API_Specification.md`](./REST_API_Specification.md), [`openapi.yaml`](./openapi.yaml)

## Global Constraints

- **Permanent QR Token Format:** Cryptographically random 64-character hexadecimal string (`bin2hex(random_bytes(32))`) with zero personal student data (`QR-001`, `SEC-009`).
- **Four Fixed Roles (`roles.slug`):** `administrator`, `organizer`, `student`, `management` (strictly Read-Only) (`AUTH-007`, `SEC-002`).
- **Single Active Session:** Logging in invalidates previous Sanctum tokens and issues `"session-{$uuid}"` stored in `users.active_session_id` (`AUTH-012`, `BR-020`).
- **Event Statuses:** `draft`, `pending_approval`, `published`, `ongoing`, `completed`, `cancelled` (`EVENT-004`).
- **Registration Statuses:** `registered`, `waiting_list`, `cancelled`, `walk_in` (`REG-007`).
- **Attendance Statuses:** `present`, `absent`, `late`, `excused`, `walk_in` (`ATT-015`).
- **Late Grace Period:** Default 15 minutes after `event_date + start_time` (`EVENT-002`, `ATT-012`).
- **Notification Retention:** 30 days in-app history before automatic purge; `event_cancellation` and `attendance_recorded` cannot be disabled (`NOTIF-005`, `NOTIF-008`, `BR-023`).
- **Test Database Isolation:** `backend/phpunit.xml` must use `DB_CONNECTION=sqlite` and `DB_DATABASE=:memory:`.

## Review Focus

1. **Waiting List Re-indexing on Walk-In or Staff Cancellation:** When a student on `waiting_list` is scanned as a `walk_in` or cancelled by staff, remaining `waiting_list_position` values above that position must be decremented so no position gaps occur.
2. **Absentee Representation in Event Attendance Report & Manual Corrections:** Registered students without an `attendances` row must appear as `absent` in `GET /api/v1/reports/event-attendance/{id}` and must be eligible for manual correction (`excused` / `present`) by an organizer or administrator.
3. **Multipart Profile Photo Upload Compatibility:** PHP does not parse `multipart/form-data` bodies on native `PUT` requests; `POST /api/v1/profile` must be supported alongside `PUT /api/v1/profile`.
4. **Check-Out Scan Verification Display:** Scanning in `check_out` mode must return the `student` profile object (`full_name`, `student_id_number`, `profile_photo_url`) and display `check_out_time` in the mobile scanner modal.
5. **Multi-Row Static Counter Reset in Excel Exports:** Excel export classes must use instance properties (`$this->row`) rather than `static $row` so sequential exports within the same worker process start at row 1.

---

# Part 1: Already Made (Completed Deliverables)

### 1.1 Specifications & Architecture Documentation
- [x] **Software Requirements Specification (v1.1 Baseline):** [`School_Event_Attendance_SRS_v1.0.md`](./School_Event_Attendance_SRS_v1.0.md) — Audited and aligned across all 35 sections.
- [x] **System Architecture & Database Design:** [`System_Architecture_and_Database_Design.md`](./System_Architecture_and_Database_Design.md) — High-level architecture, sequence diagrams, state machines, 13-table ER diagram, and production MySQL 8.0 DDL.
- [x] **REST API Specification & OpenAPI 3.0.3 Schema:** [`REST_API_Specification.md`](./REST_API_Specification.md) and [`openapi.yaml`](./openapi.yaml) — Documenting all `/api/v1/*` endpoints, parameters, and schemas.
- [x] **Workspace Context & Agent Rules:** [`context.md`](./context.md) and [`AGENTS.md`](./AGENTS.md).

### 1.2 Backend Core (`backend/`)
- [x] **Database Migrations (`backend/database/migrations/`):** All 13 domain tables (`roles`, `users`, `students`, `student_qrs`, `events`, `event_approvals`, `event_registrations`, `attendances`, `attendance_corrections`, `notifications`, `notification_preferences`, `device_tokens`, `activity_logs`) + Sanctum `personal_access_tokens` and Laravel system tables.
- [x] **Eloquent Models (`backend/app/Models/`):** All 13 domain models with relationships, capacity/status helpers, `full_name` & `profile_photo_url` accessors, and `ActivityLog::log()`.
- [x] **Database Seeders (`backend/database/seeders/`):** `RoleSeeder` (4 roles) and `UserSeeder` (4 demo accounts + student profile `20260001` + 64-char permanent QR + notification preferences).
- [x] **Custom Middleware (`backend/app/Http/Middleware/`):** `CheckRole` (`role` alias) and `EnforceSingleSession` (`single.session` alias).
- [x] **API v1 Controllers (`backend/app/Http/Controllers/Api/V1/`):**
  - [x] `AuthController` — `login` (email or numeric student ID + single-session token creation), `logout`, `profile`, `updateProfile`, `changePassword` (public self-registration removed in favor of institutional database seeding/middleware sync).
  - [x] `StudentQRController` — `show` (`GET /student/qr`), `reissue` (`POST /student/qr/reissue`), `inspect` (`GET /admin/students/{id}/qr`).
  - [x] `EventController` — `index`, `show`, `store`, `update`, `submitApproval`, `reviewApproval`, `requestCancellation`, `reviewCancellation`.
  - [x] `RegistrationController` — `register` (with capacity & waiting list placement), `cancelRegistration` (with transactional waiting list auto-promotion), `index` (`GET /events/{id}/registrations`), `studentRegistrations` (`GET /student/registrations`).
  - [x] `AttendanceController` — `scan` (`POST /events/{id}/attendance/scan` with check-in/out modes, grace-period late evaluation, walk-in auto-registration, student photo payload), `index` (`GET /events/{id}/attendance`), `correct` (`PUT /attendance/{id}/correct`), `studentHistory` (`GET /student/attendance-history`).
  - [x] `NotificationController` — `index`, `markAsRead`, `markAllAsRead`, `getPreferences`, `updatePreferences`, `storeDeviceToken`, `destroyDeviceToken`.
  - [x] `DashboardController` — `student`, `organizer`, `management`, `admin`.
  - [x] `AdminController` — `listUsers`, `createUser`, `toggleStatus`, `resetPassword`, `activityLogs`.
  - [x] `ReportController` — 7 JSON report endpoints + CSV/PDF/XLSX export for `event_attendance` and `absentee` (`EventAttendanceExport`, `AbsenteeExport`, Blade templates) + CSV export for `walk_in` and `student_history`.
- [x] **Scheduled Tasks (`backend/routes/console.php`):** `events:send-reminders-24h`, `events:send-reminders-1h`, `notifications:purge` (30-day retention), and `events:auto-close` (`published` → `ongoing` → `completed`).
- [x] **Automated Feature Tests (`backend/tests/Feature/`):**
  - [x] `SchoolAttendanceWorkflowTest.php` (5 end-to-end workflow tests).
  - [x] `AuthorizationPolicyTest.php` (21 role-based access control tests across all 4 roles).

### 1.3 Mobile Application (`mobile/`)
- [x] **Platform & Build Configuration:** Generated `linux/`, `android/`, and `web/` platform targets; configured `linux/CMakeLists.txt` for Clang compatibility; created `assets/images/`.
- [x] **Core Layer & Design System (`mobile/lib/core/`):**
  - [x] `ApiConstants` — Complete REST API v1 route catalog.
  - [x] `ApiClient` — Encrypted `FlutterSecureStorage` token persistence (with `SharedPreferences` fallback for tests), Bearer token injection, `postMultipart` upload, `downloadBytes` binary export support, and 401 session-terminated hook.
  - [x] `AppTheme` (`AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`) — Centralized Material 3 design token system.
  - [x] Reusable Component Library (`mobile/lib/core/widgets/`): `StatusBadge`, `StatMetricCard`, `EmptyStateView`, `ErrorStateView`, `SectionHeader`, `EventCard`.
- [x] **Data Models (`mobile/lib/models/`):** `UserModel`, `StudentModel`, `EventModel`, `AttendanceModel`.
- [x] **Implemented & API-Wired Screens (`mobile/lib/screens/` — 21 screens total):**
  - [x] `auth/login_screen.dart`, `auth/forgot_password_screen.dart` (self-registration removed in favor of institutional pre-provisioning)
  - [x] `common/profile_screen.dart`, `common/notifications_screen.dart`, `common/notification_preferences_screen.dart`, `common/reports_screen.dart`
  - [x] `student/student_dashboard_screen.dart`, `student/permanent_qr_screen.dart`, `student/event_detail_screen.dart`, `student/my_registrations_screen.dart`, `student/my_attendance_history_screen.dart`
  - [x] `organizer/organizer_dashboard_screen.dart`, `organizer/qr_scanner_screen.dart`, `organizer/event_form_screen.dart`, `organizer/event_registrations_screen.dart`, `organizer/live_attendance_screen.dart`
  - [x] `management/management_dashboard_screen.dart` (strictly Read-Only)
  - [x] `admin/admin_dashboard_screen.dart`, `admin/user_management_screen.dart`, `admin/activity_logs_screen.dart`, `admin/student_qr_inspect_screen.dart`
- [x] **Flutter Unit/Widget Tests (`mobile/test/widget_test.dart`):** 13 unit and widget tests covering models, design tokens, `ApiConstants`, `ApiClient` storage, reusable widgets, and screen rendering.

---

# Part 2: Continuations (Completed in Phase 8–10)

### Task 1: Complete Backend Report Exports (PDF, Excel & CSV for All 7 Report Types) & Report Filters

**Files:**
- Modify: `backend/app/Http/Controllers/Api/V1/ReportController.php`
- Create: `backend/app/Exports/StudentHistoryExport.php`
- Create: `backend/app/Exports/RegistrationSummaryExport.php`
- Create: `backend/app/Exports/ParticipationSummaryExport.php`
- Create: `backend/app/Exports/WalkInExport.php`
- Create: `backend/app/Exports/OrganizerSummaryExport.php`
- Create: `backend/resources/views/reports/student_history.blade.php`
- Create: `backend/resources/views/reports/registration_summary.blade.php`
- Create: `backend/resources/views/reports/participation_summary.blade.php`
- Create: `backend/resources/views/reports/walk_in.blade.php`
- Create: `backend/resources/views/reports/organizer_summary.blade.php`
- Create: `backend/tests/Feature/ReportExportTest.php`

**Interfaces:**
- Consumes: `Event`, `EventRegistration`, `Attendance`, `Student`, `User` models.
- Produces: `GET /api/v1/reports/export?report_type={type}&format={pdf|csv|xlsx}` supporting all 7 report types (`event_attendance`, `student_history`, `registration_summary`, `participation_summary`, `absentee`, `walk_in`, `organizer_summary`), plus `date_from`, `date_to`, `department`, `year_level`, and `status` filtering, and including non-attending registered students as `absent` in `eventAttendance`.

- [x] **Step 1: Write failing feature tests in `backend/tests/Feature/ReportExportTest.php`**
  Test that `GET /api/v1/reports/event-attendance/{id}` includes registered students without an `attendances` record as `status: "absent"`, and that `GET /api/v1/reports/export` returns `200 OK` for all 7 `report_type` values across `csv`, `pdf`, and `xlsx` formats.
- [x] **Step 2: Run test to verify it fails**
  Run: `php artisan test --filter=ReportExportTest`
  Expected: FAIL (`422` on unsupported export types and missing absent students in `eventAttendance`).
- [x] **Step 3: Implement the 5 Excel export classes, 5 Blade PDF templates, and update `ReportController.php`**
  Update `ReportController::eventAttendance()` to merge registered students without attendance rows as `absent`, add `date_from`/`date_to`/`department`/`year_level`/`status` filters, and expand `export()`, `exportCsv()`, `exportPdf()`, and `exportXlsx()` to handle all 7 report types.
- [x] **Step 4: Run test to verify it passes**
  Run: `php artisan test --filter=ReportExportTest`
  Expected: PASS
- [x] **Step 5: Commit**

---

### Task 2: Backend Email Verification, Self-Service Password Reset & Staff Operational Endpoints

**Files:**
- Modify: `backend/routes/api.php`
- Modify: `backend/app/Http/Controllers/Api/V1/AuthController.php`
- Modify: `backend/app/Http/Controllers/Api/V1/RegistrationController.php`
- Modify: `backend/app/Http/Controllers/Api/V1/StudentQRController.php`
- Modify: `backend/app/Http/Controllers/Api/V1/AttendanceController.php`
- Create: `backend/tests/Feature/AuthAndStaffOperationsTest.php`

**Interfaces:**
- Produces:
  - `POST /api/v1/auth/verify-email` (`{ email, token }`)
  - `POST /api/v1/auth/forgot-password` (`{ email }`)
  - `POST /api/v1/auth/reset-password` (`{ email, token, password, password_confirmation }`)
  - `DELETE /api/v1/events/{id}/registrations/{registrationId}` (Organizer/Admin cancel a student's registration with waiting list auto-promotion — `REG-009`)
  - `POST /api/v1/admin/students/{id}/qr/reissue` (Admin revoke & reissue student QR — `ADMIN-004`)
  - `POST /api/v1/events/{id}/attendance/mark` (Organizer/Admin create or correct attendance for an absent registered student — `ATT-011`)

- [x] **Step 1: Write failing tests in `backend/tests/Feature/AuthAndStaffOperationsTest.php`**
- [x] **Step 2: Run test to verify it fails**
- [x] **Step 3: Implement endpoints in `AuthController`, `RegistrationController`, `StudentQRController`, `AttendanceController`, and register routes in `backend/routes/api.php`**
- [x] **Step 4: Run test to verify it passes (`php artisan test`)**
- [x] **Step 5: Commit**

---

### Task 3: Backend Notification Dispatch Service & Admin Announcements

**Files:**
- Create: `backend/app/Services/NotificationService.php`
- Modify: `backend/app/Http/Controllers/Api/V1/AdminController.php`
- Modify: `backend/app/Http/Controllers/Api/V1/EventController.php`
- Modify: `backend/routes/api.php`
- Modify: `backend/routes/console.php`
- Create: `backend/tests/Feature/NotificationServiceTest.php`

**Interfaces:**
- Produces:
  - `NotificationService::send(int $userId, string $title, string $message, string $type, array $payload = []): ?Notification` — checks `NotificationPreference` (while always allowing mandatory types `event_cancellation` and `attendance_recorded`), creates the `Notification` record.
  - `POST /api/v1/admin/announcements` (`{ title, message, target_role? }`) — broadcasts an `admin_announcement` notification (`NOTIF-002`).

- [x] **Step 1: Write failing tests in `backend/tests/Feature/NotificationServiceTest.php`**
- [x] **Step 2: Run test to verify it fails**
- [x] **Step 3: Implement `NotificationService.php`, wire into `EventController` and `AdminController::sendAnnouncement`, and test scheduled commands**
- [x] **Step 4: Run test to verify it passes (`php artisan test`)**
- [x] **Step 5: Commit**

---

### Task 4: Mobile Secure Token Storage, Profile Screen & Notification Inbox/Preferences Screens

**Files:**
- Modify: `mobile/lib/core/constants/api_constants.dart`
- Modify: `mobile/lib/core/network/api_client.dart`
- Create: `mobile/lib/screens/common/profile_screen.dart`
- Create: `mobile/lib/screens/common/notifications_screen.dart`
- Create: `mobile/lib/screens/common/notification_preferences_screen.dart`
- Create: `mobile/lib/screens/auth/forgot_password_screen.dart`
- Modify: `mobile/lib/screens/student/student_dashboard_screen.dart`

- [x] **Step 1: Upgrade `ApiClient` to use `FlutterSecureStorage` with fallback to `SharedPreferences` in tests**
- [x] **Step 2: Implement `ProfileScreen` (view/edit profile fields, change password form) and `ForgotPasswordScreen`**
- [x] **Step 3: Implement `NotificationsScreen` (list notifications, mark read, mark all read) and `NotificationPreferencesScreen` (toggle 6 optional switches; show mandatory lock on critical alerts)**
- [x] **Step 4: Wire AppBar icons in `StudentDashboardScreen` (and other dashboards) to open `NotificationsScreen` and `ProfileScreen`**
- [x] **Step 5: Run Flutter analyzer and tests (`0` issues, `14/14` passing)**

---

### Task 5: Mobile Student My Registrations & Attendance History Screens

**Files:**
- Create: `mobile/lib/screens/student/my_registrations_screen.dart`
- Create: `mobile/lib/screens/student/my_attendance_history_screen.dart`
- Modify: `mobile/lib/screens/student/student_dashboard_screen.dart`

- [x] **Step 1: Implement `MyRegistrationsScreen` and `MyAttendanceHistoryScreen`**
- [x] **Step 2: Add navigation tabs and quick-action buttons on `StudentDashboardScreen` to open `MyRegistrationsScreen` and `MyAttendanceHistoryScreen`**
- [x] **Step 3: Verify with `flutter analyze` and `flutter test`**

---

### Task 6: Mobile Organizer Event Management, Attendee List & Live Attendance / Correction Screens

**Files:**
- Create: `mobile/lib/screens/organizer/event_form_screen.dart`
- Create: `mobile/lib/screens/organizer/event_registrations_screen.dart`
- Create: `mobile/lib/screens/organizer/live_attendance_screen.dart`
- Modify: `mobile/lib/screens/organizer/organizer_dashboard_screen.dart`

- [x] **Step 1: Implement `EventFormScreen` for creating and editing events (`max_participants`, `late_grace_period_minutes`, `walk_in_allowed`, dates/times, submit for approval, request cancellation)**
- [x] **Step 2: Implement `EventRegistrationsScreen` and `LiveAttendanceScreen` (with manual status correction dialog calling `PUT /attendance/{id}/correct` and manual attendance mark dialog calling `POST /events/{id}/attendance/mark`)**
- [x] **Step 3: Wire `OrganizerDashboardScreen` action buttons (Create Event FAB, Edit/Submit, View Registrations, Live Attendance, Scan QR, Reports)**
- [x] **Step 4: Verify with `flutter analyze` and `flutter test`**

---

### Task 7: Mobile Reports & Export Screen (Organizer, Management, Admin) and Admin Management Screens

**Files:**
- Create: `mobile/lib/screens/common/reports_screen.dart`
- Create: `mobile/lib/screens/admin/user_management_screen.dart`
- Create: `mobile/lib/screens/admin/activity_logs_screen.dart`
- Create: `mobile/lib/screens/admin/student_qr_inspect_screen.dart`
- Modify: `mobile/lib/screens/management/management_dashboard_screen.dart`
- Modify: `mobile/lib/screens/admin/admin_dashboard_screen.dart`

- [x] **Step 1: Implement `ReportsScreen` allowing selection of the 7 report types, event/student filters, JSON preview, and PDF/CSV/XLSX export actions**
- [x] **Step 2: Implement `UserManagementScreen`, `ActivityLogsScreen`, `StudentQrInspectScreen`, and Broadcast Announcement dialog on `AdminDashboardScreen`**
- [x] **Step 3: Wire navigation from `ManagementDashboardScreen`, `OrganizerDashboardScreen`, and `AdminDashboardScreen`**
- [x] **Step 4: Verify with `flutter analyze` and `flutter test`**

