# Project Context (`context.md`)

## School Event Registration and QR-Based Attendance Management System

> **Core Architectural Rule:**  
> *The permanent QR code (`64-character cryptographic hex token`) identifies the **student**; the event registration and attendance records identify the student's **participation in a specific event**.*

---

## 1. System Overview

The **School Event Registration and QR-Based Attendance Management System** is a decoupled client-server platform built with a **Laravel 11 REST API backend**, **MySQL / MariaDB relational database**, and a **Flutter cross-platform application** (Android, iOS, Linux Desktop, Web).

It replaces manual paper/spreadsheet event workflows with:
- Institutional account integration via the school **Student Information System (SIS)** (and pre-provisioned demo accounts via database seeders in development/demo environments) with login via either **numeric Student ID** (e.g., `20260001`) or **school email** (open self-registration and self-service forgot-password are omitted; student profiles are immutable institutional records with contact number omitted and passwords managed via institutional administrator reset).
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
├── School-Event-Registration-and-QR-Based-Attendance/
├── .agents/
│   ├── rules/                                     # Modular workspace rules connected to context.md & AGENTS.md
│   │   ├── architecture-code-organization.md      # Client-server boundaries & module organization
│   │   ├── communication-reporting.md             # Progress reporting & spec synchronization rules
│   │   ├── data-backend-security.md               # RBAC, Sanctum single-session, QR PII-free & audit rules
│   │   ├── dependencies-external-packages.md      # Package vetting & no-runtime-AI constraints
│   │   ├── existing-project-inspection.md         # Pre-modification inspection & stack discovery
│   │   ├── flutter-development-standards.md       # AetherUI tokens, ApiClient & responsive standards
│   │   ├── phased-development-workflow.md         # Sprint-aligned phased implementation workflow
│   │   ├── testing-quality.md                     # SQLite :memory: safety & Flutter verification gates
│   │   └── ui-ux-rules.md                         # 20-screen inventory, AppShell & accessibility rules
│   └── skills/                                    # Specialized agent workflow & Flutter/Dart skills
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
│   │   └── seeders/                               # RoleSeeder, UserSeeder & DemoSchoolDataSeeder
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
    │   │   └── theme/app_theme.dart               # AetherUI theme & status badge colors
    │   ├── models/                                # UserModel, StudentModel, EventModel, AttendanceModel
    │   ├── screens/                               # Auth, Student, Organizer, Management, and Admin screens
    │   └── main.dart                              # App entry point, role router & session termination modal
    └── test/                                      # Flutter unit & widget tests
```

---

## 4. Roles & Seeded Credentials

The system enforces strict Role-Based Access Control (`CheckRole` middleware using role `slug`). Student and staff accounts are designed to integrate with the school SIS; for local development and demonstrations without live SIS access, accounts and sample domain data are pre-populated via `RoleSeeder`, `UserSeeder`, and `DemoSchoolDataSeeder`:

| Role ID | Role Name | Slug | Access Summary | Demo Login | Demo Password |
|---|---|---|---|---|---|
| `1` | Administrator | `administrator` | Full control, user/role management, event/cancellation approval, QR inspection, audit logs | `admin@school.edu` | `Admin@12345` |
| `2` | Event Organizer / Staff | `organizer` | Create/manage own events, scan student QR (check-in/out), monitor/correct attendance, export reports | `organizer@school.edu` | `Organizer@12345` |
| `3` | Student | `student` | Pre-provisioned/synced institutional account (immutable profile; credentials managed via admin reset), browse/register for events, waiting list, view/reissue permanent QR, attendance history | `student@school.edu` or `20260001` | `Student@12345` |
| `4` | School Management | `management` | **Strictly Read-Only** access to dashboards, events, registrations, attendance, and reports/exports | `management@school.edu` | `Management@12345` |

---

## 5. Database Schema (13 Domain Tables)

1. **`roles`**: `id`, `name`, `slug` (`administrator`, `organizer`, `student`, `management`), `description`
2. **`users`**: `id`, `role_id`, `email`, `password`, `status` (`pending`, `active`, `inactive`), `email_verified_at`, `active_session_id`
3. **`students`**: `id`, `user_id`, `student_id_number` (unique numeric), `first_name`, `middle_name`, `last_name`, `course`, `year_level`, `section`, `department`, `contact_number` (omitted from client profile mutations and student views), `profile_photo_path`
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
  - All 13 domain migrations, Eloquent models, relationships, and seeders (`RoleSeeder`, `UserSeeder`, `DemoSchoolDataSeeder`).
  - `CheckRole` and `EnforceSingleSession` middleware.
  - All 9 API v1 controllers (`AuthController`, `StudentQRController`, `EventController`, `RegistrationController`, `AttendanceController`, `NotificationController`, `DashboardController`, `ReportController`, `AdminController`) covering 47 routes (including `verify-email`, staff registration cancellation, admin QR reissue, manual attendance marking, and admin announcements; student profile mutation via `PUT|POST /api/v1/profile` and student password modification via `POST /api/v1/profile/change-password` strictly return `403 Forbidden` with audit logging; self-service forgot/reset password omitted in favor of administrator reset and SIS integration).
  - Centralized `NotificationService` enforcing mandatory vs. optional user notification preferences.
  - Scheduled console tasks (`event-reminder-24h`, `event-reminder-1h`, `purge-old-notifications`, `auto-close-events`) in `routes/console.php`.
  - Complete PDF (7 DomPDF Blade templates), Excel (7 `Maatwebsite\Excel` export classes), and CSV streaming exports for all 7 institutional report types with optional query filters.
  - 62 automated feature/unit tests (303 assertions) passing on in-memory SQLite (`SchoolAttendanceWorkflowTest`, `AuthorizationPolicyTest`, `ReportExportTest`, `AuthAndStaffOperationsTest`, `NotificationServiceTest`, `DemoSchoolDataSeederTest`, `StudentProfileSecurityTest`).
- **Mobile Application (`mobile/`)**:
  - Cross-platform Flutter structure (`linux`, `android`, `web`) with `ShadApp.custom` (`shadcn_ui`) + Material 3 integration and the **AetherUI** design system (`AppDesignTokens.light` & `AppDesignTokens.dark`: `'Inter'` typography, lightweight `LucideIcons`, Light Mode `#FAFAFA` background, `#FFFFFF` cards/popovers, `#09090B` foreground, `#18181B` primary, `#F4F4F5` secondary/muted/accent/sidebar, `#52525B` muted foreground, `#E4E4E7` borders/inputs, `#71717A` ring; Dark Mode `#09090B` background, `#121214` cards, `#18181B` popovers, `#FFFFFF` foreground/primary, `#27272A` secondary/muted/accent/borders/inputs, `#A1A1AA` muted foreground/ring, `#0F0F12` sidebar; `#14B8A6` Teal success, `#F59E0B` Amber warning, `#EF4444` Red destructive, `8px` (`0.5rem`) radius), `NoSplash.splashFactory`, custom `AppPressable` / `AppButton` controls, adaptive `AppShell` (`<600` slide-over off-canvas drawer with blurred backdrop + `56px` bottom nav, `600–1023` navigation rail, `1024+` `256px` sticky sidebar + blurred `64px` top header), `AppPageScaffold`, and responsive layout primitives (`AppResponsivePage`, `ResponsiveGrid`, `ResponsiveCardSliver`, `ResponsiveQrFrame`).
  - `ApiClient` with `FlutterSecureStorage` token persistence, Bearer token injection, `postMultipart`, `downloadBytes`, and 401 session termination listener.
  - All 20 screens implemented, responsive across phone/tablet/desktop viewports (`320px` at `2x` text scale through `1440px`), and wired across all 4 roles:
    - Auth: `LoginScreen` (`AccountInput`)
    - Common: `ProfileScreen` (read-only institutional identity summary card for students; no contact number or password fields), `NotificationsScreen`, `NotificationPreferencesScreen`, `ReportsScreen`
    - Student: `StudentDashboardScreen`, `PermanentQrScreen`, `EventDetailScreen`, `MyRegistrationsScreen`, `MyAttendanceHistoryScreen`
    - Organizer: `OrganizerDashboardScreen`, `QrScannerScreen` (`ScanResultContent`), `EventFormScreen`, `EventRegistrationsScreen`, `LiveAttendanceScreen`
    - Management: `ManagementDashboardScreen` (strictly Read-Only)
    - Admin: `AdminDashboardScreen`, `UserManagementScreen`, `ActivityLogsScreen`, `StudentQrInspectScreen`
  - 91 Flutter unit and widget tests passing across 13 test files with `0` analyzer issues and clean `flutter build web` compilation.

---

## 7. Connected Documentation & Workspace Rules Map

All authoritative project documentation and `.agents/rules/` files are cross-linked and must remain synchronized:

### Core Specification & Planning Documents
- [`AGENTS.md`](./AGENTS.md) — Master workspace rules, domain invariants, backend/mobile conventions, and verification gates.
- [`School_Event_Attendance_SRS_v1.0.md`](./School_Event_Attendance_SRS_v1.0.md) — Approved Software Requirements Specification (v1.1 baseline).
- [`System_Architecture_and_Database_Design.md`](./System_Architecture_and_Database_Design.md) — Multi-tier architecture, sequence/state diagrams, ER diagram, and MySQL 8.0+ DDL.
- [`REST_API_Specification.md`](./REST_API_Specification.md) & [`openapi.yaml`](./openapi.yaml) — Canonical `/api/v1/*` REST API contracts and response envelopes.
- [`Project_Plan.md`](./Project_Plan.md) & [`Project_Implementation_Plan.md`](./Project_Implementation_Plan.md) — 6-Week Agile Sprint tracker, completed deliverables, and continuation tasks.
- [`backend/README.md`](./backend/README.md) & [`mobile/README.md`](./mobile/README.md) — Subsystem setup, execution, and testing guides.

### Modular Workspace Rules (`.agents/rules/`)
- [`.agents/rules/existing-project-inspection.md`](./.agents/rules/existing-project-inspection.md) — Pre-change inspection of `context.md`, `AGENTS.md`, stack versions, and completed features.
- [`.agents/rules/architecture-code-organization.md`](./.agents/rules/architecture-code-organization.md) — Decoupled Flutter (`mobile/`) ↔ Laravel (`backend/`) architecture and module boundaries.
- [`.agents/rules/data-backend-security.md`](./.agents/rules/data-backend-security.md) — 13 domain tables, 4 RBAC roles, Sanctum single-session guard, 64-char hex QR token with zero PII, and audit logging.
- [`.agents/rules/flutter-development-standards.md`](./.agents/rules/flutter-development-standards.md) — `shadcn_ui` + **AetherUI** design tokens, `ApiClient`, `ApiConstants`, and responsive layout standards.
- [`.agents/rules/ui-ux-rules.md`](./.agents/rules/ui-ux-rules.md) — 20 role-based screens, adaptive `AppShell` navigation, accessibility, and strict read-only `management` UX.
- [`.agents/rules/dependencies-external-packages.md`](./.agents/rules/dependencies-external-packages.md) — Package compatibility and prohibition of in-app runtime AI/LLM SDKs.
- [`.agents/rules/phased-development-workflow.md`](./.agents/rules/phased-development-workflow.md) — Phased execution aligned with `Project_Plan.md` and `Project_Implementation_Plan.md`.
- [`.agents/rules/testing-quality.md`](./.agents/rules/testing-quality.md) — SQLite `:memory:` test isolation (`php artisan test`) and Flutter static analysis/widget testing (`flutter analyze`, `flutter test`).
- [`.agents/rules/communication-reporting.md`](./.agents/rules/communication-reporting.md) — Evidence-backed progress reporting and cross-document synchronization.

