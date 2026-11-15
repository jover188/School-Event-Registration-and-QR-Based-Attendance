# Attendify – Fix FCM Device Registration and Backend Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve the blockers preventing real Android push notifications when Attendify is backgrounded or closed by fixing client-side FCM device token registration upon authentication and enabling backend Firebase Admin Service Account credentials on Render.

**Architecture:** 
1. Mobile: Defer FCM device token registration until the user is authenticated (post-login or valid session cold-start), handle token refreshes dynamically, deduplicate registrations, and clean up on logout.
2. Backend: Add support for direct JSON service account configuration (`FIREBASE_CREDENTIALS_JSON`) in `NotificationService.php` and `services.php`, verify HTTP v1 JWT signing and error logging, and test `DeviceToken` storage and admin broadcast targeting.

**Tech Stack:**
- Mobile: Flutter (Dart 3.x), `firebase_messaging`, `firebase_core`, `ApiClient`.
- Backend: Laravel 11.x, PHP 8.2+, MySQL / SQLite `:memory:` for testing, OpenSSL, Firebase Cloud Messaging HTTP v1 API.

**Spec:** Section 8 & 33.7 of `School_Event_Attendance_SRS_v1.0.md` & `REST_API_Specification.md`.

## Global Constraints
- Decoupled client-server architecture: mobile app communicates solely via `/api/v1/*`.
- Single active session enforcement: tokens tied to authenticated session.
- Never commit Firebase private keys or service account credentials to GitHub.
- Never expose Firebase Admin credentials in Flutter.
- Keep `DB_CONNECTION=sqlite` and `DB_DATABASE=:memory:` enabled in `backend/phpunit.xml`.
- Do not push or deploy without explicit user approval.

## Review Focus
1. Cold start with no prior session: Does NOT call `POST /api/v1/notifications/device-token` before login (no 401 spam).
2. Login flow: Calls `syncDeviceToken()` immediately after successful login so `device_tokens` stores the phone's FCM token.
3. Token refresh: If FCM rotates the token while authenticated, it updates `device_tokens` on the backend.
4. Account switching / logout: Deregisters old token on logout and properly registers the new user ID on subsequent login.
5. Backend service account resolution: Safely parses `FIREBASE_CREDENTIALS_JSON`, `FIREBASE_CREDENTIALS` (file), or discrete env vars (`FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`) without failing if unconfigured.

---

### Task 1: Flutter Client-Side FCM Token Registration & Lifecycle Management

**Files:**
- Modify: `mobile/lib/core/services/push_notification_service.dart`
- Modify: `mobile/lib/screens/auth/login_screen.dart`
- Modify: `mobile/lib/main.dart`
- Test: `mobile/test/core/services/push_notification_service_test.dart`

**Implementation Steps:**
- [ ] In `push_notification_service.dart`:
  - Add `String? _lastRegisteredToken` and `int? _lastRegisteredUserId` state tracking to deduplicate calls.
  - In `initialize()`: Cache `_fcmToken = token`, set up background handler and permissions, but ONLY invoke backend registration if `ApiClient().token` is already present.
  - Implement `Future<bool> syncDeviceToken({bool force = false})`:
    - Check if `_fcmToken` is valid and `ApiClient().token` is present.
    - If already registered with the current user ID and token hasn't changed (and `!force`), return early to avoid redundant network traffic.
    - Call `RealtimeNotificationService().registerDeviceToken(_fcmToken!)`.
    - If successful, record `_lastRegisteredToken` and current user ID.
  - In `onTokenRefresh` listener: Update `_fcmToken` and trigger `syncDeviceToken()`.
  - Add `void resetRegistrationState()` so logout or account switching resets `_lastRegisteredToken` and `_lastRegisteredUserId`.
- [ ] In `login_screen.dart`:
  - Call `await PushNotificationService().syncDeviceToken(force: true)` immediately following successful authentication and `RealtimeNotificationService().initialize()`.
- [ ] In `main.dart`:
  - In `_resolveInitialScreen()`, if existing token and role are restored, call `RealtimeNotificationService().initialize()` and `PushNotificationService().syncDeviceToken()`.
- [ ] Write unit tests in `mobile/test/core/services/push_notification_service_test.dart` to verify:
  - Token is cached without registering before login.
  - Registration runs when authenticated.
  - Duplicate registration calls are skipped.
  - Token refresh triggers re-registration when authenticated.

---

### Task 2: Backend Firebase Admin SDK / HTTP v1 Configuration & Diagnostics

**Files:**
- Modify: `backend/config/services.php`
- Modify: `backend/app/Services/NotificationService.php`
- Test: `backend/tests/Feature/NotificationTest.php`

**Implementation Steps:**
- [ ] In `backend/config/services.php`:
  - Add `'credentials_json' => env('FIREBASE_CREDENTIALS_JSON')` under `'firebase'`.
- [ ] In `backend/app/Services/NotificationService.php`:
  - In `getFirebaseCredentials()`:
    - Check `config('services.firebase.credentials_json') ?: env('FIREBASE_CREDENTIALS_JSON')`.
    - Parse raw JSON string if present, validate `project_id`, `client_email`, and `private_key` (normalizing `\n` linebreaks).
    - Maintain existing file-path (`FIREBASE_CREDENTIALS`) and discrete env var fallback.
  - In `dispatchFcmV1()`:
    - Enhance diagnostic logging: Log exact failure status and error details from Google OAuth or FCM HTTP v1 so admins know whether credentials, token, or project ID are misconfigured.
- [ ] Run backend tests:
  - `php artisan test --filter=NotificationTest`
  - Ensure all existing tests pass and add test cases for `FIREBASE_CREDENTIALS_JSON` parsing and device token storage.

---

### Task 3: Verification & Integration Testing

**Steps:**
- [ ] Run `mobile`: `flutter test test/core/services/push_notification_service_test.dart` and `flutter analyze`.
- [ ] Run `backend`: `php artisan test`.
- [ ] Test device token registration API contract against backend controller using SQLite in-memory test.
- [ ] Confirm no private keys or secrets are staged or created in the working tree.
- [ ] Compile comprehensive report outlining root causes, files modified, Render env vars instructions, and manual test requirements.
