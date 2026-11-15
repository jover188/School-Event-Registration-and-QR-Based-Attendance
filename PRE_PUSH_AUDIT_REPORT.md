# Attendify — Complete Pre-Push Audit Report (Bugs, Logic, Security & Stability)

**Date of Audit:** November 15, 2026  
**Auditor Roles:** Senior Flutter Developer, Senior Backend Developer, Application Security Engineer, Database Reviewer, QA Engineer  
**Audit Scope:** Entire repository (`backend/`, `mobile/`, `.github/`, root deployment configuration)  
**Automated Verification:**
- Backend Test Suite: `php artisan test` ➔ **111 passed (572 assertions)**
- Mobile Static Analysis: `flutter analyze` ➔ **0 issues found**
- Mobile Test Suite: `flutter test` ➔ **148 passed (0 failures, 100% pass rate)**

---

## 1. Executive Summary & Overall Project Health

Attendify demonstrates strong architectural principles:
- **Clean Decoupling:** Complete separation between the Flutter frontend and Laravel REST API.
- **RBAC & State Machines:** Strict 4-role RBAC (`administrator`, `organizer`, `student`, `management`), event lifecycle transitions, single active session enforcement via UUID, and permanent 64-char hex QR codes.
- **Modern Design & A11y:** Responsive AetherUI design system with 20+ dedicated mobile screens, dark theme branding, and clean resource disposal across all 30 stateful widgets.
- **FCM HTTP v1 & Real-time Delivery:** Modern OAuth 2.0 RS256-signed JWT integration with in-app real-time fallback and Notification Chime 07.

However, an exhaustive audit across backend security, database schema limits, and client networking uncovered **2 CRITICAL**, **6 HIGH**, **9 MEDIUM**, and **5 LOW** severity findings. 

As of this update, **ALL 8 CONFIRMED BLOCKERS (CRIT-1, CRIT-2, HIGH-1, HIGH-2, HIGH-3, HIGH-4, HIGH-5, HIGH-6)** have been fully resolved, regression tested, and verified:
1. **[CRIT-1 FIXED]** `AuthController::verifyEmail()` now validates cryptographically generated 6-digit OTP tokens against cache hashes using `hash_equals()`, expires in 15 minutes, prevents replay, and rejects invalid/expired tokens.
2. **[CRIT-2 FIXED]** `ApiClient._ensureAndroidHost()` now checks if `baseUrl` targets localhost before probing socket `127.0.0.1:8000`, preserving remote URLs on physical Android devices.
3. **[HIGH-1 FIXED]** `activity_logs.user_agent` widened to `TEXT` via migration and clamped to 1000 characters.
4. **[HIGH-2 FIXED]** Announcement title validation clamped to `max:150` to match `notifications.title` column width.
5. **[HIGH-3 FIXED]** Organizer summary report export strictly scoped to authenticated organizer ID for non-admins.
6. **[HIGH-4 FIXED]** All 4 role dashboards now deregister the FCM device token from backend on logout.
7. **[HIGH-5 FIXED]** `ApiClient` added `onUnauthenticated` callback; `main.dart` routes expired sessions cleanly to `LoginScreen` and displays error toast with modal deduplication guard.
8. **[HIGH-6 FIXED]** Stale widget tests in `student_profile_protection_test.dart` aligned with the read-only institutional layout.

### Recommendation
**READY TO PUSH – All 8 Confirmed Blockers Resolved & Verified.**  
All automated test suites pass without regressions (`php artisan test`: 111 passed; `flutter test`: 148 passed; `flutter analyze`: 0 issues).

---

## 2. Findings Classification & Summary Table

| ID | Subsystem | Severity | Category | Location | Title | Status | Blocks Push? |
| :--- | :--- | :---: | :--- | :--- | :--- | :---: | :---: |
| **CRIT-1** | Backend | 🔴 **CRITICAL** | Security | `AuthController.php:347-380` | Email Verification Authentication Bypass | **RESOLVED** | **NO** |
| **CRIT-2** | Mobile | 🔴 **CRITICAL** | Network | `api_client.dart:53-67` | Base URL Hijacked to `10.0.2.2:8000` on Physical Devices | **RESOLVED** | **NO** |
| **HIGH-1** | Backend | 🟠 **HIGH** | Stability | `activity_logs migration` & `ActivityLog.php:47` | Fatal SQL 500 Crash on Long `User-Agent` Headers (>255 chars) | **RESOLVED** | **NO** |
| **HIGH-2** | Backend | 🟠 **HIGH** | Integrity | `AdminController.php:195` & `notifications migration` | Schema Mismatch: Announcement Title Validation (191) vs DB (150) | **RESOLVED** | **NO** |
| **HIGH-3** | Backend | 🟠 **HIGH** | Security / IDOR | `ReportController.php:613,778` & `OrganizerSummaryExport.php:40` | Organizer Summary Report Export Leaks All Organizers' Data | **RESOLVED** | **NO** |
| **HIGH-4** | Mobile | 🟠 **HIGH** | Security | Dashboards (`student`, `admin`, `organizer`, `management`) | Missing FCM Device Token Deregistration on Logout | **RESOLVED** | **NO** |
| **HIGH-5** | Mobile | 🟠 **HIGH** | Session | `api_client.dart:151-158, 446-449` | Inconsistent 401 Handling Strands User on Expired Session | **RESOLVED** | **NO** |
| **HIGH-6** | Mobile | 🟠 **HIGH** | Testing / CI | `test/screens/student_profile_protection_test.dart` | Stale Widget Tests Expecting Removed Editable Profile UI | **RESOLVED** | **NO** |
| **HIGH-7** | Mobile | 🟠 **HIGH** | Performance | `realtime_notification_service.dart:40` | 4-Second Foreground Polling Drains Battery Alongside FCM | Open | **NO** |
| **MED-1** | Backend | 🟡 **MEDIUM** | Concurrency | `StudentQRController.php:71-95, 139-160` | Missing Row Lock in Student QR Reissue Causes Duplicate Active QRs | Open | **NO** |
| **MED-2** | Backend | 🟡 **MEDIUM** | Security | `AuthController.php:294-297` | Password Change Does Not Invalidate Prior Tokens/Sessions | Open | **NO** |
| **MED-3** | Backend | 🟡 **MEDIUM** | Workflow | `EventController.php:493-518, 523-581` | Disconnected Event Cancellation Request Workflow | Open | **NO** |
| **MED-4** | Backend | 🟡 **MEDIUM** | API Standards | `AttendanceController.php:593` & `RegistrationController.php:446` | Missing Student Profile Returns HTTP 200 with Non-Standard Envelope | Open | **NO** |
| **MED-5** | Backend | 🟡 **MEDIUM** | DoS / Stability | `AdminController`, `EventController`, `AttendanceController`, etc. | Unbounded `per_page` Parameter Causing OOM / DB Strain | Open | **NO** |
| **MED-6** | Backend | 🟡 **MEDIUM** | Logic | `AuthController.php:182-194, 216-219` | Dead Code in Student Profile Photo Upload Handler | Open | **NO** |
| **MED-7** | Mobile | 🟡 **MEDIUM** | UI / Modal | `main.dart:42-69` | Session Terminated Modal Dialog Stacking on Concurrent 401s | **RESOLVED** | **NO** |
| **MED-8** | Mobile | 🟡 **MEDIUM** | Stability | `app_shell.dart:603-605` | `AppDestinationStack` Asserts `index >= 0` on Unmapped Destination | Open | **NO** |
| **MED-9** | Mobile | 🟡 **MEDIUM** | Race Condition | `notifications_screen.dart:120-142` | Async Index Mutation in `_markSingleRead` Modifies Wrong Item | Open | **NO** |
| **LOW-1** | Backend | 🟢 **LOW** | Security | `routes/api.php:40, 65, 68, 124` | Rate Limiting Missing on QR Reissue, Register, Password Change | Open | **NO** |
| **LOW-2** | Backend | 🟢 **LOW** | Consistency | `bootstrap/app.php:22-56` | Generic `HttpException` Rendered Without Standard JSON Envelope | Open | **NO** |
| **LOW-3** | Backend | 🟢 **LOW** | Validation | `EventController.php:281, 347` | Missing URI / Protocol Validation on `cover_image_path` | Open | **NO** |
| **LOW-4** | Mobile | 🟢 **LOW** | Privacy / Logs | `push_notification_service.dart:77, 83` | Raw FCM Device Token Logged to Stdout/Logcat | Open | **NO** |
| **LOW-5** | Git / Config | 🟢 **LOW** | Deployment | `.gitignore` | `google-services.json` and Key Files Not Explicitly in `.gitignore` | Open | **NO** |

---

## 3. Deep-Dive Findings & Technical Evidence

### 🔴 Critical Findings

#### [CRIT-1] Complete Authentication Bypass in Email Verification
- **Subsystem:** Backend API
- **Location:** `backend/app/Http/Controllers/Api/V1/AuthController.php:347-360`
- **Root Cause & Technical Evidence:**
  ```php
  public function verifyEmail(Request $request): JsonResponse
  {
      $validated = $request->validate([
          'email' => ['required', 'email'],
          'code' => ['nullable', 'string'],
          'token' => ['nullable', 'string'],
      ]);

      $code = $validated['code'] ?? $validated['token'] ?? null;
      if (empty($code)) {
          return response()->json([
              'success' => false,
              'error_code' => 'ERR_INVALID_TOKEN',
              'message' => 'Verification token or code is required.',
          ], 422);
      }

      $user = User::where('email', $validated['email'])->first();
      // ...
      $user->update([
          'status' => 'active',
          'email_verified_at' => $user->email_verified_at ?? now(),
      ]);
  ```
  The submitted `$code` is **never compared against any stored token, database column, or cache entry**. An attacker knowing any pending user's email can send `{"email": "admin@school.edu", "code": "anything"}` to activate the account.
- **Status:** ✅ **RESOLVED & VERIFIED**
- **Resolution:**
  - Implemented `AuthController::resendVerification()` generating a 6-digit cryptographic OTP, hashed with SHA-256 and stored in Cache with a 15-minute TTL (`email_verify_{user_id}`).
  - Rewrote `AuthController::verifyEmail()` to compare the submitted token against the cached hash using timing-safe `hash_equals()`.
  - Rejects missing, invalid, or expired tokens with `422 ERR_TOKEN_EXPIRED`.
  - Atomically invalidates the token upon use via `Cache::forget()`, preventing token replay.
  - Added unit and feature tests covering valid verification, invalid tokens, expired tokens, and token replay prevention (`AuthAndStaffOperationsTest.php`). All passed.

---

#### [CRIT-2] Base URL Overridden to `10.0.2.2:8000` on Physical Android Devices
- **Subsystem:** Mobile Network Client
- **Location:** `mobile/lib/core/network/api_client.dart:53-67`
- **Root Cause & Technical Evidence:**
  ```dart
  Future<void> _ensureAndroidHost() async {
    if (kIsWeb || !Platform.isAndroid || ApiConstants.customBaseUrl != null) return;
    try {
      final socket = await Socket.connect('127.0.0.1', 8000, timeout: const Duration(milliseconds: 200));
      socket.destroy();
    } catch (_) {
      ApiConstants.customBaseUrl = 'http://10.0.2.2:8000/api/v1';
    }
  }
  ```
  On a physical Android phone or when connecting to Render (`https://attendify-fugh.onrender.com/api/v1`), `127.0.0.1:8000` is unreachable. The `catch` block unconditionally assigns `ApiConstants.customBaseUrl = 'http://10.0.2.2:8000/api/v1'`. Because `ApiConstants.baseUrl` checks `customBaseUrl` first, **all requests on physical Android phones are redirected to the emulator IP and fail with connection refused.**
- **Status:** ✅ **RESOLVED & VERIFIED**
- **Resolution:**
  - Updated `_ensureAndroidHost()` in `api_client.dart` to verify whether `ApiConstants.baseUrl` points to `127.0.0.1` or `localhost`.
  - If connecting to remote/production hosts (e.g. Render, staging domain, or custom LAN IP), the socket probe is bypassed entirely, guaranteeing the remote URL is never overwritten.
  - Added unit tests in `mobile/test/core/api_client_test.dart` verifying remote URL preservation. All passed.

---

### 🟠 High-Severity Findings

#### [HIGH-1] Fatal Database 500 Crash on Modern `User-Agent` Headers
- **Location:** `backend/database/migrations/2026_10_08_081000_create_activity_logs_table.php:22` & `backend/app/Models/ActivityLog.php:47`
- **Impact:** Migration sets `VARCHAR(255)` for `user_agent`. Modern Android WebView, Chrome Mobile, and Samsung Browser User-Agents routinely exceed 260–380 characters. In MySQL strict mode, any logged action (login, QR scan, registration) throws `SQLSTATE[22001]: String data, right truncated`, producing an unhandled 500 server crash.
- **Status:** ✅ **RESOLVED & VERIFIED**
- **Resolution:** Created migration `2026_11_15_000001_widen_user_agent_in_activity_logs_table.php` changing `user_agent` to `TEXT`. Added defensive truncation in `ActivityLog::log()` to 1000 characters. Verified via `AuthAndStaffOperationsTest::test_activity_log_handles_long_user_agent_without_error`.

#### [HIGH-2] Schema Mismatch: Announcement Title Validation (191) vs Database (150)
- **Location:** `backend/app/Http/Controllers/Api/V1/AdminController.php:195` vs `backend/database/migrations/2026_10_08_080700_create_notifications_table.php:17`
- **Impact:** `AdminController::sendAnnouncement` validates `'title' => ['required', 'string', 'max:191']`, but `notifications.title` is `VARCHAR(150)`. Titles between 151 and 191 characters pass validation but crash Eloquent with SQL truncation error, failing announcement delivery.
- **Status:** ✅ **RESOLVED & VERIFIED**
- **Resolution:** Clamped validation rule in `AdminController::sendAnnouncement` to `'title' => ['required', 'string', 'max:150']`. Added boundary test in `NotificationServiceTest::test_announcement_title_validation_length_boundary`.

#### [HIGH-3] Horizontal Authorization Leakage (IDOR) in Report Exports
- **Location:** `backend/app/Http/Controllers/Api/V1/ReportController.php:613, 778` & `backend/app/Exports/OrganizerSummaryExport.php:40`
- **Impact:** The JSON endpoint `ReportController::organizerSummary()` scopes organizers to `where('id', $user->id)` if the requester is an organizer. However, the CSV, PDF, and Excel export routines query `User::where('role_id', 2)->get()`. Any organizer can download reports containing all other organizers' full names, emails, total events, total attendees, and turnout metrics.
- **Status:** ✅ **RESOLVED & VERIFIED**
- **Resolution:** In `ReportController::export()`, enforced `$validated['organizer_id'] = $user->id;` for non-admin/non-management organizers. Scoped `OrganizerSummaryExport::query()` to filter by `$this->organizerId`. Verified via `ReportExportTest::test_organizer_summary_export_scopes_to_own_organizer_data_for_organizer_role`.

#### [HIGH-4] Missing FCM Device Token Deregistration on Logout
- **Location:** `mobile/lib/screens/*/*_dashboard_screen.dart` (`student`, `admin`, `organizer`, `management`)
- **Impact:** `RealtimeNotificationService` has `deregisterDeviceToken(fcmToken)`, but none of the dashboard `_logout()` methods invoke it. On shared tablets or personal phones handed to another student, the device token remains bound to the previous user in `device_tokens`, leaking attendance and event notifications across accounts.
- **Status:** ✅ **RESOLVED & VERIFIED**
- **Resolution:** Updated `_logout()` across all 4 dashboards (`student_dashboard_screen.dart`, `admin_dashboard_screen.dart`, `organizer_dashboard_screen.dart`, `management_dashboard_screen.dart`) to retrieve `PushNotificationService().fcmToken` and call `deregisterDeviceToken(fcmToken)` before clearing the session. Verified with dedicated widget tests in `logout_fcm_deregistration_test.dart` (6/6 passed).

#### [HIGH-5] Inconsistent 401 Handling Strands User on Expired Session
- **Location:** `mobile/lib/core/network/api_client.dart:151-158`
- **Impact:** In `_handleResponse`, when a 401 is received, `onSessionTerminated` is only called if `error_code == 'ERR_SESSION_TERMINATED'`. If the session expired (`ERR_UNAUTHENTICATED`), the token is cleared, but the user is never redirected to `LoginScreen`. They remain stuck on an unresponsive screen receiving errors on every action.
- **Status:** ✅ **RESOLVED & VERIFIED**
- **Resolution:** Added `onUnauthenticated` callback in `ApiClient` for general 401s. Wired in `main.dart` to navigate back to `LoginScreen` and display a clear toast notification. Added `_isSessionDialogActive` lock preventing modal stacking (also resolving `MED-7`). Verified with unit/widget tests in `api_client_test.dart`.

#### [HIGH-6] Stale Widget Tests in `student_profile_protection_test.dart` Failing Full Suite CI
- **Location:** `mobile/test/screens/student_profile_protection_test.dart` vs. `mobile/lib/screens/common/profile_screen.dart`
- **Impact:** In commit `908ed86`, `ProfileScreen` was intentionally converted to a strictly read-only institutional profile display without contact mutation or correction request dialogs. However, `student_profile_protection_test.dart` was left expecting the previous UI (`profile-contact` key, `request-correction-button`, "Update Contact Number"). Running `flutter test` across the full test suite produces 4 test failures (129 passed, 4 failed), which will cause any GitHub Actions CI workflow to fail and block deployment.
- **Status:** ✅ **RESOLVED & VERIFIED**
- **Resolution:** Re-aligned all 4 test cases in `student_profile_protection_test.dart` to assert the read-only institutional display (`Institutional Academic Identity`, `Institutional Record` badges, absence of mutation controls). All 148 tests in the full suite now pass cleanly.

#### [HIGH-7] Aggressive 4-Second Polling Battery Drain
- **Location:** `mobile/lib/core/services/realtime_notification_service.dart:40`
- **Impact:** Polling `GET /notifications?after_id=...` every 4 seconds in the foreground keeps mobile cellular/Wi-Fi chips in continuous high-power mode.
- **Recommended Fix:** Relax the default foreground polling interval to 30–45 seconds now that FCM foreground push (`FirebaseMessaging.onMessage`) triggers instant on-demand synchronization.

---

### 🟡 Medium-Severity Findings

- **[MED-1] Concurrency Race Condition in QR Reissue:** `StudentQRController::reissue` revokes active tokens and inserts a new one inside a transaction without acquiring an exclusive row lock (`lockForUpdate`). Rapid concurrent taps can result in multiple active QR codes.
- **[MED-2] Password Change Invalidation:** `AuthController::changePassword` updates the password hash without revoking other existing Sanctum tokens or rotating `active_session_id`.
- **[MED-3] Disconnected Cancellation Workflow:** Cancellation requests are logged as unstructured JSON in `activity_logs` rather than inserting a pending `EventApproval`. Admins have no dashboard visibility into pending cancellations.
- **[MED-4] Non-Standard Error Envelope on Missing Student:** `AttendanceController::studentHistory` and `RegistrationController::studentRegistrations` return HTTP 200 with `success: false` and omit `error_code`.
- **[MED-5] Unbounded `per_page` Parameter:** Multiple controllers lack `max(1, min(100, ...))` clamping, allowing clients to pass `?per_page=1000000` (DoS risk).
- **[MED-6] Dead Code in Profile Photo Upload:** Students are rejected at line 182 in `AuthController::updateProfile`, leaving lines 207-222 unreachable.
- **[MED-7] Session Modal Dialog Stacking:** Multiple concurrent 401 requests trigger `showDialog` multiple times without a deduplication lock.
- **[MED-8] `AppDestinationStack` Unmapped Assertion:** `ids.indexOf(widget.selectedId)` returns `-1` if unmapped, asserting `index >= 0` in debug mode.
- **[MED-9] Async Race Condition in `_markSingleRead`:** Mutating `_notifications[index]` by array index after an `await` can mutate the wrong item if a new notification arrived and shifted the array.

---

### 🟢 Low-Severity Findings

- **[LOW-1] Missing Rate Limiting on Mutation Endpoints:** `routes/api.php` missing rate limiting on `/student/qr/reissue`, `/events/{id}/register`, `/profile/change-password`.
- **[LOW-2] Generic `HttpException` JSON Envelope:** `abort(422, ...)` in controllers outputs Laravel default `{message: ...}` without standard `error_code`.
- **[LOW-3] Missing URL Validation on `cover_image_path`:** `cover_image_path` validated only as string without scheme validation.
- **[LOW-4] Sensitive FCM Token Logged:** `debugPrint` logs raw device tokens to logcat.
- **[LOW-5] `.gitignore` Coverage:** `mobile/android/app/google-services.json` and keystores should be added to `.gitignore`.

---

## 4. Subsystem Assessments

### Security Assessment
- **Authentication & RBAC:** Excellent role gating via `CheckRole` middleware and `active_session_id` single session enforcement.
- **Vulnerabilities Identified:**
  - Critical authentication bypass in email verification (`CRIT-1`).
  - Horizontal privilege leakage / IDOR in report exports (`HIGH-3`).
  - Token persistence across logout on shared hardware (`HIGH-4`).
- **Data Protection:** No credentials or private keys committed. Passwords hashed with bcrypt (rounds: 12). Raw SQL injection vulnerability: None identified.

### Database Assessment
- **Schema & Relationships:** Proper foreign keys, cascade constraints, and indices on `user_id` and `student_id`.
- **Identified Flaws:**
  - Column length mismatch on `user_agent` (`VARCHAR(255)` causes 500 errors on long client headers).
  - Column length mismatch on `notifications.title` (`VARCHAR(150)` vs `191` in validation).
  - Missing pessimistic locking during student QR reissuance.

### Flutter Mobile Assessment
- **State & Memory Management:** Exceptional controller and animation disposal. Clean separation of concerns.
- **Identified Flaws:**
  - Automated socket probe breaks physical Android devices and remote cloud API (`CRIT-2`).
  - Session termination dialog stacking and unauthenticated session drop (`HIGH-5`, `MED-7`).
  - Index shifting on real-time stream prepend during asynchronous item marking (`MED-9`).

---

## 5. Prioritized Remediation Action Plan

Before executing `git push origin main`, the following fixes should be implemented in order:

### Priority 1: Critical & High Blocking Fixes (Must Fix Before Push)
1. **Fix [CRIT-2] in `api_client.dart`**: Prevent `_ensureAndroidHost` from redirecting physical devices to `10.0.2.2:8000`.
2. **Fix [CRIT-1] in `AuthController.php`**: Enforce verification token matching in `verifyEmail()`.
3. **Fix [HIGH-1] in `ActivityLog.php` & New Migration**: Alter `activity_logs.user_agent` to `TEXT` and truncate safely.
4. **Fix [HIGH-2] in `AdminController.php`**: Clamp announcement title validation to `max:150`.
5. **Fix [HIGH-3] in `ReportController.php`**: Scope `organizer_summary` export to `$user->id` for organizers.
6. **Fix [HIGH-4] in Dashboards**: Call `deregisterDeviceToken()` in `_logout()`.
7. **Fix [HIGH-5] in `api_client.dart` & `main.dart`**: Route general 401 unauthenticated errors to `LoginScreen`.
8. **Fix [HIGH-6] in `student_profile_protection_test.dart`**: Synchronize widget tests with read-only `ProfileScreen`.

### Priority 2: Quality & Stability Improvements (Recommended)
9. **Fix [HIGH-7] in `realtime_notification_service.dart`**: Relax polling interval from 4s to 30s.
10. **Fix [MED-7] in `main.dart`**: Add dialog guard boolean to prevent stacking session termination dialogs.
11. **Fix [MED-8] in `app_shell.dart`**: Guard `IndexedStack` against `-1` index assertions.
12. **Fix [MED-9] in `notifications_screen.dart`**: Locate notification by ID rather than index after `await`.
13. **Fix [LOW-5] in `.gitignore`**: Add `mobile/android/app/google-services.json` and `*.keystore` / `*.jks`.

---

## 6. Final Recommendation

```
================================================================================
FINAL VERDICT: READY TO PUSH – ALL 8 BLOCKERS RESOLVED AND VERIFIED
================================================================================
All critical and high-priority blocking issues (CRIT-1, CRIT-2, HIGH-1, HIGH-2,
HIGH-3, HIGH-4, HIGH-5, HIGH-6) have been resolved and verified with automated
test suites:
  • Backend: 111 passed (572 assertions, 0 failures)
  • Mobile Analysis: No issues found!
  • Mobile Tests: 148 passed (0 failures, 100% pass rate)

The repository is healthy, secure, and ready for production deployment.
================================================================================
```
