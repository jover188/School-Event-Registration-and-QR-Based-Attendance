# School Event Registration & QR-Based Attendance Management System
## 6-Week Project Plan & Implementation Status

> **Project Title:** School Event Registration and QR-Based Attendance Management System  
> **Duration:** 6 Weeks (Agile Sprints 1–6)  
> **Team Size:** Individual / Small Team  
> **Stack:** Laravel 11 / PHP 8.3+ (Backend API) · Flutter 3.x / Dart 3.x (Mobile & Desktop) · MySQL 8.0+ / MariaDB (Production) · SQLite `:memory:` (Automated Testing)  
> **Detailed Task Plan:** See [`Project_Implementation_Plan.md`](./Project_Implementation_Plan.md) and [`context.md`](./context.md)

---

## Sprint Overview

| Week | Sprint | Focus Area | Status |
|------|--------|------------|--------|
| 1 | Sprint 1 | Requirements, Architecture & Database Design | ✅ Done |
| 2 | Sprint 2 | Backend Core — Auth, QR, Events, Migrations | ✅ Done |
| 3 | Sprint 3 | Registration, Attendance, Dashboards & RBAC API | ✅ Done |
| 4 | Sprint 4 | Reports, Notifications, Scheduled Tasks & Policy Tests | 🔄 In Progress (Core Done, Continuations Remaining) |
| 5 | Sprint 5 | Flutter Mobile UI — Core Screens Wired & Secondary Screens | 🔄 In Progress (9 Screens Wired, Continuations Remaining) |
| 6 | Sprint 6 | Full Export Coverage, Secondary Screens & E2E Polish | ⬜ Upcoming |

---

## 1. Already Made (Completed Deliverables)

### Week 1 — Sprint 1: Requirements, Architecture & Database Design ✅
- [x] **Software Requirements Specification (SRS v1.1 Baseline)** — [`School_Event_Attendance_SRS_v1.0.md`](./School_Event_Attendance_SRS_v1.0.md) (audited and aligned across all 35 sections)
- [x] **System Architecture & Database Design** — [`System_Architecture_and_Database_Design.md`](./System_Architecture_and_Database_Design.md)
  - High-level multi-tier architecture diagram
  - Sequence diagrams (single-session login flow, atomic QR scan & verification flow)
  - State machine diagrams (event lifecycle, registration & waiting list lifecycle)
  - 13-domain-table Entity-Relationship (ER) diagram & MySQL 8.0+ DDL
- [x] **REST API Specification** — [`REST_API_Specification.md`](./REST_API_Specification.md) (all 46 implemented v1 endpoints + auth verification/reset specs)
- [x] **OpenAPI 3.0.3 Machine-Readable Spec** — [`openapi.yaml`](./openapi.yaml)
- [x] **Agent & Context Documentation** — [`AGENTS.md`](./AGENTS.md), [`context.md`](./context.md), and [`Project_Implementation_Plan.md`](./Project_Implementation_Plan.md)

### Week 2 — Sprint 2: Backend Core — Auth, QR, Events ✅
- [x] Laravel 11 scaffolded in `backend/` with Laravel Sanctum 4.x
- [x] 13 domain table migrations + Sanctum `personal_access_tokens` & Laravel system tables
- [x] 13 Eloquent Models with full relationships, capacity helpers, and `ActivityLog::log()`
- [x] `AuthController` — `POST /api/v1/auth/login` (numeric student ID or email), `POST /api/v1/auth/logout`, `GET /api/v1/profile`, `PUT|POST /api/v1/profile`, `POST /api/v1/profile/change-password` (public self-registration disabled; pre-provisioned via institutional seeders/middleware)
- [x] `StudentQRController` — `GET /api/v1/student/qr`, `POST /api/v1/student/qr/reissue`, `GET /api/v1/admin/students/{id}/qr`
- [x] `EventController` — `GET /api/v1/events`, `GET /api/v1/events/{id}`, `POST /api/v1/events`, `PUT /api/v1/events/{id}`, `POST /api/v1/events/{id}/submit-approval`, `POST /api/v1/admin/events/{id}/review`, `POST /api/v1/events/{id}/request-cancellation`, `POST /api/v1/admin/events/{id}/review-cancellation`
- [x] Custom Middleware: `CheckRole` (`role` alias) + `EnforceSingleSession` (`single.session` alias)
- [x] Seeders: `RoleSeeder` (4 roles) + `UserSeeder` (4 demo accounts + student `20260001` with permanent 64-char hex QR)
- [x] MariaDB/MySQL `school_event_attendance` database migrated & seeded; `phpunit.xml` isolated on SQLite `:memory:`

### Week 3 — Sprint 3: Registration, Attendance & Scanner API ✅
- [x] `RegistrationController` — `POST /api/v1/events/{id}/register` (with capacity & waiting list placement), `DELETE /api/v1/events/{id}/cancel-registration` (with transactional waiting list auto-promotion), `GET /api/v1/events/{id}/registrations`, `GET /api/v1/student/registrations`
- [x] `AttendanceController` — `POST /api/v1/events/{id}/attendance/scan` (check-in/out modes, grace-period late detection, walk-in support with waiting list re-indexing, student profile photo response), `GET /api/v1/events/{id}/attendance`, `PUT /api/v1/attendance/{id}/correct`, `GET /api/v1/student/attendance-history`
- [x] `NotificationController` — `GET /api/v1/notifications`, `PATCH /api/v1/notifications/{id}/read`, `POST /api/v1/notifications/mark-all-read`, `GET|PUT /api/v1/notifications/preferences`, `POST|DELETE /api/v1/device-tokens`
- [x] `DashboardController` — `GET /api/v1/dashboard/{student|organizer|management|admin}`
- [x] `AdminController` — `GET|POST /api/v1/admin/users`, `PATCH /api/v1/admin/users/{id}/status`, `POST /api/v1/admin/users/{id}/reset-password`, `GET /api/v1/admin/logs`
- [x] `ReportController` — 7 JSON report endpoints + CSV/PDF/Excel exports for `event_attendance` and `absentee` + CSV exports for `walk_in` and `student_history`
- [x] Scheduled Console Commands (`backend/routes/console.php`): `events:send-reminders-24h`, `events:send-reminders-1h`, `notifications:purge` (30-day retention), `events:auto-close`
- [x] Automated Backend Feature Tests:
  - [x] `SchoolAttendanceWorkflowTest` (5 end-to-end domain workflow tests passing)
  - [x] `AuthorizationPolicyTest` (21 RBAC policy tests across all 4 roles passing)

### Week 5 (Initial Phase) — Flutter Application Core & Primary Screens ✅
- [x] Cross-platform targets configured (`linux`, `android`, `web`) and building cleanly on Linux desktop
- [x] `main.dart` — persistent login routing by role + global single-session termination dialog
- [x] `api_client.dart` & `api_constants.dart` — Bearer token auth, multipart upload, 401 session callback
- [x] `login_screen.dart` & `forgot_password_screen.dart` — wired to `/api/v1/auth/login`, `/api/v1/auth/forgot-password`, `/api/v1/auth/reset-password`, and `/api/v1/auth/verify-email` (self-registration removed in favor of institutional pre-provisioning)
- [x] `student_dashboard_screen.dart` — wired to `/api/v1/dashboard/student` and `/api/v1/events`
- [x] `permanent_qr_screen.dart` — wired to `GET /api/v1/student/qr` and `POST /api/v1/student/qr/reissue` with `QrImageView`
- [x] `event_detail_screen.dart` — wired to `GET /api/v1/events/{id}`, `POST /api/v1/events/{id}/register`, and `DELETE /api/v1/events/{id}/cancel-registration`
- [x] `organizer_dashboard_screen.dart` & `qr_scanner_screen.dart` — wired to `/api/v1/dashboard/organizer` and `POST /api/v1/events/{id}/attendance/scan` (check-in & check-out with student photo verification sheet)
- [x] `management_dashboard_screen.dart` — wired to `GET /api/v1/dashboard/management`
- [x] `admin_dashboard_screen.dart` — wired to `GET /api/v1/dashboard/admin` and `POST /api/v1/admin/events/{id}/review`

---

## 2. Continuations (Remaining Work by Sprint)

> See [`Project_Implementation_Plan.md`](./Project_Implementation_Plan.md) for step-by-step implementation tasks, file lists, and test commands.

### Sprint 4 Continuations — Backend Reports, Auth Extensions & FCM Dispatch 🔄
- [x] **Complete PDF, Excel (`.xlsx`), and CSV Exports for All 7 Report Types:**
  - Add Excel export classes (`app/Exports/`) and DomPDF Blade views (`resources/views/reports/`) for `student_history`, `registration_summary`, `participation_summary`, `walk_in`, and `organizer_summary`.
  - Add CSV streaming branches in `ReportController::export()` for `registration_summary`, `participation_summary`, and `organizer_summary`.
  - Include non-attending registered students as `status: "absent"` in `ReportController::eventAttendance()`.
  - Support `date_from`, `date_to`, `department`, `year_level`, and `status` filtering on report endpoints.
- [x] **Email Verification & Self-Service Password Reset Endpoints:**
  - Implement `POST /api/v1/auth/verify-email`, `POST /api/v1/auth/forgot-password`, and `POST /api/v1/auth/reset-password`.
- [x] **Staff & Admin Operational Endpoints:**
  - Allow Organizer/Admin to cancel a student's registration (`REG-009`), mark/correct attendance for absent registered students (`ATT-011`), reissue/revoke student QR as Admin (`ADMIN-004`), and broadcast Admin announcements (`NOTIF-002`).
- [x] **FCM Push Notification Service (`NotificationService`):**
  - Centralize notification creation + FCM HTTP v1 push dispatch respecting `NotificationPreference` (with mandatory `event_cancellation` and `attendance_recorded`).

### Sprint 5 — Flutter Secondary Screens & Security Polish ✅
- [x] **Secure Token Storage:** Migrate token persistence in `mobile/lib/core/network/api_client.dart` from `SharedPreferences` to `FlutterSecureStorage` (with fallback).
- [x] **Profile & Notification Screens (All Roles):**
  - `ProfileScreen` (`GET /api/v1/profile`, `POST /api/v1/profile`, `POST /api/v1/profile/change-password`).
  - `NotificationsScreen` (`GET /api/v1/notifications`, `PATCH /api/v1/notifications/{id}/read`, `POST /api/v1/notifications/mark-all-read`).
  - `NotificationPreferencesScreen` (`GET|PUT /api/v1/notifications/preferences`).
- [x] **Student Secondary Screens:**
  - `MyRegistrationsScreen` (`GET /api/v1/student/registrations`).
  - `MyAttendanceHistoryScreen` (`GET /api/v1/student/attendance-history`).
- [x] **Organizer Event Lifecycle & Attendance Screens:**
  - `EventFormScreen` (`POST /api/v1/events`, `PUT /api/v1/events/{id}`).
  - Submit for approval (`POST /api/v1/events/{id}/submit-approval`) & request cancellation (`POST /api/v1/events/{id}/request-cancellation`) UI controls.
  - `EventRegistrationsScreen` (`GET /api/v1/events/{id}/registrations`).
  - `LiveAttendanceScreen` (`GET /api/v1/events/{id}/attendance`) with manual attendance correction dialog (`PUT /api/v1/attendance/{id}/correct`).
- [x] **Reports & Export Screen (Organizer, Management, Admin):**
  - `ReportsScreen` wired to `GET /api/v1/reports/*` and `GET /api/v1/reports/export`.
- [x] **Admin Management Screens:**
  - `UserManagementScreen` (`GET|POST /api/v1/admin/users`, `PATCH /api/v1/admin/users/{id}/status`, `POST /api/v1/admin/users/{id}/reset-password`).
  - Event cancellation review UI (`POST /api/v1/admin/events/{id}/review-cancellation`).
  - `StudentQrInspectScreen` (`GET /api/v1/admin/students/{id}/qr`).
  - `ActivityLogsScreen` (`GET /api/v1/admin/logs`).

### Sprint 6 — Testing & Verification ✅
- [x] **Expanded Backend Test Suite:** Report export tests (`ReportExportTest`), auth & staff operation tests (`AuthAndStaffOperationsTest`), notification preference & scheduled command tests (`NotificationServiceTest`), all 43 tests passing.
- [x] **Expanded Flutter Widget Tests:** Reusable widgets, forms, model parsing, and screen rendering tests (`mobile/test/widget_test.dart`), 13 tests passing with 0 analyzer issues.

### Remaining Tasks & Post-Baseline Roadmap 📋
- [ ] **School Database Integration / Synchronization Middleware:**
  - Build an institutional sync command/service (e.g. `php artisan students:sync-school-db` or API webhook) to ingest student records from the school's central database / SIS, automatically populating `users`, `students`, and generating 64-character permanent QR tokens in `student_qrs`.
- [ ] **Live Physical Device Deployment (Poco F7 / Android Hardware):**
  - Connect physical device via USB or Wireless ADB (`adb connect`), test real-world camera performance for QR scanning, accessibility, and high-density check-in response times.
- [ ] **Production Firebase Cloud Messaging (FCM) Credentials:**
  - Add production `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) and configure Google service account private key in backend `.env` for real-time mobile push notifications.
- [ ] **Offline QR Scanning & Local Batch Sync (SRS §11 & §33.4):**
  - Local SQLite / Hive caching on mobile for organizer QR scanning when venue Wi-Fi is intermittent, with automatic batch sync (`POST /api/v1/events/{id}/attendance/sync-offline`).
- [ ] **Production Deployment & Server Hardening:**
  - Production Nginx / PHP-FPM configuration, SSL/TLS certificates, supervisor daemon for `php artisan queue:work`, and systemd cron for `php artisan schedule:run`.
- [ ] **End-to-End User Acceptance Testing (UAT):**
  - Structured UAT walkthrough with school administrators and event organizers using demo seeded data.

---

## Technical Reference

### Seeded Test Accounts
| Role | Login | Password |
|------|-------|----------|
| Administrator | `admin@school.edu` | `Admin@12345` |
| Organizer | `organizer@school.edu` | `Organizer@12345` |
| Management | `management@school.edu` | `Management@12345` |
| Student | `20260001` or `student@school.edu` | `Student@12345` |

### Running the Backend
```bash
cd backend
php artisan serve --host=127.0.0.1 --port=8000
# API available at: http://127.0.0.1:8000/api/v1/
```

### Running Backend Tests
```bash
cd backend
php artisan test
# Runs against isolated in-memory SQLite database
```

### Resetting & Seeding the MySQL/MariaDB Database
```bash
cd backend
php artisan migrate:fresh --seed
```

### Running the Flutter Application
```bash
cd mobile
/home/thea/development/flutter/bin/flutter run -d linux
```
