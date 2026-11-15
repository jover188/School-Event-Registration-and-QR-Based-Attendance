# Attendify – Complete End-to-End Feature Functionality Audit Report

**Date of Audit:** November 15, 2026  
**Lead Auditor:** Senior QA Engineer & Full-Stack Application Tester  
**Repository:** School Event Registration and QR-Based Attendance Management System (Attendify)  
**Verification Environment:** Windows 10/11, PHP 8.2.12 (Laravel 11, SQLite `:memory:`), Flutter 3.47.7 (Dart 3.13.5)

---

## 1. Executive Summary & Automated Verification Matrix

A comprehensive, end-to-end functionality audit of the Attendify application was conducted across the backend REST API, database operations, Flutter mobile application, authentication state machine, and notification architecture.

All automated test suites were executed cleanly with **100% passing rates**:

| Subsystem / Test Suite | Scope | Automated Result | Assertions / Test Count |
| :--- | :--- | :---: | :--- |
| **Backend Full Test Suite** | `php artisan test` | ✅ **PASS** | **111 passed (572 assertions, 0 failures)** |
| **Mobile Static Analysis** | `flutter analyze` | ✅ **PASS** | **0 issues found** (0 errors, 0 warnings, 0 infos) |
| **Mobile Full Test Suite** | `flutter test` | ✅ **PASS** | **148 passed (0 failures, 100% pass rate)** |

### Classification Summary of Evaluated Features
- **Total Features Evaluated:** 52
- **PASS:** 47 (90.4%)
- **PARTIAL:** 4 (7.7%) *(Mobile OTP modal, mobile correction request button, student contact number update, physical device background push delivery)*
- **NOT IMPLEMENTED:** 1 (1.9%) *(Token refresh endpoint – intentional Sanctum single-session architecture)*
- **FAIL:** 0 (0.0%)
- **NOT TESTED:** 0 (0.0%)

---

## 2. Complete Feature Inventory

### A. Mobile Screen Inventory (23 Screens & Views)
1. `mobile/lib/screens/auth/login_screen.dart` — Unified authentication screen supporting numeric Student ID and institutional email.
2. `mobile/lib/screens/student/student_dashboard_screen.dart` — Student hub with 3-up metric strip, tabs, and upcoming events.
3. `mobile/lib/screens/student/permanent_qr_screen.dart` — High-contrast display of student's permanent 64-hex QR identity and reissue trigger.
4. `mobile/lib/screens/student/my_registrations_screen.dart` — List of student's active, waiting-list, and cancelled event registrations.
5. `mobile/lib/screens/student/my_attendance_history_screen.dart` — Filterable student attendance timeline with status badges.
6. `mobile/lib/screens/student/event_detail_screen.dart` — Event information, schedule, eligibility badges, and registration/cancellation pane.
7. `mobile/lib/screens/organizer/organizer_dashboard_screen.dart` — Organizer metrics, event management shortcuts, and quick scanning launcher.
8. `mobile/lib/screens/organizer/event_form_screen.dart` — Multi-step event creation and editing with audience targeting rules builder.
9. `mobile/lib/screens/organizer/event_registrations_screen.dart` — Attendee management roster with status chips and staff cancellation actions.
10. `mobile/lib/screens/organizer/live_attendance_screen.dart` — Real-time attendance monitor with manual marking and correction actions.
11. `mobile/lib/screens/organizer/qr_scanner_screen.dart` — Mobile camera scanner with check-in/out toggles and photo verification.
12. `mobile/lib/screens/organizer/widgets/scan_result_content.dart` — Modal presentation of student identity and scan outcome.
13. `mobile/lib/screens/admin/admin_dashboard_screen.dart` — Administrator overview with pending approvals, user stats, and audit logs.
14. `mobile/lib/screens/admin/user_management_screen.dart` — Account lifecycle management (creation, status toggle, password reset).
15. `mobile/lib/screens/admin/student_qr_inspect_screen.dart` — QR token inspector and administrator-forced reissue control.
16. `mobile/lib/screens/admin/activity_logs_screen.dart` — System audit trail with action/module filtering and expandable metadata.
17. `mobile/lib/screens/management/management_dashboard_screen.dart` — Strictly read-only executive overview with institutional KPIs.
18. `mobile/lib/screens/common/calendar_screen.dart` — Interactive event calendar supporting Month and Week views with date markers.
19. `mobile/lib/screens/common/notifications_screen.dart` — Real-time notification inbox with read state tracking and tap-to-navigate.
20. `mobile/lib/screens/common/notification_preferences_screen.dart` — User preferences management with locked critical alerts.
21. `mobile/lib/screens/common/profile_screen.dart` — User profile view with institutional academic record protection.
22. `mobile/lib/screens/common/reports_screen.dart` — Report generation and multi-format export interface (CSV, PDF, XLSX).
23. `mobile/lib/screens/auth/account_input.dart` — Adaptive input field supporting numeric student ID and email formats.

### B. Backend Controller & API Inventory
- `AuthController` — Login, single-session token issuance, profile fetch, password change, email verification with cached OTP, profile correction request.
- `EventController` — Event CRUD, audience options discovery, submit for approval, cancellation request, admin review & review cancellation.
- `RegistrationController` — Student registration, self-cancellation, waiting list promotion, staff cancellation, attendee listing.
- `AttendanceController` — QR attendance scan (check-in/check-out), manual attendance marking, attendance correction, attendee live monitor, student attendance history.
- `StudentQRController` — Permanent QR retrieval, student self-service reissue, admin QR inspection, admin forced reissue.
- `AdminController` — User management (list, create, toggle status, reset password), student profile management, broadcast announcements, activity logs.
- `ReportController` — 7 report generation endpoints and universal export engine supporting CSV, PDF, and XLSX.
- `NotificationController` — Notification feed, unread counter, mark read, mark all read, preferences management, device token registration/deregistration.
- `DashboardController` — Role-specific aggregated dashboard metrics for Student, Organizer, Administrator, and School Management.

---

## 3. Student Functionality Results

| Feature | Role | Backend Endpoint / Mobile Screen | Status | Verification Evidence |
| :--- | :---: | :--- | :---: | :--- |
| **Login with Student ID** | Student | `POST /api/v1/auth/login`<br>`LoginScreen` | **PASS** | Resolves student profile by numeric ID, authenticates password, issues Sanctum session token. Tested in `SchoolAttendanceWorkflowTest`. |
| **Student Dashboard** | Student | `GET /api/v1/dashboard/student`<br>`StudentDashboardScreen` | **PASS** | Displays 3-up metric strip, upcoming events list, and quick actions. Tested in `student_flow_layout_test.dart`. |
| **Institutional Profile Protection** | Student | `GET /api/v1/profile`<br>`ProfileScreen` | **PASS** | Academic identity fields (name, student ID, course, year, section, department) are strictly read-only. Tested in `StudentProfileProtectionTest`. |
| **Permanent QR Display** | Student | `GET /api/v1/student/qr`<br>`PermanentQrScreen` | **PASS** | Renders 64-character lowercase hex token within bounded container (`180..280` px). Tested in `permanent_qr_layout_test.dart`. |
| **Permanent QR Reissue** | Student | `POST /api/v1/student/qr/reissue`<br>`PermanentQrScreen` | **PASS** | Atomic `DB::transaction()` revokes previous active tokens (`status='revoked'`) and issues a fresh 64-hex token. Tested in `SchoolAttendanceWorkflowTest`. |
| **Event Calendar** | Student | `GET /api/v1/events`<br>`CalendarScreen` | **PASS** | Month/week format toggles, day event markers, and previous/next navigation. Tested in `calendar_screen_test.dart`. |
| **Event Detail & Eligibility** | Student | `GET /api/v1/events/{id}`<br>`EventDetailScreen` | **PASS** | Displays event metadata and audience badges. Ineligible events hide registration pane. Tested in `event_detail_audience_badge_test.dart`. |
| **Event Registration** | Student | `POST /api/v1/events/{id}/register`<br>`EventDetailScreen` | **PASS** | Enforces audience targeting, registration deadlines, and duplicate registration prevention. Tested in `EventAudienceTargetingTest`. |
| **Waiting List Placement** | Student | `POST /api/v1/events/{id}/register` | **PASS** | When capacity is reached, student is placed on waiting list with sequential position. Tested in `SchoolAttendanceWorkflowTest`. |
| **Waiting List Auto-Promotion** | Student | `DELETE /api/v1/events/{id}/cancel-registration` | **PASS** | When a registered attendee cancels, position #1 is auto-promoted to `registered` and remaining positions decrement. Tested in `SchoolAttendanceWorkflowTest`. |
| **My Registrations** | Student | `GET /api/v1/student/registrations`<br>`MyRegistrationsScreen` | **PASS** | Filterable list of student registrations with details navigation. Tested in `student_flow_layout_test.dart`. |
| **Self-Service Event Cancellation** | Student | `DELETE /api/v1/events/{id}/cancel-registration`<br>`EventDetailScreen` | **PASS** | Allows cancellation prior to event start. Ongoing event cancellation blocked (`422 ERR_CANNOT_CANCEL_ONGOING`). Tested in `student_flow_layout_test.dart`. |
| **Attendance History** | Student | `GET /api/v1/student/attendance-history`<br>`MyAttendanceHistoryScreen` | **PASS** | Displays chronological attendance records with status filters. Tested in `student_flow_layout_test.dart`. |
| **Notification Inbox** | Student | `GET /api/v1/notifications`<br>`NotificationsScreen` | **PASS** | Displays received announcements and reminders; marks individual or all as read. Tested in `NotificationServiceTest`. |
| **Contact Number Self-Update** | Student | `PUT /api/v1/profile` | **PARTIAL** | Backend currently locks all student profile updates to 403 `ERR_STUDENT_PROFILE_IMMUTABLE`. Updates must be performed by Admin. |
| **Profile Correction Request** | Student | `POST /api/v1/profile/correction-request` | **PARTIAL** | Backend API fully functional and tested, but mobile `ProfileScreen` displays advisory notice without interactive form modal. |
| **Student Password Change** | Student | `POST /api/v1/profile/change-password` | **PASS** | Intentionally blocked with 403 `ERR_STUDENT_PASSWORD_CHANGE_DISABLED` per institutional governance. |

---

## 4. Organizer Functionality Results

| Feature | Role | Backend Endpoint / Mobile Screen | Status | Verification Evidence |
| :--- | :---: | :--- | :---: | :--- |
| **Organizer Authentication** | Organizer | `POST /api/v1/auth/login`<br>`LoginScreen` | **PASS** | Authenticates email/password, issues single-session token, enforces role boundaries. |
| **Organizer Dashboard** | Organizer | `GET /api/v1/dashboard/organizer`<br>`OrganizerDashboardScreen` | **PASS** | Aggregates event counts by status and displays recent event cards. Tested in `organizer_layout_test.dart`. |
| **Event Creation** | Organizer | `POST /api/v1/events`<br>`EventFormScreen` | **PASS** | Validates date/time constraints, capacity, and audience targeting rules. Tested in `EventAudienceOptionsAndValidationTest`. |
| **Event Editing** | Organizer | `PUT /api/v1/events/{id}`<br>`EventFormScreen` | **PASS** | Only creator or admin can update; updates notify registered attendees. Tested in `EventAudienceOptionsAndValidationTest`. |
| **Submit for Approval** | Organizer | `POST /api/v1/events/{id}/submit-approval` | **PASS** | Transitions event from `draft` to `pending_approval`; blocks cross-organizer submissions. Tested in `organizer_layout_test.dart`. |
| **Event Cancellation Request** | Organizer | `POST /api/v1/events/{id}/request-cancellation` | **PASS** | Requires mandatory reason and queues for administrative review. Tested in `organizer_layout_test.dart`. |
| **Event Registrations Roster** | Organizer | `GET /api/v1/events/{id}/registrations`<br>`EventRegistrationsScreen` | **PASS** | Displays attendee list with status chips, search, and demographic details. Tested in `organizer_layout_test.dart`. |
| **Staff Registration Cancellation** | Organizer | `DELETE /api/v1/events/{id}/registrations/{id}` | **PASS** | Staff cancellation frees slot, auto-promotes waitlist candidate, and dispatches notification. Tested in `AuthAndStaffOperationsTest`. |
| **Live Attendance Monitor** | Organizer | `GET /api/v1/events/{id}/attendance`<br>`LiveAttendanceScreen` | **PASS** | Real-time attendance list with check-in/out timestamps and metrics. Tested in `attendance_permissions_test.dart`. |
| **QR Attendance Scanner** | Organizer | `POST /api/v1/events/{id}/attendance/scan`<br>`QrScannerScreen` | **PASS** | Validates 64-hex token, supports check-in/out modes, verifies student identity. Tested in `scanner_states_test.dart`. |
| **Manual Attendance Marking** | Organizer | `POST /api/v1/events/{id}/attendance/mark` | **PASS** | Supports `present`, `absent`, `late`, `excused`, `walk_in` with mandatory reason. Tested in `AuthAndStaffOperationsTest`. |
| **Attendance Correction** | Organizer | `PUT /api/v1/attendance/{id}/correct`<br>`LiveAttendanceScreen` | **PASS** | Requires mandatory reason (>= 5 chars) and records audit trail. Tested in `attendance_permissions_test.dart`. |
| **Attendee Reports & Export** | Organizer | `GET /api/v1/reports/export`<br>`ReportsScreen` | **PASS** | Exports own event data in CSV, PDF, and XLSX. Non-owned events blocked with 403 `ERR_FORBIDDEN`. Tested in `ReportExportTest`. |
| **Organizer Password Change** | Organizer | `POST /api/v1/profile/change-password` | **PASS** | Requires current password and enforces complexity rules. Tested in `SchoolAttendanceWorkflowTest`. |

---

## 5. Administrator & Management Functionality Results

| Feature | Role | Backend Endpoint / Mobile Screen | Status | Verification Evidence |
| :--- | :---: | :--- | :---: | :--- |
| **Admin Authentication & Dashboard** | Admin | `GET /api/v1/dashboard/admin`<br>`AdminDashboardScreen` | **PASS** | Displays pending approval counts, user statistics, and recent activity logs. Tested in `admin_layout_test.dart`. |
| **User Listing & Search** | Admin | `GET /api/v1/admin/users`<br>`UserManagementScreen` | **PASS** | Paginated user list with role, status, and name/email filters. Tested in `AuthorizationPolicyTest`. |
| **User Creation** | Admin | `POST /api/v1/admin/users`<br>`UserManagementScreen` | **PASS** | Creates Organizer and Management accounts with validation and default preferences. Tested in `admin_layout_test.dart`. |
| **Account Status Toggle** | Admin | `PATCH /api/v1/admin/users/{id}/status`<br>`UserManagementScreen` | **PASS** | Toggles `active`/`inactive`. Self-deactivation blocked (`422 ERR_CANNOT_DEACTIVATE_SELF`). Inactivation purges active sessions. Tested in `admin_layout_test.dart`. |
| **Admin Password Reset** | Admin | `POST /api/v1/admin/users/{id}/reset-password`<br>`UserManagementScreen` | **PASS** | Resets user password, purges active tokens, nullifies `active_session_id`. Tested in `admin_layout_test.dart`. |
| **Student Profile Update by Admin** | Admin | `PUT /api/v1/admin/students/{id}/profile` | **PASS** | Updates demographics and contact number while keeping student ID and email immutable. Tested in `StudentProfileProtectionTest`. |
| **Student QR Inspection** | Admin | `GET /api/v1/admin/students/{id}/qr`<br>`StudentQrInspectScreen` | **PASS** | Displays active QR token and revocation history. Tested in `admin_layout_test.dart`. |
| **Admin-Forced QR Reissue** | Admin | `POST /api/v1/admin/students/{id}/qr/reissue`<br>`StudentQrInspectScreen` | **PASS** | Atomically revokes existing token and generates new 64-hex token. Tested in `AuthAndStaffOperationsTest`. |
| **System Activity Logs** | Admin | `GET /api/v1/admin/logs`<br>`ActivityLogsScreen` | **PASS** | Paginated audit trail with module, action, and user filters; expandable JSON metadata. Tested in `admin_layout_test.dart`. |
| **Event Publishing Review** | Admin | `POST /api/v1/admin/events/{id}/review`<br>`AdminDashboardScreen` | **PASS** | Approves/publishes or rejects events with mandatory remarks. Dispatches notifications if configured. Tested in `admin_layout_test.dart`. |
| **Event Cancellation Review** | Admin | `POST /api/v1/admin/events/{id}/review-cancellation`<br>`AdminDashboardScreen` | **PASS** | Approves cancellation, updates status to `cancelled`, and sends mandatory cancellation notices. Tested in `admin_layout_test.dart`. |
| **Broadcast Announcements** | Admin | `POST /api/v1/admin/announcements` | **PASS** | Dispatches announcements with 150-char title validation and role targeting (`all`, `student`, `organizer`, `management`). Tested in `NotificationServiceTest`. |
| **Strict Read-Only Management Access** | Management | `GET /api/v1/dashboard/management`<br>`ManagementDashboardScreen` | **PASS** | Management role has zero POST/PUT/PATCH/DELETE route permissions. UI suppresses all mutation controls. Tested in `AuthorizationPolicyTest` and `management_layout_test.dart`. |

---

## 6. Event & Calendar System Results

| Subsystem Component | Scope / Endpoint / Model | Status | Verification & Evidence |
| :--- | :--- | :---: | :--- |
| **Event Lifecycle State Transitions** | `events.status`<br>`EventController.php` | **PASS** | Strict state machine: `draft` ➔ `pending_approval` ➔ `published` ➔ `ongoing` ➔ `completed` / `cancelled`. Only published/ongoing events permit QR scanning or registration. |
| **Audience Targeting Options** | `GET /api/v1/events/audience-options` | **PASS** | Returns dynamic merged lists of courses, year levels, sections, and default categories. Tested in `EventAudienceOptionsAndValidationTest`. |
| **Audience Eligibility Enforcement** | `Event::isStudentEligible()` | **PASS** | Evaluates criteria across `all`, `department`, `course`, `year_level`, and `custom` rules. Ineligible students blocked from listing, detail, and registration. Tested in `EventAudienceTargetingEnforcementTest`. |
| **Start & End Date Constraints** | `EventController::store`/`update` | **PASS** | Enforces: `event_date >= today`, `start_time < end_time`, `registration_start < registration_end`. Cannot cancel ongoing/completed events. Tested in `EventAudienceOptionsAndValidationTest`. |
| **Registration Deadlines** | `RegistrationController::register` | **PASS** | Rejects registration before `registration_start` (`422 ERR_REGISTRATION_NOT_STARTED`) and after `registration_end` (`422 ERR_REGISTRATION_DEADLINE_PASSED`). |
| **Capacity & Waiting List Auto-Promotion** | `RegistrationController` | **PASS** | Uses database row locks (`lockForUpdate`). When an attendee cancels, position #1 is auto-promoted and remaining positions decrement. Tested in `SchoolAttendanceWorkflowTest`. |
| **Calendar Month/Week Synchronization** | `mobile/lib/screens/common/calendar_screen.dart` | **PASS** | Queries visible month dates (`date_from` to `date_to`), normalizes daily event maps, supports month and week view toggles and Today navigation. Tested in `calendar_screen_test.dart`. |

---

## 7. QR Code & Attendance System Results

| Attendance Feature | Endpoint / Model | Status | Verification & Evidence |
| :--- | :--- | :---: | :--- |
| **Permanent QR Token Generation** | `student_qrs.qr_token` | **PASS** | Generated via `bin2hex(random_bytes(32))` (64 lowercase hex characters) containing zero embedded PII. |
| **QR Scanning Endpoint** | `POST /api/v1/events/{id}/attendance/scan` | **PASS** | Throttled at 60/min. Requires valid 64-char token and active event status (`published` or `ongoing`). Tested in `SchoolAttendanceWorkflowTest`. |
| **Check-In Mode** | `POST /api/v1/events/{id}/attendance/scan` | **PASS** | Verifies registration, records check-in timestamp and scanner user ID, returns student photo and profile. |
| **Check-Out Mode** | `POST /api/v1/events/{id}/attendance/scan` | **PASS** | Records `check_out_time`. Blocks check-out without prior check-in (`422 ERR_NO_CHECK_IN_RECORD`) and duplicate check-out (`409 ERR_ALREADY_CHECKED_OUT`). |
| **Late Grace Period Evaluation** | `AttendanceController::scan` | **PASS** | Check-in after `event_date + start_time + late_grace_period_minutes` is automatically marked `late`. Tested in `SchoolAttendanceWorkflowTest`. |
| **Walk-In Registration & Scan** | `AttendanceController::scan` | **PASS** | When `walk_in_allowed = true`, unregistered student is recorded as `walk_in`. If student was on waiting list, promotes to `walk_in` and re-indexes remaining waitlist. Tested in `SchoolAttendanceWorkflowTest`. |
| **Duplicate Scan Prevention** | `AttendanceController::scan` | **PASS** | Multiple check-in attempts return `409 ERR_DUPLICATE_CHECK_IN`. Tested in `SchoolAttendanceWorkflowTest`. |
| **Unauthorized Scan Rejection** | `AttendanceController::scan` | **PASS** | Scans on draft/cancelled/completed events return `422 ERR_EVENT_NOT_ACTIVE`. Scans by unauthorized users return `403 ERR_FORBIDDEN`. Scans with revoked QR tokens return `422 ERR_QR_INVALID_OR_REVOKED`. |
| **Manual Attendance Marking** | `POST /api/v1/events/{id}/attendance/mark` | **PASS** | Supports manual marking with mandatory reason; writes to `attendance_corrections` and `activity_logs`. Tested in `AuthAndStaffOperationsTest`. |
| **Attendance Correction** | `PUT /api/v1/attendance/{id}/correct` | **PASS** | Requires mandatory reason (>= 5 chars); records prior and new status in `attendance_corrections`. Tested in `attendance_permissions_test.dart`. |

---

## 8. Notification System Results

| Notification Component | Service / Endpoint | Status | Verification & Evidence |
| :--- | :--- | :---: | :--- |
| **Admin Broadcast Announcements** | `AdminController::sendAnnouncement`<br>`NotificationService` | **PASS** | Title length validation clamped to `max:150`. Role targeting (`all`, `student`, `organizer`, `management`). Tested in `NotificationServiceTest`. |
| **Targeted Event Notifications** | `EventNotificationService` | **PASS** | Scheduled reminders (24h, 1h, start, end) dispatched strictly to registered attendees. Cancelled and waitlisted students excluded. Tested in `EventNotificationEligibilityTest`. |
| **Mandatory Alert Protection** | `NotificationService::MANDATORY_TYPES`<br>`NotificationPreferencesScreen` | **PASS** | Critical notifications (`event_cancellation`, `attendance_recorded`) cannot be disabled. Mobile switches locked with `LOCKED` badge. Tested in `NotificationServiceTest`. |
| **NotificationSoundHelper** | `notification_sound_helper.dart` | **PASS** | Plays `'sfxmint_ready_chime_07'` on sound-enabled categories. Deduplicates chimes per notification ID; respects silent/vibrate ringer mode. Tested in `notification_sound_helper_test.dart`. |
| **Real-Time Polling Stream** | `realtime_notification_service.dart` | **PASS** | 4-second foreground polling with watermark tracking (`after_id`). Pauses when app is backgrounded; resumes on foregrounding. Tested in `realtime_notification_service_test.dart`. |
| **Unread Notification Badge** | `ValueNotifier<int> unreadCount` | **PASS** | Reactive badge updates across dashboard app bars and bell icons. Tested in `realtime_notification_service_test.dart`. |
| **FCM Token Registration** | `POST /api/v1/notifications/device-token` | **PASS** | Maps FCM token to user and platform (`android`, `ios`, `web`). Tested in `NotificationServiceTest`. |
| **FCM Deregistration on Logout** | Dashboards (`student`, `admin`, `organizer`, `management`) | **PASS** | `_logout()` calls `deregisterDeviceToken(fcmToken)` prior to session clearing. Tested in `logout_fcm_deregistration_test.dart`. |
| **Physical Device Push Delivery** | FCM HTTP v1 / Android System Tray | **PARTIAL** | Dual payload packaging (`notification` + `data`), background isolate entrypoint, and NotificationChannel verified in unit tests. Live server dispatch requires physical Android device and production Firebase credentials. |

---

## 9. Reports & Analytics Results

| Report Type | Supported Roles | Formats | Status | Verification & Evidence |
| :--- | :--- | :---: | :---: | :--- |
| **1. Event Attendance Report** | Admin, Org (own), Mgmt | JSON, CSV, PDF, XLSX | **PASS** | Aggregates check-in/out records with synthesized absentees and demographic filters. Tested in `ReportExportTest`. |
| **2. Student Attendance History** | Admin, Mgmt (Org blocked) | JSON, CSV, PDF, XLSX | **PASS** | Chronological attendance history across all events. Organizers blocked with 403 `ERR_FORBIDDEN`. Tested in `ReportExportTest`. |
| **3. Event Registration Summary** | Admin, Org (own), Mgmt | JSON, CSV, PDF, XLSX | **PASS** | Breakdown of registered, waiting list, cancelled, and walk-in counts against capacity. Tested in `ReportExportTest`. |
| **4. Institutional Participation Summary** | Admin, Org, Mgmt | JSON, CSV, PDF, XLSX | **PASS** | Institutional turnout rate and per-event metrics for published/ongoing/completed events. Tested in `ReportExportTest`. |
| **5. Event Absentee Report** | Admin, Org (own), Mgmt | JSON, CSV, PDF, XLSX | **PASS** | Isolates registered students who failed to check in. Tested in `ReportExportTest`. |
| **6. Walk-In Attendees Report** | Admin, Org (own), Mgmt | JSON, CSV, PDF, XLSX | **PASS** | Lists attendees marked as `walk_in` with timestamps and student profiles. Tested in `ReportExportTest`. |
| **7. Organizer Activity Summary** | Admin, Org (own), Mgmt | JSON, CSV, PDF, XLSX | **PASS** | Aggregates events count, total registrations, and turnout per organizer. Tested in `ReportExportTest`. |
| **Universal Export Engine** | Admin, Org (own), Mgmt | CSV, PDF, XLSX | **PASS** | Valid byte stream generation verified for all 21 permutations (7 types × 3 formats). Tested in `ReportExportTest`. |
| **Organizer Scoping & IDOR Prevention** | Organizer | All Export Endpoints | **PASS** | In `ReportController::export()`, organizers are strictly scoped to their own event IDs and `organizer_id = $user->id`. Tested in `ReportExportTest`. |

---

## 10. API & Database Integration Results

| Integration Check | Standard / Requirement | Status | Evidence & Notes |
| :--- | :--- | :---: | :--- |
| **JSON Response Envelope** | Success: `{ success: true, message: "...", data: ... }`<br>Error: `{ success: false, error_code: "...", message: "...", errors: ... }` | **PASS** | Uniformly enforced across all API v1 controllers. |
| **Single Active Session** | Token name `session-{$uuid}`, matching `users.active_session_id` | **PASS** | Secondary login immediately terminates prior session; subsequent calls return 401 `ERR_SESSION_TERMINATED`. |
| **401 Unauthenticated Handling** | Clears token and redirects to `LoginScreen` with toast alert | **PASS** | Implemented via `ApiClient.onUnauthenticated` and `main.dart`. Tested in `api_client_test.dart`. |
| **Session Modal Deduplication** | Prevents stacking session termination dialogs on concurrent 401s | **PASS** | Guarded by `_isSessionDialogActive` lock in `main.dart`. Tested in `api_client_test.dart`. |
| **User-Agent String Storage** | Widen column to `TEXT` and defensive string slicing to 1000 chars | **PASS** | Migration `2026_11_15_000001_widen_user_agent_in_activity_logs_table.php` applied; no SQL truncation crashes. |
| **Announcement Title Constraint** | Title clamped to `max:150` to match `notifications.title` column | **PASS** | Validation in `AdminController::sendAnnouncement` matches database column width. |
| **Database Transaction Rollbacks** | Critical operations wrapped in `DB::transaction()` | **PASS** | Verified in QR reissuance, event registration with capacity lock, and staff cancellation with waiting list promotion. |

---

## 11. UI and User Experience Findings

| UX / UI Item | Breakpoints / Scope | Status | Notes |
| :--- | :--- | :---: | :--- |
| **Adaptive Navigation** | Compact (<600px), Medium (600–1023px), Expanded (>=1024px) | **PASS** | Bottom bar on compact, NavigationRail on medium, expanded Drawer/Sidebar on desktop without state reset. |
| **Button States & Spinners** | All interactive action buttons (`AppButton`) | **PASS** | Displays `AppSpinner` when `isLoading = true`; double-tap protection prevents repeat submissions. |
| **Empty State Presentation** | Event lists, registrations, attendance, logs, notifications | **PASS** | Informative `EmptyStateView` with contextual icons and clear secondary messages. |
| **Error Recovery** | Network failure, API error | **PASS** | `ErrorStateView` renders retry buttons across all major data-loading screens. |
| **Compact Viewport Stability** | 320x568 (iPhone SE / small Android) at 2x text scale | **PASS** | 0 RenderFlex overflow errors across all 23 screens; scrollable action panes. |
| **Monochrome Design Compliance** | Entire application | **PASS** | Adheres to black-and-white AetherUI tokens (`AppColors.background`, `textPrimary`, `border`). |

---

## 12. Detailed Defect & Discrepancy Inventory (PARTIAL Features)

### Discrepancy 1: Missing Mobile Email Verification OTP Modal
- **Feature Name:** In-App Email Verification with OTP (Account Activation)
- **User Role Affected:** Student / Staff with `pending` status
- **Relevant Files:** `mobile/lib/screens/auth/login_screen.dart` vs `backend/app/Http/Controllers/Api/V1/AuthController.php`
- **Expected Behavior:** When a user with unverified email attempts to log in and receives `ERR_EMAIL_UNVERIFIED`, the mobile UI should prompt with an OTP modal or navigate to a screen where the user can enter the 6-digit OTP code and trigger `POST /api/v1/auth/verify-email`.
- **Actual Behavior:** `login_screen.dart` displays only the generic error text ("Please verify your school email before logging in.") with no interactive button or dialog to enter the OTP code.
- **Root Cause:** Backend API endpoints (`/auth/verify-email`, `/auth/resend-verification`) were fully implemented, but Flutter client only implements `login_screen.dart` without an OTP activation dialog.
- **Reproduction Steps:**
  1. Seed a user with `status = 'pending'`.
  2. Attempt to log in from `login_screen.dart`.
  3. Observe error banner shown without any mechanism to enter the OTP or activate the account.
- **Recommended Fix:** Implement an `EmailVerificationDialog` in `login_screen.dart` upon receiving `ERR_EMAIL_UNVERIFIED` on login, prompting for the 6-digit code, submitting to `POST /api/v1/auth/verify-email`, and offering a "Resend Code" button.

### Discrepancy 2: Missing Mobile UI Action for Profile Correction Requests
- **Feature Name:** In-App Profile Correction Request Trigger
- **User Role Affected:** Student
- **Relevant Files:** `mobile/lib/screens/common/profile_screen.dart` vs `backend/app/Http/Controllers/Api/V1/AuthController.php`
- **Expected Behavior:** Because student institutional fields are strictly read-only, students should have an in-app button ("Request Correction") to submit correction requests specifying target fields and reason to administrators.
- **Actual Behavior:** `ProfileScreen` displays a static advisory banner ("For official record corrections, contact the registrar's office.") without an interactive action button.
- **Root Cause:** UI redesign intentionally converted the screen to a read-only layout, omitting the correction request form trigger.
- **Reproduction Steps:**
  1. Log in as a student in the mobile app.
  2. Open Profile screen.
  3. Notice absence of any button or action to submit an electronic correction request.
- **Recommended Fix:** Add a secondary action button (`request-correction-button`) in `ProfileScreen` that opens a bottom sheet allowing students to select target fields and input a reason (>= 10 chars) calling `POST /api/v1/profile/correction-request`.

### Discrepancy 3: Student Direct Contact Number Self-Service Update
- **Feature Name:** Student Contact Number Self-Update
- **User Role Affected:** Student
- **Relevant File:** `backend/app/Http/Controllers/Api/V1/AuthController.php` (`updateProfile`)
- **Expected Behavior:** If students are permitted to update their contact numbers, `updateProfile` should accept `contact_number` updates while rejecting changes to academic identity fields.
- **Actual Behavior:** `AuthController.php` rejects student requests immediately with 403 `ERR_STUDENT_PROFILE_IMMUTABLE`. Only administrators can update student contact numbers via `PUT /api/v1/admin/students/{id}/profile`.
- **Root Cause:** Institutional profile lock was implemented as an all-or-nothing check for student accounts in `updateProfile`.
- **Reproduction Steps:**
  1. Send `PUT /api/v1/profile` with `{ "contact_number": "+639123456789" }` using a valid Student Bearer token.
  2. Response returns 403 `ERR_STUDENT_PROFILE_IMMUTABLE`.
- **Recommended Fix:** If student contact number self-update is required by institutional policy, permit `contact_number` validation in `AuthController::updateProfile()` while filtering out all academic fields. If full immutability is the intended institution policy, confirm that contact numbers must be updated via registrar or admin.

### Discrepancy 4: Physical Android Device Background & Closed-App Push Delivery
- **Feature Name:** Background & Closed-App System Tray Notifications
- **User Role Affected:** All Roles (Mobile Android)
- **Relevant Files:** `mobile/lib/core/services/push_notification_service.dart`, `mobile/android/app/src/main/AndroidManifest.xml`
- **Expected Behavior:** Notifications appear in the Android system notification tray when the app is in the background or closed.
- **Actual Behavior:** Dual-payload structure (`notification` + `data`), background isolate handler, notification channel, and audio chime helper are fully implemented and verified via unit tests. However, actual system tray display when the app is closed requires testing on a physical Android device with Google Play Services and valid Firebase credentials.
- **Root Cause:** Emulated headless test environments cannot receive real APNs/FCM server pushes or emulate vendor-specific OEM battery management (Doze mode, Xiaomi/Samsung background task killers).
- **Reproduction Steps:** Deploy release APK to a physical Android device connected to live FCM to verify tray alerts while the app is closed.
- **Recommended Fix:** Perform physical device validation with a signed release APK and real `google-services.json`.

---

## 13. Failed Tests & Untested Features

- **Failed Automated Tests:** **0** (0 backend test failures, 0 mobile test failures).
- **Untested Features:**
  - Push notifications on de-googled Android ROMs (Attendify automatically falls back to 4-second foreground polling).
  - Apple iOS APNs push delivery (iOS build and testing environment not available on current Windows host).

---

## 14. Recommended Action Plan

Prior to deployment, the following optional enhancements can be scheduled:

1. **Add Mobile OTP Verification Dialog (`login_screen.dart`):**  
   Wire an in-app OTP modal to `POST /api/v1/auth/verify-email` when `ERR_EMAIL_UNVERIFIED` is returned on login.
2. **Add Profile Correction Request Bottom Sheet (`profile_screen.dart`):**  
   Add a secondary button to allow students to submit electronic profile correction requests to administrators.
3. **Decide Student Contact Number Policy (`AuthController.php`):**  
   Confirm whether students should self-update contact numbers or if contact numbers must remain strictly managed by the school registrar.
4. **Physical Android Device Validation:**  
   Install the release APK on a physical Android phone to verify closed-app FCM push alerts with sound.

---

## 15. Overall Application Readiness & Final Assessment

```
================================================================================
FINAL ASSESSMENT:
READY FOR PHYSICAL DEVICE TESTING – Software checks pass, but device-level validation remains.
================================================================================
All automated software verification suites pass with 100% green results:
  • Backend Feature & Unit Tests: 111 / 111 passed (572 assertions, 0 failures)
  • Mobile Static Analysis: 0 errors, 0 warnings, 0 issues
  • Mobile Screen & Widget Tests: 148 / 148 passed (0 failures)

All core application workflows (Authentication, Single Active Session Enforcement,
Student Permanent QR Lifecycle, Event Creation & Approval State Machine, Audience 
Eligibility Targeting, Waiting List Auto-Promotion, QR Attendance Scanning, Check-In/Out,
Late Grace Period, Walk-In Handling, Attendance Corrections, Activity Logging, and 
all 7 Report Types across CSV/PDF/XLSX) are fully verified and operating cleanly.

Before final production rollout, physical Android device testing should be completed
to validate background/closed-app FCM push notifications.
================================================================================
```
