# AGENTS.md — Workspace Rules & Agent Guidelines

This document defines the mandatory architectural constraints, domain rules, coding conventions, and workflow instructions for all AI agents operating in the **School Event Registration and QR-Based Attendance Management System** repository.

---

## 1. Authoritative Documentation & Context

Before modifying code, schemas, or API contracts, consult the root specification files and modular workspace rules:
- [`context.md`](./context.md) — High-level system context, database tables, roles, current implementation status, and connected rules map.
- [`Project_Implementation_Plan.md`](./Project_Implementation_Plan.md) & [`Project_Plan.md`](./Project_Plan.md) — Completed deliverables ("Already Made") and prioritized remaining tasks ("Continuations").
- [`School_Event_Attendance_SRS_v1.0.md`](./School_Event_Attendance_SRS_v1.0.md) — Finalized Software Requirements Specification (v1.1 baseline).
- [`System_Architecture_and_Database_Design.md`](./System_Architecture_and_Database_Design.md) — ER diagram, state machines, sequence diagrams, and MySQL 8.0 DDL.
- [`REST_API_Specification.md`](./REST_API_Specification.md) & [`openapi.yaml`](./openapi.yaml) — Canonical REST API v1 routes, request payloads, and response envelopes.
- [`backend/README.md`](./backend/README.md) & [`mobile/README.md`](./mobile/README.md) — Backend and Mobile subsystem developer guides.
- **Modular Workspace Rules (`.agents/rules/`):**
  - [`.agents/rules/existing-project-inspection.md`](./.agents/rules/existing-project-inspection.md) — Repository inspection & stack discovery before edits.
  - [`.agents/rules/architecture-code-organization.md`](./.agents/rules/architecture-code-organization.md) — Decoupled client-server architecture & module boundaries.
  - [`.agents/rules/data-backend-security.md`](./.agents/rules/data-backend-security.md) — Data entities, RBAC, single-session auth, QR security, and audit logging.
  - [`.agents/rules/flutter-development-standards.md`](./.agents/rules/flutter-development-standards.md) — Flutter/Dart conventions, **AetherUI** design system, and `ApiClient` usage.
  - [`.agents/rules/ui-ux-rules.md`](./.agents/rules/ui-ux-rules.md) — 20-screen inventory, adaptive `AppShell` navigation, and accessibility rules.
  - [`.agents/rules/dependencies-external-packages.md`](./.agents/rules/dependencies-external-packages.md) — Dependency approval and no-runtime-AI rules.
  - [`.agents/rules/phased-development-workflow.md`](./.agents/rules/phased-development-workflow.md) — Sprint-aligned phased implementation workflow.
  - [`.agents/rules/testing-quality.md`](./.agents/rules/testing-quality.md) — Backend SQLite `:memory:` and Flutter verification standards.
  - [`.agents/rules/communication-reporting.md`](./.agents/rules/communication-reporting.md) — Evidence-backed reporting and documentation updates.

Whenever an API route, request/response field, status enum, or database column changes, keep `context.md`, `REST_API_Specification.md`, `openapi.yaml`, `backend/routes/api.php`, and `mobile/lib/core/constants/api_constants.dart` synchronized.

---

## 2. Non-Negotiable Domain & Architectural Invariants

1. **Decoupled Client-Server Architecture:**
   - The Flutter mobile app (`mobile/`) must **never** connect directly to MySQL/MariaDB. All operations go through `/api/v1/*` JSON REST endpoints on the Laravel backend (`backend/`).
   - The backend is the sole authority for attendance validation, late evaluation, capacity checks, and waiting list promotion.

2. **Permanent Student QR Identity vs. Event Participation:**
   - Each student has **one active permanent QR code** (`student_qrs.qr_token`) generated via `bin2hex(random_bytes(32))` (64 lowercase hexadecimal characters) with **zero embedded personal information**.
   - Reissuing a QR code (`POST /api/v1/student/qr/reissue`) must atomically set all previous active tokens for that student to `status = 'revoked'` (`revoked_at = now()`) inside a `DB::transaction()`.
   - Attendance belongs to a `(event_id, student_id)` pair in `attendances`, linked to `event_registrations`.

3. **Four Fixed RBAC Roles (`roles.slug`):**
   - `administrator` (Role ID `1`): Full system management, user creation/status/password reset, event publishing & cancellation review, QR inspection, activity logs.
   - `organizer` (Role ID `2`): Create/edit own events, submit for approval, request cancellation, scan QR codes (check-in/out), correct attendance for own events, view/export reports.
   - `student` (Role ID `3`): Pre-provisioned institutional student account (synchronized from school database / seeders). Authenticate via numeric Student ID or school email. Browse/register/cancel events, join waiting lists, view/reissue permanent QR, view own attendance history (self-registration is disabled).
   - `management` (Role ID `4`): **Strictly Read-Only (`RO`)**. Must never be granted write/mutation access to events, registrations, attendance, or users.

4. **Single Active Session Enforcement:**
   - On login (`POST /api/v1/auth/login`), previous Sanctum tokens for the user are invalidated, a fresh session UUID is generated (`$sessionId = Str::uuid()->toString()`), saved to `users.active_session_id`, and issued as Sanctum token name `"session-{$sessionId}"`.
   - Protected routes use `['auth:sanctum', 'single.session']` middleware.

5. **Event Lifecycle & Approval Governance:**
   - Valid `events.status` values: `draft`, `pending_approval`, `published`, `ongoing`, `completed`, `cancelled`.
   - Organizers create events in `draft` status and submit them (`pending_approval`). Only an `administrator` can approve publishing (`published`) or approve cancellation (`cancelled`).
   - QR attendance scanning is only allowed when an event is `published` or `ongoing`.

6. **Capacity, Waiting List & Walk-In Rules:**
   - Valid `event_registrations.status` values: `registered`, `waiting_list`, `cancelled`, `walk_in`.
   - `(event_id, student_id)` is unique in `event_registrations`. Re-registering after cancellation or scanning in as a walk-in when on the waiting list must **update** the existing row rather than inserting a duplicate.
   - When a `registered` student cancels before event start, the lowest `waiting_list_position` entry for that event is automatically promoted to `registered` inside a `DB::transaction()`, and remaining waiting list positions are decremented.

7. **Attendance Status, Late Detection & Corrections:**
   - Valid `attendances.status` values: `present`, `absent`, `late`, `excused`, `walk_in`.
   - Check-in after `event_date + start_time + late_grace_period_minutes` is automatically marked `late` (for pre-registered students) or `walk_in` (for unregistered walk-in students when `walk_in_allowed = true`).
   - Manual attendance corrections (`PUT /api/v1/attendance/{id}/correct`) require a mandatory `reason` and must record entries in **both** `attendance_corrections` and `activity_logs`.

8. **Notifications & 30-Day Retention:**
   - Critical notifications (`event_cancellation`, `attendance_recorded`) are mandatory and cannot be disabled in `notification_preferences`.
   - Notification history is retained for 30 days and purged via the `notifications:purge` scheduled task (`created_at < now()->subDays(30)`).

9. **No In-App AI Runtime Features:**
   - Per SRS Section 17 & 33.7, runtime AI features (chatbots, AI report summaries) are out of scope for v1.x. Do not add external LLM SDKs or runtime AI endpoints to `backend/` or `mobile/`.

---

## 3. Backend Conventions (`backend/`)

- **Standard JSON Response Envelope:**
  - Success: `{ "success": true, "message": "...", "data": ... }`
  - Error: `{ "success": false, "error_code": "...", "message": "...", "errors": ... }`
- **Audit Logging:**
  - Record state-changing operations using `ActivityLog::log($action, $module, $recordId, $metadata)`.
- **Testing Safety:**
  - Always keep `DB_CONNECTION=sqlite` and `DB_DATABASE=:memory:` enabled in `backend/phpunit.xml` so `php artisan test` never mutates or wipes the local MySQL/MariaDB database (`school_event_attendance`).
  - Run backend tests from `backend/`:
    ```bash
    php artisan test
    ```

---

## 4. Mobile Conventions (`mobile/`)

- **Flutter Binary Path:** `/home/thea/development/flutter/bin/flutter` (with `CHROME_EXECUTABLE=/usr/bin/brave` for web targets).
- **API Routing:**
  - Centralize all endpoint paths in `mobile/lib/core/constants/api_constants.dart`.
  - Route all HTTP requests through `ApiClient()` (`mobile/lib/core/network/api_client.dart`) so Bearer tokens and 401 session-termination callbacks are consistently handled.
- **Verification Commands:**
  - Run static analysis and widget/unit tests from `mobile/` before completing any Flutter task:
    ```bash
    /home/thea/development/flutter/bin/flutter analyze
    /home/thea/development/flutter/bin/flutter test
    ```

---

## 5. Multi-Agent & Skill Workflow Guidelines

- **Check Relevant Skills First:** Activate relevant workflow skills (`brainstorming`, `writing-plans`, `test-driven-development`, `systematic-debugging`, `dispatching-parallel-agents`, `subagent-driven-development`, `verification-before-completion`) when planning, implementing, debugging, or verifying features.
- **Parallel Subagent Dispatch:** When working on independent subsystems (e.g., backend controllers/tests vs. Flutter screens vs. documentation), dispatch parallel subagents with non-overlapping file ownership to avoid merge conflicts.
- **Evidence Before Completion:** Always run `php artisan test` (for backend changes) and `flutter analyze` + `flutter test` (for mobile changes) and confirm green output before claiming a task is complete.
