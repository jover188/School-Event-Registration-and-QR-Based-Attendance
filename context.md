# Project Context (`context.md`)

## School Event Registration and QR-Based Attendance Management System

> **Core Architectural Rule:**  
> *The permanent QR code (`64-character cryptographic hex token`) identifies the **student**; the event registration and attendance records identify the student's **participation in a specific event**.*

---

## 1. System Overview

The **School Event Registration and QR-Based Attendance Management System** is a decoupled client-server platform built with a **Laravel 11 REST API backend**, **MySQL / MariaDB relational database**, and a **Flutter cross-platform application** (Android, iOS, Linux Desktop, Web).

It replaces manual paper/spreadsheet event workflows with:
- Student self-registration and login via either **numeric Student ID** (e.g., `20260001`) or **school email**.
- **Single active session enforcement** (logging in on a new device invalidates previous tokens).
- **Permanent student QR codes** (`64-char hex`, containing zero PII) with self-service instant reissue/revocation.
- **Event lifecycle governance** requiring Administrator approval before publishing or cancelling events.
- **Automated capacity & waiting list management** with transactional auto-promotion when slots open.
- **QR attendance scanning** supporting both **check-in** and **check-out** modes, configurable **late grace periods** (default 15 minutes), **walk-in attendance** handling, and **on-screen visual identity verification** (student profile photo + full name).
- **7 institutional report types** with **PDF**, **CSV**, and **Excel (`.xlsx`)** export capabilities and complete **audit logging**.

---

## 2. Technology Stack & Local Environment

| Layer | Technology | Local Environment Details |
|---|---|---|
| **Backend Framework** | Laravel 11 / PHP 8.3+ | Served via `php artisan serve --host=127.0.0.1 --port=8000` |
| **Authentication** | Laravel Sanctum 4.x | Bearer token (`session-{uuid}`) + `EnforceSingleSession` middleware |
| **Production/Dev DB** | MySQL 8.0+ / MariaDB 13.x | Database: `school_event_attendance` (`127.0.0.1:3306`, user `root`) |
| **Test Database** | SQLite (`:memory:`) | Configured in `backend/phpunit.xml` for fast, isolated feature tests |
| **Report Engines** | `barryvdh/laravel-dompdf`, `maatwebsite/excel` | PDF Blade views in `backend/resources/views/reports/`, Excel in `backend/app/Exports/` |
| **Mobile / Client** | Flutter 3.x / Dart 3.x | Binary: `/home/thea/development/flutter/bin/flutter` (Targets: Linux Desktop, Android, Web) |
| **QR Libraries** | `qr_flutter` (`^4.1.0`), `mobile_scanner` (`^5.1.0`) | Renders & scans 64-character hex tokens |
| **Push Notifications** | Firebase Cloud Messaging (FCM) | Device token registry via `device_tokens` + in-app `notifications` inbox |

---

## 3. Repository Structure

```text
School-Event-Registration-and-QR-Based-Attendance/
├── AGENTS.md                                      # Workspace rules & conventions for AI coding agents
├── context.md                                     # System context, architecture, and status reference
├── Project_Plan.md                                # 6-Week Agile Sprint Plan & status tracker
├── Project_Implementation_Plan.md                 # Detailed implementation plan (Already Made & Continuations)
├── School_Event_Attendance_SRS_v1.0.md            # Finalized Software Requirements Specification (v1.1 baseline)
├── System_Architecture_and_Database_Design.md     # ER diagrams, state machines, sequence diagrams, MySQL DDL
├── REST_API_Specification.md                      # Complete REST API endpoint & payload reference
├── openapi.yaml                                   # OpenAPI 3.0.3 machine-readable specification
├── backend/                                       # Laravel 11 REST API
│   ├── app/
│   │   ├── Exports/                               # Maatwebsite Excel export classes
│   │   ├── Http/
│   │   │   ├── Controllers/Api/V1/                # 9 v1 API controllers
│   │   │   └── Middleware/                        # CheckRole (RBAC) & EnforceSingleSession
│   │   └── Models/                                # 13 Eloquent domain models
│   ├── database/
│   │   ├── migrations/                            # 13 domain table migrations + Laravel system tables
│   │   └── seeders/                               # RoleSeeder & UserSeeder
│   ├── resources/views/reports/                   # DomPDF Blade templates
│   ├── routes/
│   │   ├── api.php                                # All /api/v1/* routes
│   │   └── console.php                            # Scheduled tasks (reminders, 30-day purge, event status)
│   └── tests/Feature/                             # Workflow & RBAC authorization feature tests
└── mobile/                                        # Flutter Cross-Platform Application
    ├── lib/
    │   ├── core/
    │   │   ├── constants/api_constants.dart       # API base URL & endpoint path constants
    │   │   ├── network/api_client.dart            # HTTP client with Bearer auth & 401 session hook
    │   │   └── theme/app_theme.dart               # Material 3 theme & status badge colors
    │   ├── models/                                # UserModel, StudentModel, EventModel, AttendanceModel
    │   ├── screens/                               # Auth, Student, Organizer, Management, and Admin screens
    │   └── main.dart                              # App entry point, role router & session termination modal
    └── test/                                      # Flutter unit & widget tests
```

---

## 4. Roles & Seeded Credentials

The system enforces strict Role-Based Access Control (`CheckRole` middleware using role `slug`):

| Role ID | Role Name | Slug | Access Summary | Demo Login | Demo Password |
|---|---|---|---|---|---|
| `1` | Administrator | `administrator` | Full control, user/role management, event/cancellation approval, QR inspection, audit logs | `admin@school.edu` | `Admin@12345` |
| `2` | Event Organizer / Staff | `organizer` | Create/manage own events, scan student QR (check-in/out), monitor/correct attendance, export reports | `organizer@school.edu` | `Organizer@12345` |
| `3` | Student | `student` | Self-register, browse/register for events, waiting list, view/reissue permanent QR, attendance history | `student@school.edu` or `20260001` | `Student@12345` |
| `4` | School Management | `management` | **Strictly Read-Only** access to dashboards, events, registrations, attendance, and reports/exports | `management@school.edu` | `Management@12345` |

---

## 5. Database Schema (13 Domain Tables)

1. **`roles`**: `id`, `name`, `slug` (`administrator`, `organizer`, `student`, `management`), `description`
2. **`users`**: `id`, `role_id`, `email`, `password`, `status` (`pending`, `active`, `inactive`), `email_verified_at`, `active_session_id`
3. **`students`**: `id`, `user_id`, `student_id_number` (unique numeric), `first_name`, `middle_name`, `last_name`, `course`, `year_level`, `section`, `department`, `contact_number`, `profile_photo_path`
4. **`student_qrs`**: `id`, `student_id`, `qr_token` (unique 64-char hex), `status` (`active`, `revoked`), `revoked_at`
5. **`events`**: `id`, `organizer_id`, `title`, `description`, `venue`, `event_date`, `start_time`, `end_time`, `registration_start`, `registration_end`, `max_participants` (nullable), `late_grace_period_minutes` (default 15), `walk_in_allowed` (bool), `status` (`draft`, `pending_approval`, `published`, `ongoing`, `completed`, `cancelled`)
6. **`event_approvals`**: `id`, `event_id`, `admin_id`, `approval_type` (`publish`, `cancellation`), `status` (`approved`, `rejected`), `remarks`
7. **`event_registrations`**: `id`, `event_id`, `student_id` (unique `[event_id, student_id]`), `status` (`registered`, `waiting_list`, `cancelled`, `walk_in`), `waiting_list_position`, `registered_at`, `cancelled_at`
8. **`attendances`**: `id`, `event_id`, `student_id` (unique `[event_id, student_id]`), `event_registration_id`, `check_in_time`, `check_out_time`, `status` (`present`, `absent`, `late`, `excused`, `walk_in`), `scanner_id`
9. **`attendance_corrections`**: `id`, `attendance_id`, `corrected_by`, `original_status`, `new_status`, `reason`
10. **`notifications`**: `id`, `user_id`, `title`, `message`, `notification_type`, `is_read`, `payload` (JSON)
11. **`notification_preferences`**: `id`, `user_id`, `new_event_published`, `registration_confirmed`, `event_reminders`, `event_updates`, `waiting_list_promoted`, `admin_announcements`
12. **`device_tokens`**: `id`, `user_id`, `fcm_token`, `platform` (`android`, `ios`)
13. **`activity_logs`**: `id`, `user_id`, `action`, `module`, `record_id`, `metadata` (JSON), `ip_address`, `user_agent`, `created_at`

---

## 6. Implementation Status Summary

### Already Made (Completed)
- **Specifications & Design**: Finalized SRS v1.1, System Architecture & ER/State/Sequence Diagrams, REST API Specification, and OpenAPI 3.0.3 schema.
- **Backend Core (`backend/`)**:
  - All 13 domain migrations, Eloquent models, relationships, and seeders (`RoleSeeder`, `UserSeeder`).
  - `CheckRole` and `EnforceSingleSession` middleware.
  - All 9 API v1 controllers (`AuthController`, `StudentQRController`, `EventController`, `RegistrationController`, `AttendanceController`, `NotificationController`, `DashboardController`, `ReportController`, `AdminController`) covering 49 routes (including `verify-email`, `forgot-password`, `reset-password`, staff registration cancellation, admin QR reissue, manual attendance marking, and admin announcements).
  - Centralized `NotificationService` enforcing mandatory vs. optional user notification preferences.
  - Scheduled console tasks (`event-reminder-24h`, `event-reminder-1h`, `purge-old-notifications`, `auto-close-events`) in `routes/console.php`.
  - Complete PDF (7 DomPDF Blade templates), Excel (7 `Maatwebsite\Excel` export classes), and CSV streaming exports for all 7 institutional report types with optional query filters.
  - 43 automated feature/unit tests (193 assertions) passing on in-memory SQLite (`SchoolAttendanceWorkflowTest`, `AuthorizationPolicyTest`, `ReportExportTest`, `AuthAndStaffOperationsTest`, `NotificationServiceTest`).
- **Mobile Application (`mobile/`)**:
  - Cross-platform Flutter structure (`linux`, `android`, `web`), centralized Material 3 design token system (`AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`), and reusable widget component library (`StatusBadge`, `StatMetricCard`, `EmptyStateView`, `ErrorStateView`, `SectionHeader`, `EventCard`).
  - `ApiClient` with `FlutterSecureStorage` token persistence, Bearer token injection, `postMultipart`, `downloadBytes`, and 401 session termination listener.
  - All 22 screens implemented and wired across all 4 roles:
    - Auth: `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`
    - Common: `ProfileScreen`, `NotificationsScreen`, `NotificationPreferencesScreen`, `ReportsScreen`
    - Student: `StudentDashboardScreen`, `PermanentQrScreen`, `EventDetailScreen`, `MyRegistrationsScreen`, `MyAttendanceHistoryScreen`
    - Organizer: `OrganizerDashboardScreen`, `QrScannerScreen`, `EventFormScreen`, `EventRegistrationsScreen`, `LiveAttendanceScreen`
    - Management: `ManagementDashboardScreen` (strictly Read-Only)
    - Admin: `AdminDashboardScreen`, `UserManagementScreen`, `ActivityLogsScreen`, `StudentQrInspectScreen`
  - 14 Flutter unit and widget tests passing with `0` analyzer issues.

