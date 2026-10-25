# School SIS Database Ingestion & Administrator Scope Solidification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Solidify the project SRS (`School_Event_Attendance_SRS_v1.0.md`), System Architecture, and repository rules around the institutional mandate: student accounts and records originate strictly from the school's central Student Information System (SIS) database. Administrators manage staff roles, system configuration, system records, activity logs, monitoring, QR oversight, and event approvals, but **cannot create students** and **cannot edit student academic records**. Implement the institutional SIS database sync service and console command (`php artisan students:sync-school-db`) with dry-run and atomic upserting.

**Architecture:**
- **SIS Ingestion Authority:** The school's central SIS database is the sole authority for student enrollment, student ID numbers, full names, courses, year levels, sections, and departments.
- **Administrative Boundary (SRS §2.2.1):** Administrator role is restricted to staff provisioning (`organizer`, `management`, `administrator`), system configuration, audit logs, monitoring, QR oversight, and event approvals. Administrators cannot create students or alter student academic records.
- **Backend Sync Engine:** A dedicated `SisSyncService` and `SyncSchoolDatabaseCommand` (`students:sync-school-db`) to securely ingest student records from the school SIS, upsert `users` and `students`, and generate permanent 64-character hex QR tokens in `student_qrs`.
- **Client Presentation:** The mobile `UserManagementScreen` confirms that administrators can only provision staff users and inspect student records without student creation or editing controls.

**Tech Stack:** Laravel 11, PHP 8.3+, Laravel Sanctum 4.x, SQLite `:memory:`, Flutter 3.x, Dart 3.x, `shadcn_ui`, `flutter_test`.

---

## File Structure & Responsibilities

| Subsystem | Target File | Responsibility |
|---|---|---|
| **Spec** | `School_Event_Attendance_SRS_v1.0.md` | Align Section 2.2.1 (exact administrator scope), Section 5 (User Management: remove student self-registration and student editing; codify SIS ingestion authority; admin cannot create/edit students), Section 16 (System Administration), Section 25 (Business Rules), and Section 26 (Security). |
| **Spec** | `System_Architecture_and_Database_Design.md` | Update multi-tier architecture diagrams, boundary descriptions, and sequence flows to reflect SIS database sync authority. |
| **Spec** | `AGENTS.md`, `context.md`, `REST_API_Specification.md`, `openapi.yaml`, `Project_Plan.md`, `Project_Implementation_Plan.md` | Synchronize workspace documentation with administrator boundaries and SIS synchronization. |
| **Backend** | `backend/tests/Feature/AdminScopeSecurityTest.php` | **[NEW]** Feature tests asserting administrators cannot create students (role_id 3 rejected) and cannot edit student academic records. |
| **Backend** | `backend/app/Http/Controllers/Api/V1/AdminController.php` | Ensure `createUser` strictly forbids student creation (`in:1,2,4` with explicit error code `ERR_CANNOT_CREATE_STUDENTS`). Confirm no student editing endpoint exists. |
| **Backend** | `backend/app/Services/SisSyncService.php` | **[NEW]** Service to parse/ingest institutional SIS student records, upsert user accounts and student profiles, generate 64-character hex permanent QRs, and write audit logs. |
| **Backend** | `backend/app/Console/Commands/SyncSchoolDatabaseCommand.php` | **[NEW]** Artisan console command `students:sync-school-db` supporting `--dry-run`, `--file=`, or direct database connection sync. |
| **Backend** | `backend/tests/Feature/SisSyncCommandTest.php` | **[NEW]** Feature tests verifying SIS student sync, idempotency, QR token generation, and audit logging. |
| **Mobile** | `mobile/test/screens/admin_layout_test.dart` | Assert `UserManagementScreen` displays "Create Staff Account" (only roles 1, 2, 4), labels student accounts as "SIS Synchronized", and provides no student creation or academic editing controls. |
| **Mobile** | `mobile/lib/screens/admin/user_management_screen.dart` | Verify and harden student display cards (status toggle, password reset, inspect QR only; no edit student form). |

---

## Tasks & Steps

### Task 1: Solidify Software Requirements Specification (SRS v1.1) & Architecture Documentation

**Files:**
- Modify: `School_Event_Attendance_SRS_v1.0.md`
- Modify: `System_Architecture_and_Database_Design.md`
- Modify: `AGENTS.md`
- Modify: `context.md`
- Modify: `REST_API_Specification.md`
- Modify: `openapi.yaml`

**Specifications to Solidify:**
1. **SRS Section 2.2.1 Administrator Scope:**
   Update to exact authoritative definition:
   ```markdown
   ### 2.2.1 Administrator

   The Administrator manages:

   -   Roles and permissions
   -   System configuration
   -   System records
   -   Activity logs
   -   Administrative monitoring
   -   QR revocation/reissue oversight
   -   Event approval

   Note: Administrators cannot create student accounts or edit student academic records. Student records are managed exclusively by the school's central Student Information System (SIS).
   ```
2. **SRS Section 5 User Management Requirements:**
   - `USER-001 Account Creation`: Specify that administrators create accounts for non-student staff only (organizers, management, admin). Student accounts are ingested exclusively from the school SIS database.
   - `USER-005 Student Profile`: Maintain institutional fields; remove `Contact number`.
   - `USER-006 Account Immutability`: Student academic records are immutable in this attendance system. Neither students nor administrators can edit student profile fields within this system; corrections must occur in the central SIS.
   - Remove all residual occurrences of "self-registration".
3. **System Architecture & Database Design:**
   - Document SIS Database Ingestion Pipeline and boundary between SIS student records and local event attendance management.
4. **Synchronize Workspace Rules & API Specs:**
   - Update `AGENTS.md` role table, `context.md`, `REST_API_Specification.md`, and `openapi.yaml`.

- [ ] **Step 1: Update `School_Event_Attendance_SRS_v1.0.md`**
  - Revise Section 2.2.1, Section 5 (`USER-001`, `USER-005`, `USER-006`), Section 16 (`ADMIN-001`), Section 25, and Section 26.
- [ ] **Step 2: Update `System_Architecture_and_Database_Design.md`**
  - Clarify the SIS ingestion flow and immutable student records.
- [ ] **Step 3: Update `AGENTS.md` and `context.md`**
  - Record the administrator boundary: manages staff, config, logs, event approvals, QR oversight; cannot create students or edit student records.
- [ ] **Step 4: Update `REST_API_Specification.md` and `openapi.yaml`**
  - Document that `POST /api/v1/admin/users` only accepts `role_id: 1, 2, 4` and rejects student creation with `422/403`.
- [ ] **Step 5: Commit documentation updates**
  - Git commit: `git commit -m "docs: solidify SRS v1.1 and architecture for administrator scope and SIS ingestion"`

---

### Task 2: Backend API Enforcement — Forbid Administrator Student Creation & Editing

**Files:**
- Create: `backend/tests/Feature/AdminScopeSecurityTest.php`
- Modify: `backend/app/Http/Controllers/Api/V1/AdminController.php`

**Interfaces:**
- `POST /api/v1/admin/users`: If payload contains `role_id: 3` (Student), return `422 Unprocessable Entity` with `{ "success": false, "error_code": "ERR_CANNOT_CREATE_STUDENTS", "message": "Administrators cannot create student accounts. Students must be synchronized from the school SIS database." }`.
- Confirm that no endpoint allows administrators to update student academic fields (`first_name`, `last_name`, `course`, `year_level`, `section`, `department`).

- [ ] **Step 1: Write failing feature tests in `backend/tests/Feature/AdminScopeSecurityTest.php`**
  - Test 1: `test_admin_cannot_create_student_account`
    - Login as administrator (`admin@school.edu`).
    - Attempt `POST /api/v1/admin/users` with `role_id: 3` (Student).
    - Assert failure (`422` with `ERR_CANNOT_CREATE_STUDENTS`).
    - Assert no user or student was created in database.
  - Test 2: `test_admin_can_create_organizer_and_management_accounts`
    - Assert `POST /api/v1/admin/users` with `role_id: 2` (Organizer) and `role_id: 4` (Management) succeeds (`201 Created`).
  - Test 3: `test_no_endpoint_allows_editing_student_academic_records`
    - Verify attempting to send student academic updates to `admin/users` or any admin endpoint is rejected or non-existent.
- [ ] **Step 2: Run test to verify it fails**
  - Run: `cd backend && php artisan test --filter=AdminScopeSecurityTest`
  - Expected: FAIL (`ERR_CANNOT_CREATE_STUDENTS` check).
- [ ] **Step 3: Enforce validation and custom error message in `AdminController.php`**
  - In `AdminController::createUser()`:
    - Explicitly check if `role_id === 3`. Return `422` with `ERR_CANNOT_CREATE_STUDENTS`.
    - Ensure validation rules enforce `in:1,2,4`.
- [ ] **Step 4: Run tests to verify they pass**
  - Run: `cd backend && php artisan test --filter=AdminScopeSecurityTest`
  - Run: `cd backend && php artisan test`
  - Expected: All 63+ backend tests pass.
- [ ] **Step 5: Commit changes**
  - Git commit: `git commit -m "feat(backend): restrict admin user creation to staff roles and forbid student creation"`

---

### Task 3: Backend School SIS Database Synchronization Service & Artisan Command

**Files:**
- Create: `backend/app/Services/SisSyncService.php`
- Create: `backend/app/Console/Commands/SyncSchoolDatabaseCommand.php`
- Create: `backend/tests/Feature/SisSyncCommandTest.php`

**Interfaces:**
- `SisSyncService::syncStudents(array $records, bool $dryRun = false): array`:
  - Accepts list of student records from SIS (`student_id_number`, `first_name`, `middle_name`, `last_name`, `email`, `course`, `year_level`, `section`, `department`, `profile_photo_path`).
  - Atomically inside `DB::transaction()`:
    - Upserts `users` with `role_id = 3` (`student`), `status = 'active'`, `email_verified_at = now()`. Default password hashed from Student ID (or SIS default) if newly created.
    - Upserts `students` linked to the user account.
    - Generates 64-character cryptographically random hexadecimal token (`bin2hex(random_bytes(32))`) in `student_qrs` if no active QR exists.
    - Creates default `notification_preferences` for new students.
    - Logs `students_synced_from_sis` in `activity_logs`.
  - Returns statistics: `['total' => X, 'created' => Y, 'updated' => Z, 'qrs_generated' => W]`.
- Console Command: `php artisan students:sync-school-db {--file= : Path to JSON/CSV SIS export} {--dry-run : Simulate sync without committing}`.

- [ ] **Step 1: Write failing tests in `backend/tests/Feature/SisSyncCommandTest.php`**
  - Test 1: `test_sis_sync_command_ingests_new_students_and_generates_qr`
    - Run command with mock SIS data.
    - Assert `users` and `students` created.
    - Assert `student_qrs` has 64-character hex active token.
    - Assert `activity_logs` recorded sync.
  - Test 2: `test_sis_sync_is_idempotent_and_updates_existing_students`
    - Run sync twice with changed section.
    - Assert student section updated, QR token preserved (no duplicate QRs generated).
  - Test 3: `test_dry_run_does_not_mutate_database`
    - Run command with `--dry-run`.
    - Assert database count remains unchanged.
- [ ] **Step 2: Run test to verify it fails**
  - Run: `cd backend && php artisan test --filter=SisSyncCommandTest`
  - Expected: FAIL (Command does not exist).
- [ ] **Step 3: Implement `SisSyncService.php` and `SyncSchoolDatabaseCommand.php`**
  - Create service with transaction handling and QR token generation.
  - Create Artisan command registered in Laravel console kernel.
- [ ] **Step 4: Run test to verify it passes**
  - Run: `cd backend && php artisan test --filter=SisSyncCommandTest`
  - Run: `cd backend && php artisan test`
  - Expected: All 65+ backend tests pass.
- [ ] **Step 5: Commit changes**
  - Git commit: `git commit -m "feat(backend): implement school SIS database sync service and artisan command"`

---

### Task 4: Mobile Client UI Audit & Scope Alignment

**Files:**
- Modify: `mobile/lib/screens/admin/user_management_screen.dart`
- Modify: `mobile/test/screens/admin_layout_test.dart`

**UI Requirements:**
- In `UserManagementScreen`:
  - Verify that the Add User action is labeled "Create Staff Account" and only allows selecting Event Organizer, School Management, or System Administrator.
  - In user list cards, when rendering a student account, display a distinct "SIS Account" badge (`LucideIcons.database`) indicating the record is managed by the institutional SIS.
  - Ensure there is NO "Edit Profile" or "Edit Student" button on student user cards (administrators only have Reset Password, Toggle Status, and Inspect QR).

- [ ] **Step 1: Write/update widget test in `mobile/test/screens/admin_layout_test.dart`**
  - Test: `user management displays SIS Account badge for students and only allows staff account creation`
    - Pump `UserManagementScreen` with student and staff accounts.
    - Assert "Create Staff Account" button opens dialog with only roles 1, 2, 4.
    - Assert student cards display "SIS Account" indicator and lack edit profile controls.
- [ ] **Step 2: Run test to verify it fails/passes**
  - Run: `cd mobile && /home/thea/development/flutter/bin/flutter test test/screens/admin_layout_test.dart`
- [ ] **Step 3: Refactor `UserManagementScreen` in `mobile/lib/screens/admin/user_management_screen.dart`**
  - Add "SIS Synchronized" badge to student user cards.
  - Verify zero student creation/editing options exist.
- [ ] **Step 4: Run test to verify it passes**
  - Run: `cd mobile && /home/thea/development/flutter/bin/flutter test test/screens/admin_layout_test.dart`
  - Run: `cd mobile && /home/thea/development/flutter/bin/flutter analyze`
  - Expected: PASS with 0 analyzer issues.
- [ ] **Step 5: Run full mobile test suite**
  - Run: `cd mobile && /home/thea/development/flutter/bin/flutter test`
  - Expected: All 91+ tests pass.
- [ ] **Step 6: Commit changes**
  - Git commit: `git commit -m "feat(mobile): display SIS synchronized badge on student cards and ensure staff-only provisioning"`

---

### Task 5: End-to-End Verification Gate & Document Solidification

**Files:**
- Modify: `Project_Plan.md`
- Modify: `Project_Implementation_Plan.md`
- Modify: `docs/superpowers/reviews/2026-10-25-sis-and-admin-scope-audit.md` (Audit summary)

**Verification Checks:**
1. Execute full backend test suite: `cd backend && php artisan test` (must pass 100%).
2. Execute full mobile analysis and tests: `cd mobile && flutter analyze && flutter test` (0 issues, 100% pass).
3. Test `php artisan students:sync-school-db --help` and verify dry-run execution.
4. Author audit review in `docs/superpowers/reviews/2026-10-25-sis-and-admin-scope-audit.md`.

- [ ] **Step 1: Execute verification commands**
- [ ] **Step 2: Commit audit notes and final plan updates**
  - Git commit: `git commit -m "docs: finalize SIS database integration and administrator scope audit"`
