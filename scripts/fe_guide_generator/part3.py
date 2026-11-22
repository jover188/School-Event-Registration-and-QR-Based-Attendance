"""
part3.py - Chapters 9 to 13 for Attendify Frontend Developer Guide.
Covers:
- Chapter 9: State Management Architecture (State Patterns, Notifiers, Controllers)
- Chapter 10: REST API Integration (ApiClient, Interceptors, Endpoint Inventory)
- Chapter 11: Authentication and Role-Based Access Control (RBAC, Single-Session)
- Chapter 12: Event Management Frontend (Creation, Targeting, Capacity, Queue)
- Chapter 13: Calendar and QR-Based Attendance Scanning (Hardware, Decoding, Grace Period)
"""

from .styles import (
    add_chapter_title, add_section_title, add_subsection_title,
    add_body_p, add_bullet_item, add_callout, add_styled_table, add_code_block
)

def add_part3(doc):
    # -------------------------------------------------------------
    # CHAPTER 9: STATE MANAGEMENT
    # -------------------------------------------------------------
    add_chapter_title(doc, "9", "State Management & Reactive Architecture")

    add_section_title(doc, "9.1", "State Management Approach")
    add_body_p(doc, "Attendify deliberately avoids bloated third-party state frameworks (such as Bloc or MobX) that introduce excessive boilerplate and complex ceremony. Instead, the application leverages Flutter's built-in foundational primitives (`ChangeNotifier`, `ValueNotifier`, and `StreamController`) organized into singleton controllers, paired with local `StatefulWidget` component lifecycles.", bold_prefix="Pragmatic State Philosophy: ")

    add_section_title(doc, "9.2", "Global State Coordinators")
    add_bullet_item(doc, "Singleton `ChangeNotifier` managing `ThemeMode.light`, `ThemeMode.dark`, and `ThemeMode.system`. Persists choice in `SharedPreferences` (`attendify_theme_mode`) and broadcasts changes app-wide via `ListenableBuilder` wrapped around `ShadApp.custom` and `MaterialApp` in `main.dart`.", bold_prefix="1. AppThemeController: ")
    add_bullet_item(doc, "Singleton coordinator managing unread notification counts via a reactive `ValueNotifier<int> unreadCount`. Automatically polls the backend every 4 seconds in foreground, deduplicates audio chimes, and emits incoming notification payloads over a broadcast `Stream<Map<String, dynamic>>`.", bold_prefix="2. RealtimeNotificationService: ")
    add_bullet_item(doc, "Firebase Cloud Messaging coordinator registering device push tokens, handling background handlers with `@pragma('vm:entry-point')`, and routing tapped notifications to the appropriate screen.", bold_prefix="3. PushNotificationService: ")
    add_bullet_item(doc, "Singleton network coordinator holding the active Bearer token in memory, backed by `FlutterSecureStorage` with `SharedPreferences` fallback, and triggering global session termination callbacks.", bold_prefix="4. ApiClient Auth State: ")

    add_section_title(doc, "9.3", "Feature & Screen-Level State")
    add_body_p(doc, "Individual screens maintain their own view state using standard `StatefulWidget` patterns:")
    add_bullet_item(doc, "Boolean flags (`_isLoading`, `_isSubmitting`, `_isRefreshing`) toggling between `AppSpinner`, skeleton loaders, and live data widgets.", bold_prefix="Loading States: ")
    add_bullet_item(doc, "Null-safe String or Map objects (`_errorMessage`, `_validationErrors`) displaying inline alert banners or triggering `AppToast.error()`.", bold_prefix="Error States: ")
    add_bullet_item(doc, "Evaluated collections (`_events.isEmpty`) rendering `EmptyStateView` with contextual icons and CTA buttons.", bold_prefix="Empty States: ")

    add_section_title(doc, "9.4", "State Management Architecture Diagram")
    add_code_block(doc,
"""+-------------------------------------------------------------------------+
|                      GLOBAL APPLICATION STATE                           |
|                                                                         |
|  +------------------------+      +-----------------------------------+  |
|  |   AppThemeController   |      |    RealtimeNotificationService    |  |
|  | - ChangeNotifier       |      | - ValueNotifier<int> unreadCount  |  |
|  | - ThemeMode (L/D/S)    |      | - Stream<Map> notificationStream  |  |
|  | - SharedPreferences    |      | - Foreground 4s Lifecycle Poller  |  |
|  +------------------------+      +-----------------------------------+  |
|              |                                     |                    |
+--------------|-------------------------------------|--------------------+
               |                                     |
               v                                     v
+-------------------------------------------------------------------------+
|                        REACTIVE UI CONSUMERS                            |
|                                                                         |
|  ListenableBuilder (main.dart)        ValueListenableBuilder            |
|  -> Rebuilds MaterialApp theme        -> Updates Notification Bell      |
|  -> Re-renders all AetherUI tokens    -> Plays audio chime via helper   |
|                                                                         |
|  Local StatefulWidget Screens:                                           |
|  - _isLoading (AppSpinner)                                              |
|  - _errorMessage (AppToast / ErrorStateView)                            |
|  - _dataCollection.isEmpty (EmptyStateView)                             |
+-------------------------------------------------------------------------+""")

    # -------------------------------------------------------------
    # CHAPTER 10: API INTEGRATION
    # -------------------------------------------------------------
    add_chapter_title(doc, "10", "REST API Integration & Network Layer")

    add_section_title(doc, "10.1", "ApiClient Architecture & Network Interceptors")
    add_body_p(doc, "All network traffic in Attendify is routed through the singleton `ApiClient` (`mobile/lib/core/network/api_client.dart`). The client encapsulates authentication headers, timeout management, automated host detection for Android emulators, and response envelope parsing.", bold_prefix="Network Architecture: ")

    add_body_p(doc, "Key capabilities of the `ApiClient` include:")
    add_bullet_item(doc, "Automatically injects `Accept: application/json`, `Content-Type: application/json`, and `Authorization: Bearer <token>` when a token is stored.", bold_prefix="1. Automatic Header Injection: ")
    add_bullet_item(doc, "If running on an Android emulator and connecting to `127.0.0.1:8000` fails, the client automatically falls back to `http://10.0.2.2:8000/api/v1` without developer intervention.", bold_prefix="2. Android Emulator Auto-Fallback: ")
    add_bullet_item(doc, "Detects HTTP 401 with `ERR_SESSION_TERMINATED` and executes `onSessionTerminated` callback, prompting the user with an un-dismissible session dialog.", bold_prefix="3. Single-Session Interception: ")
    add_bullet_item(doc, "Exposes a static `mockHandler` hook, allowing unit and widget tests to inject mock HTTP responses without spinning up mock HTTP servers.", bold_prefix="4. Test Mocking Harness: ")

    add_section_title(doc, "10.2", "Canonical API Endpoint Inventory")
    add_body_p(doc, "The table below catalogs the primary REST endpoints called by the frontend:")

    api_headers = ["HTTP Method", "Canonical Endpoint Path", "Subsystem Feature", "Auth Required"]
    api_rows = [
        ["POST", "/api/v1/auth/login", "User authentication & session creation", "No (Public)"],
        ["POST", "/api/v1/auth/logout", "Session token revocation & FCM cleanup", "Yes (Sanctum)"],
        ["GET", "/api/v1/profile", "Student/Staff profile & academic data", "Yes (Sanctum)"],
        ["PUT", "/api/v1/profile/change-password", "User password update", "Yes (Sanctum)"],
        ["GET", "/api/v1/student/qr", "Student permanent 64-char QR token", "Yes (Student)"],
        ["POST", "/api/v1/student/qr/reissue", "Revoke & reissue permanent QR token", "Yes (Student)"],
        ["GET", "/api/v1/events", "List events with filters (month, college)", "Yes (Sanctum)"],
        ["GET", "/api/v1/events/audience-options", "Fetch college & year level target lists", "Yes (Organizer/Admin)"],
        ["POST", "/api/v1/events", "Create new event in draft status", "Yes (Organizer/Admin)"],
        ["POST", "/api/v1/events/{id}/submit-approval", "Submit draft event for admin review", "Yes (Organizer)"],
        ["POST", "/api/v1/events/{id}/register", "Register for event or join waiting list", "Yes (Student)"],
        ["POST", "/api/v1/events/{id}/cancel-registration", "Cancel registration & trigger FIFO promo", "Yes (Student)"],
        ["POST", "/api/v1/events/{id}/attendance/scan", "Sub-second camera QR scan verification", "Yes (Organizer/Admin)"],
        ["GET", "/api/v1/events/{id}/attendance", "Live attendance list & counts", "Yes (Organizer/Admin)"],
        ["PUT", "/api/v1/attendance/{id}/correct", "Manual attendance correction with reason", "Yes (Organizer/Admin)"],
        ["GET", "/api/v1/student/attendance-history", "Student personal attendance transcript", "Yes (Student)"],
        ["GET", "/api/v1/dashboard/{role}", "Role-specific dashboard metrics payload", "Yes (Sanctum)"],
        ["GET", "/api/v1/notifications", "In-app notifications inbox list", "Yes (Sanctum)"],
        ["PUT", "/api/v1/notifications/{id}/read", "Mark individual notification as read", "Yes (Sanctum)"],
        ["POST", "/api/v1/notifications/mark-all-read", "Mark all notifications read", "Yes (Sanctum)"],
        ["POST", "/api/v1/device-tokens", "Register FCM device push token", "Yes (Sanctum)"],
        ["GET", "/api/v1/reports/*", "7 Institutional reports data streams", "Yes (Sanctum)"],
        ["POST", "/api/v1/reports/export", "Export report to CSV, XLSX, or PDF", "Yes (Sanctum)"],
        ["GET", "/api/v1/admin/users", "User management search & pagination", "Yes (Admin)"],
        ["PUT", "/api/v1/admin/users/{id}/status", "Toggle active/suspended account status", "Yes (Admin)"],
        ["POST", "/api/v1/admin/users/{id}/reset-password", "Trigger admin temporary password reset", "Yes (Admin)"],
        ["GET", "/api/v1/admin/logs", "Forensic audit activity logs stream", "Yes (Admin)"]
    ]
    add_styled_table(doc, api_headers, api_rows, col_widths=[1.0, 2.7, 1.8, 1.0])

    # -------------------------------------------------------------
    # CHAPTER 11: AUTHENTICATION AND USER ROLES
    # -------------------------------------------------------------
    add_chapter_title(doc, "11", "Authentication & Single-Session Management")

    add_section_title(doc, "11.1", "Login Flow & Credential Validation")
    add_body_p(doc, "The login flow supports both numeric Student ID numbers (for students) and institutional email addresses (for staff, organizers, administrators, and students).", bold_prefix="Authentication Logic: ")
    add_bullet_item(doc, "The user enters their credential and password into `LoginScreen` (`mobile/lib/screens/auth/login_screen.dart`).", bold_prefix="1. Input Ingestion: ")
    add_bullet_item(doc, "The payload is dispatched via `ApiClient().post(ApiConstants.login, body)`. The backend authenticates credentials via Bcrypt.", bold_prefix="2. Backend Validation: ")
    add_bullet_item(doc, "Upon HTTP 200, the response contains `token`, `role`, and `user` data. The frontend saves credentials to `FlutterSecureStorage` (with SharedPreferences fallback) via `ApiClient().saveToken(token, role, userId)`.", bold_prefix="3. Token Persistence: ")
    add_bullet_item(doc, "The app registers the FCM push token with `/api/v1/device-tokens`, initializes `RealtimeNotificationService`, and routes the user to their designated dashboard.", bold_prefix="4. Session Boot: ")

    add_section_title(doc, "11.2", "Single Active Session Enforcement")
    add_body_p(doc, "To prevent account credential sharing and proxy attendance, Attendify enforces strict single active session policies:", bold_prefix="Session Invariant: ")
    add_bullet_item(doc, "When a user logs in, the backend generates a new session UUID (`users.active_session_id`) and revokes all previous Sanctum tokens for that user.", bold_prefix="Backend Invalidation: ")
    add_bullet_item(doc, "If an older device issues a request with a revoked token, the backend returns HTTP 401 with `error_code: 'ERR_SESSION_TERMINATED'`.", bold_prefix="Client Detection: ")
    add_bullet_item(doc, "The `ApiClient` interceptor intercepts this error and triggers `onSessionTerminated`, displaying an un-dismissible `AlertDialog` stating that another login occurred. Tapping 'Return to Login' clears tokens and resets the navigation stack to `LoginScreen`.", bold_prefix="Graceful Eviction: ")

    # -------------------------------------------------------------
    # CHAPTER 12: EVENT MANAGEMENT FRONTEND
    # -------------------------------------------------------------
    add_chapter_title(doc, "12", "Event Management Frontend & Waiting List Queue")

    add_section_title(doc, "12.1", "Event Creation & Editing Workflow")
    add_body_p(doc, "Event creation is managed in `EventFormScreen` (`mobile/lib/screens/organizer/event_form_screen.dart`). Organizers configure event parameters across structured form sections:", bold_prefix="Event Authoring: ")
    add_bullet_item(doc, "Event title, venue, and detailed description.", bold_prefix="1. Basic Details: ")
    add_bullet_item(doc, "Event date, start time, end time, and late arrival grace period in minutes.", bold_prefix="2. Schedule & Timing: ")
    add_bullet_item(doc, "Maximum attendee capacity and walk-in allowance toggle (`walk_in_allowed`).", bold_prefix="3. Capacity Controls: ")
    add_bullet_item(doc, "Target college departments (retrieved from `/api/v1/events/audience-options`) and target year levels (1st through 5th Year).", bold_prefix="4. Audience Targeting: ")

    add_section_title(doc, "12.2", "Capacity Metering & FIFO Waiting List Queue")
    add_body_p(doc, "On the `EventDetailScreen`, the frontend calculates capacity utilization using a visual progress bar. If an event is at 100% capacity, the primary action button changes from 'Register for Event' to 'Join Waiting List'. If a registered student subsequently cancels, the backend automatically promotes waiting list position 1 inside an atomic database transaction.", bold_prefix="Queue Feedback: ")

    # -------------------------------------------------------------
    # CHAPTER 13: CALENDAR AND QR ATTENDANCE
    # -------------------------------------------------------------
    add_chapter_title(doc, "13", "Calendar & QR-Based Attendance Scanning")

    add_section_title(doc, "13.1", "Calendar Integration via TableCalendar")
    add_body_p(doc, "The `CalendarScreen` (`mobile/lib/screens/common/calendar_screen.dart`) embeds the `table_calendar` package, configured with:", bold_prefix="Calendar Architecture: ")
    add_bullet_item(doc, "Days with scheduled events render a subtle dot marker beneath the date number.", bold_prefix="Event Indicators: ")
    add_bullet_item(doc, "Selecting a date immediately updates the bottom event list, filtering to events active on that calendar date.", bold_prefix="Interactive Selection: ")
    add_bullet_item(doc, "Users can toggle between a compact 1-week format and a full 1-month grid format.", bold_prefix="Format Switching: ")

    add_section_title(doc, "13.2", "Live QR Attendance Scanning Engine")
    add_body_p(doc, "Venue check-in is driven by `QrScannerScreen` (`mobile/lib/screens/organizer/qr_scanner_screen.dart`). It coordinates hardware camera scanning with backend verification:", bold_prefix="Scanning Workflow: ")
    add_bullet_item(doc, "The `MobileScanner` widget captures camera frames and decodes barcodes in real time.", bold_prefix="1. Camera Stream: ")
    add_bullet_item(doc, "Upon detecting a barcode, the screen engages a debounce lock (`_isProcessingScan = true`) to prevent duplicate requests.", bold_prefix="2. Debounce Lock: ")
    add_bullet_item(doc, "The 64-character token is dispatched to `POST /api/v1/events/{id}/attendance/scan` with mode (`check_in` or `check_out`).", bold_prefix="3. API Dispatch: ")
    add_bullet_item(doc, "The backend verifies the token, calculates late arrival against the grace period, and returns HTTP 200.", bold_prefix="4. Server Evaluation: ")
    add_bullet_item(doc, "The frontend triggers device haptic vibration, plays an audio chime via `NotificationSoundHelper`, and presents `ScanResultContent` modal sheet showing student photo, name, course, and arrival status (Present, Late, Walk-In).", bold_prefix="5. Feedback & Modal: ")
