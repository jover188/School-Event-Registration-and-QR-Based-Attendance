# Student Profile Read-Only & Credential Security Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enforce institutional immutability for student profiles (preventing students from modifying their own academic records or profile details), remove the contact number field, remove password change fields from the client UI, block unauthorized API endpoints for students, and conduct security vulnerability verification across both backend and mobile layers.

**Architecture:**
- **Backend (Laravel 11 REST API):** Restrict `PUT|POST /api/v1/profile` and `POST /api/v1/profile/change-password` so that student role requests are rejected server-side with `403 Forbidden` and logged in `activity_logs`. Remove `contact_number` validation and mutation from profile updating.
- **Mobile Client (Flutter 3.x / AetherUI):** Refactor `ProfileScreen` into a clean, read-only institutional identity summary for students. Remove all editable text inputs for student academic data, remove the contact number input, remove the password change form and controllers, and eliminate the "Save Profile Changes" button for students.
- **Security & Integrity:** Audit against OWASP API1:2023 (Broken Object Level Authorization), API3:2023 (Broken Object Property Level Authorization / Mass Assignment), and credential tampering.

**Tech Stack:** Laravel 11, PHP 8.3+, Laravel Sanctum 4.x, SQLite `:memory:` (testing), Flutter 3.x, Dart 3.x, `shadcn_ui`, `flutter_test`.

---

## File Structure & Responsibilities

| Subsystem | Target File | Responsibility |
|---|---|---|
| **Backend** | `backend/tests/Feature/StudentProfileSecurityTest.php` | **[NEW]** Feature tests asserting server-side authorization: 403 on student profile edits, 403 on student password changes, contact number immutability, and security audit logging. |
| **Backend** | `backend/app/Http/Controllers/Api/V1/AuthController.php` | Enforce server-side authorization checks in `updateProfile()` and `changePassword()`: reject student modifications with `403 Forbidden` (`ERR_STUDENT_PROFILE_IMMUTABLE` / `ERR_STUDENT_PASSWORD_CHANGE_DISABLED`). Remove `contact_number` mutation logic. |
| **Backend** | `backend/tests/Feature/SchoolAttendanceWorkflowTest.php` | Update existing workflow tests to reflect student profile immutability and staff-only password changes. |
| **Mobile** | `mobile/test/screens/account_layout_test.dart` | Update layout tests to assert absence of contact number, absence of password change inputs, absence of student edit forms, and presence of read-only institutional info cards. |
| **Mobile** | `mobile/lib/screens/common/profile_screen.dart` | Remove `_contactController`, contact number field, password change section and controllers. Replace editable student fields and "Save Profile Changes" button with read-only institutional profile badges/cards. |
| **Docs** | `context.md`, `REST_API_Specification.md`, `openapi.yaml`, `Project_Plan.md`, `Project_Implementation_Plan.md` | Keep documentation synchronized with student profile immutability, removal of contact number, and password restrictions. |

---

## Tasks & Steps

### Task 1: Backend Server-Side Authorization & Immutability for Student Profiles and Credentials

**Files:**
- Create: `backend/tests/Feature/StudentProfileSecurityTest.php`
- Modify: `backend/app/Http/Controllers/Api/V1/AuthController.php`
- Modify: `backend/tests/Feature/SchoolAttendanceWorkflowTest.php`

**Interfaces:**
- `PUT|POST /api/v1/profile`: If authenticated user has role `student`, return `403 Forbidden` with `{ "success": false, "error_code": "ERR_STUDENT_PROFILE_IMMUTABLE", "message": "Students are not permitted to modify institutional profile information. Profile changes must be requested through the school registrar or administrator." }` and write an `unauthorized_profile_update_attempt` entry to `activity_logs`. Remove `contact_number` from validation and updates.
- `POST /api/v1/profile/change-password`: If authenticated user has role `student`, return `403 Forbidden` with `{ "success": false, "error_code": "ERR_STUDENT_PASSWORD_CHANGE_DISABLED", "message": "Student password changes are managed by institutional administration or SIS synchronization. Contact your administrator to reset credentials." }` and write an `unauthorized_password_change_attempt` entry to `activity_logs`. Staff accounts (`organizer`, `administrator`) retain password change capability.

- [ ] **Step 1: Write failing feature tests in `backend/tests/Feature/StudentProfileSecurityTest.php`**
  - Test 1: `test_student_cannot_update_profile_information_via_put_or_post`
    - Login as student (`20260001`).
    - Attempt `PUT /api/v1/profile` with `{"first_name": "Tampered", "section": "CS-99", "contact_number": "09999999999"}`.
    - Assert `403 Forbidden` with `ERR_STUDENT_PROFILE_IMMUTABLE`.
    - Assert student database record remains unmodified (`first_name` != 'Tampered').
    - Attempt `POST /api/v1/profile` with multipart/form-data $\rightarrow$ assert `403 Forbidden`.
    - Assert `activity_logs` contains action `'unauthorized_profile_update_attempt'`.
  - Test 2: `test_student_cannot_change_password_via_api`
    - Login as student (`20260001`).
    - Attempt `POST /api/v1/profile/change-password` with `{"current_password": "Student@12345", "new_password": "NewSecret@12345", "new_password_confirmation": "NewSecret@12345"}`.
    - Assert `403 Forbidden` with `ERR_STUDENT_PASSWORD_CHANGE_DISABLED`.
    - Assert student can still authenticate with old password.
    - Assert `activity_logs` contains action `'unauthorized_password_change_attempt'`.
  - Test 3: `test_staff_can_still_change_password`
    - Login as organizer (`organizer@school.edu`).
    - Attempt `POST /api/v1/profile/change-password`.
    - Assert `200 OK`.
- [ ] **Step 2: Run test to verify it fails**
  - Run: `cd backend && php artisan test --filter=StudentProfileSecurityTest`
  - Expected: FAIL (`403` expected but received `200`).
- [ ] **Step 3: Implement authorization checks and remove `contact_number` mutation in `AuthController.php`**
  - In `AuthController::updateProfile()`:
    - Check if `$user->isStudent()` or `$user->role?->slug === 'student'`.
    - If student, log security event to `ActivityLog` and return `403 Forbidden`.
    - Remove `'contact_number'` from `$validated` rules and assignment array.
  - In `AuthController::changePassword()`:
    - Check if `$user->isStudent()` or `$user->role?->slug === 'student'`.
    - If student, log security event to `ActivityLog` and return `403 Forbidden`.
- [ ] **Step 4: Update `SchoolAttendanceWorkflowTest.php`**
  - Update `test_profile_update_and_password_change_compatibility` to assert student rejection or split into staff password test and student immutability test.
- [ ] **Step 5: Run tests to verify they pass**
  - Run: `cd backend && php artisan test --filter=StudentProfileSecurityTest`
  - Run: `cd backend && php artisan test`
  - Expected: All 60 backend tests pass (0 failures).
- [ ] **Step 6: Commit backend changes**
  - Git commit: `git commit -m "feat(backend): enforce student profile immutability and restrict password changes"`

---

### Task 2: Mobile UI — Remove Contact Number, Remove Password Fields, and Render Read-Only Student Profile

**Files:**
- Modify: `mobile/lib/screens/common/profile_screen.dart`
- Modify: `mobile/test/screens/account_layout_test.dart`

**UI Requirements:**
- **Remove Contact Number:** Completely remove `_contactController`, the "Contact Number" `AccountInput` widget, and references in form submissions.
- **Remove Password Fields:** Completely remove `_currentPasswordController`, `_newPasswordController`, `_confirmPasswordController`, `_changePassword()` method, and the entire "Change Password" section in `ProfileScreen`.
- **Read-Only Institutional Student Profile:**
  - For students (`_hasStudentProfile == true`), display their academic information in an institutional identity card:
    - Student ID Number (monochrome badge)
    - Full Name (with "Institutional Record" verification indicator)
    - Course / Program
    - Year Level
    - Section
    - Department / College
  - Display informative notice banner: *"Institutional records are synchronized with the School Student Information System (SIS) and are read-only. For official record corrections, contact the registrar's office."*
  - Completely remove the editable form inputs and the `save-profile-button` for students.
- **Staff Profiles:**
  - For staff accounts (`administrator`, `organizer`, `management`), display their account email, role name, and status without broken or redundant student form fields.

- [ ] **Step 1: Write failing widget and layout tests in `mobile/test/screens/account_layout_test.dart`**
  - Test: `student profile displays read-only institutional info without contact number, edit inputs, or password change fields`
    - Pump `ProfileScreen` with student initial data (`student_profile`).
    - Assert `find.byKey(const ValueKey('profile-contact'))` finds nothing (`findsNothing`).
    - Assert `find.byKey(const ValueKey('change-current-password'))` finds nothing (`findsNothing`).
    - Assert `find.byKey(const ValueKey('change-new-password'))` finds nothing (`findsNothing`).
    - Assert `find.byKey(const ValueKey('change-confirm-password'))` finds nothing (`findsNothing`).
    - Assert `find.byKey(const ValueKey('update-password-button'))` finds nothing (`findsNothing`).
    - Assert `find.byKey(const ValueKey('save-profile-button'))` finds nothing (`findsNothing`).
    - Assert institutional read-only notice text is present (`find.textContaining('synchronized with the School Student Information System')`).
    - Assert Student ID Number, Name, Course, Year Level, Section, and Department are visible as read-only text.
- [ ] **Step 2: Run test to verify it fails**
  - Run: `cd mobile && /home/thea/development/flutter/bin/flutter test test/screens/account_layout_test.dart`
  - Expected: FAIL (`save-profile-button` or password fields found).
- [ ] **Step 3: Refactor `ProfileScreen` in `mobile/lib/screens/common/profile_screen.dart`**
  - Delete `_contactController` and its initialization/disposal.
  - Delete password controllers (`_currentPasswordController`, `_newPasswordController`, `_confirmPasswordController`) and `_changePassword()`.
  - Remove the password change section.
  - Replace the student editable form and submit button with a polished read-only institutional identity details card.
  - Ensure clean styling following AetherUI tokens and zero layout overflows.
- [ ] **Step 4: Run test to verify it passes**
  - Run: `cd mobile && /home/thea/development/flutter/bin/flutter test test/screens/account_layout_test.dart`
  - Run: `cd mobile && /home/thea/development/flutter/bin/flutter analyze`
  - Expected: PASS with 0 analyzer issues.
- [ ] **Step 5: Run full mobile test suite**
  - Run: `cd mobile && /home/thea/development/flutter/bin/flutter test`
  - Expected: All 90+ tests pass.
- [ ] **Step 6: Commit mobile changes**
  - Git commit: `git commit -m "feat(mobile): convert student profile to read-only, remove contact number and password change fields"`

---

### Task 3: Vulnerability & Security Assessment Verification Gate

**Files:**
- Modify: `docs/superpowers/reviews/2026-10-25-student-profile-security-audit.md` (Security Audit Report)
- Modify: `context.md`, `REST_API_Specification.md`, `openapi.yaml`, `Project_Plan.md`, `Project_Implementation_Plan.md`

**Vulnerability Checks:**
1. **Broken Object Property Level Authorization (BOPLA / Mass Assignment):**
   Verify that arbitrary POST/PUT requests cannot inject or update fields (`first_name`, `last_name`, `contact_number`, `student_id_number`) into student records.
2. **Broken Function Level Authorization (BFLA):**
   Verify that role authorization middleware (`role:administrator,organizer`) or controller guard blocks student attempts to access unauthorized administrative or staff mutation actions.
3. **Credential Manipulation:**
   Verify that student passwords cannot be tampered with through any client API route; student credentials are only resettable by institutional administrators (`POST /api/v1/admin/users/{id}/reset-password`).
4. **Information Disclosure & Privacy:**
   Ensure contact number is no longer collected or exposed via profile mutation endpoints.
5. **Client-Side Surface Hardening:**
   Inspect `ProfileScreen` accessibility tree and widget keys to ensure no hidden or disabled form fields leak student data or accept input.

- [ ] **Step 1: Execute security regression tests on backend**
  - Run: `cd backend && php artisan test`
  - Verify all feature tests pass including `StudentProfileSecurityTest` and `AuthorizationPolicyTest`.
- [ ] **Step 2: Execute mobile static analysis and test suite**
  - Run: `cd mobile && /home/thea/development/flutter/bin/flutter analyze`
  - Run: `cd mobile && /home/thea/development/flutter/bin/flutter test`
  - Verify 0 analysis issues and 100% test pass rate.
- [ ] **Step 3: Update specifications & documentation**
  - Update `context.md`, `REST_API_Specification.md`, `openapi.yaml`, and project plans to document:
    - Student profile immutability (read-only institutional record).
    - Removal of contact number field.
    - Omission of student-facing password change in favor of administrator reset.
- [ ] **Step 4: Commit documentation and verification evidence**
  - Git commit: `git commit -m "docs: update specifications and audit notes for student profile immutability and credential security"`
