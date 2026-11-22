"""
part4.py - Chapters 14 to 18 for Attendify Frontend Developer Guide.
Covers:
- Chapter 14: Notifications and Firebase Cloud Messaging (FCM, Foreground, Chimes)
- Chapter 15: Forms and Input Validation (TextControllers, Regex, Error Mapping)
- Chapter 16: Responsive Design and Platform Compatibility (LayoutBuilder, Breakpoints)
- Chapter 17: Error Handling and Debugging (ApiClient Envelope, DevTools, Logcat)
- Chapter 18: Frontend Testing (Widget Tests, AppTestHost, 202 Passing Tests)
"""

from .styles import (
    add_chapter_title, add_section_title, add_subsection_title,
    add_body_p, add_bullet_item, add_callout, add_styled_table, add_code_block
)

def add_part4(doc):
    # -------------------------------------------------------------
    # CHAPTER 14: NOTIFICATIONS AND FIREBASE CLOUD MESSAGING
    # -------------------------------------------------------------
    add_chapter_title(doc, "14", "Notifications & Firebase Cloud Messaging (FCM)")

    add_section_title(doc, "14.1", "Dual-Channel Notification Architecture")
    add_body_p(doc, "Attendify implements a dual-channel notification architecture designed to guarantee delivery regardless of device state, network carrier, or application lifecycle:", bold_prefix="Dual Architecture: ")
    add_bullet_item(doc, "Managed by `PushNotificationService` (`mobile/lib/core/services/push_notification_service.dart`). Handles background push notifications when the application is minimized or terminated, displaying alerts in the Android system notification tray.", bold_prefix="1. Native Firebase Cloud Messaging (FCM): ")
    add_bullet_item(doc, "Managed by `RealtimeNotificationService` (`mobile/lib/core/services/realtime_notification_service.dart`). Polls the backend every 4 seconds in the foreground, updates reactive `unreadCount` badges, plays audible chimes, and surfaces in-app toast banners.", bold_prefix="2. Foreground Real-Time In-App Poller: ")

    add_section_title(doc, "14.2", "FCM Lifecycle Handlers")
    add_body_p(doc, "The Flutter application handles push notifications across three distinct execution states:")
    add_bullet_item(doc, "Handled by the top-level function `@pragma('vm:entry-point') Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message)`. Processed by the Android notification manager without waking the full Flutter UI.", bold_prefix="Background & Terminated: ")
    add_bullet_item(doc, "Handled by `FirebaseMessaging.onMessage.listen()`. The service extracts the payload, triggers `NotificationSoundHelper.playIfSoundEnabled()`, and calls `syncNotifications()` to refresh in-app lists.", bold_prefix="Foreground Active: ")
    add_bullet_item(doc, "Handled by `FirebaseMessaging.onMessageOpenedApp` and `getInitialMessage()`. If the notification payload contains an `event_id`, the navigator automatically pushes `EventDetailScreen(eventId: id)`; otherwise, it opens `NotificationsScreen`.", bold_prefix="Notification Tap Routing: ")

    add_section_title(doc, "14.3", "FCM Notification Flow Diagram")
    add_code_block(doc,
"""+-------------------------------------------------------------------------+
|                    LARAVEL 11 BACKEND NOTIFICATION                      |
|            (Dispatches FCM HTTP v1 JSON to Google FCM Servers)          |
+-------------------------------------------------------------------------+
                                    |
                                    v
+-------------------------------------------------------------------------+
|                      GOOGLE FCM CLOUD GATEWAY                           |
+-------------------------------------------------------------------------+
                                    |
                    +---------------+---------------+
                    |                               |
       App Minimized / Terminated             App in Foreground
                    |                               |
                    v                               v
    +--------------------------------+   +--------------------------------+
    |   ANDROID NOTIFICATION TRAY    |   | FirebaseMessaging.onMessage    |
    | - Native OS alert banner       |   | - Plays sound via helper       |
    | - User taps notification       |   | - Updates unreadCount badge    |
    | - Routes to EventDetailScreen  |   | - Emits to active inbox screen |
    +--------------------------------+   +--------------------------------+""")

    # -------------------------------------------------------------
    # CHAPTER 15: FORMS AND INPUT VALIDATION
    # -------------------------------------------------------------
    add_chapter_title(doc, "15", "Forms, Controllers & Input Validation")

    add_section_title(doc, "15.1", "Form Architecture & Controller Lifecycle")
    add_body_p(doc, "Form screens in Attendify (such as `LoginScreen`, `EventFormScreen`, and `ProfileScreen`) use Flutter `Form` widgets paired with strongly typed `TextEditingController` instances initialized in `initState()` and explicitly disposed in `dispose()` to prevent memory leaks.", bold_prefix="Form Discipline: ")

    add_section_title(doc, "15.2", "Client-Side Validation Rules")
    add_bullet_item(doc, "Evaluates whether the input matches institutional email format (`^[a-zA-Z0-9._%+-]+@school\.edu$`) or a numeric Student ID (6 to 12 digits).", bold_prefix="Account Identifier: ")
    add_bullet_item(doc, "Enforces a minimum of 8 characters for security.", bold_prefix="Password Fields: ")
    add_bullet_item(doc, "Validates that title, venue, and description are non-empty and within character limits.", bold_prefix="Event Details: ")
    add_bullet_item(doc, "Ensures event start time is prior to end time, and event date is not in the past.", bold_prefix="Date & Time Logic: ")
    add_bullet_item(doc, "Enforces numeric integer >= 1; rejects negative or non-numeric values.", bold_prefix="Capacity Limits: ")
    add_bullet_item(doc, "Mandatory justification text (minimum 10 characters) required before manual attendance adjustments can be submitted.", bold_prefix="Correction Reason: ")

    add_section_title(doc, "15.3", "Backend 422 Validation Error Mapping")
    add_body_p(doc, "When the Laravel backend returns HTTP 422 Unprocessable Entity, the `errors` JSON object maps field names to error string lists. The frontend inspects `response.errors` and surfaces inline validation messages under the corresponding input fields via `_validationErrors['field_name']`.", bold_prefix="Error Binding: ")

    # -------------------------------------------------------------
    # CHAPTER 16: RESPONSIVE DESIGN AND PLATFORM COMPATIBILITY
    # -------------------------------------------------------------
    add_chapter_title(doc, "16", "Responsive Layout & Cross-Platform Adaptation")

    add_section_title(doc, "16.1", "Viewport Breakpoints & ResponsiveLayout Widget")
    add_body_p(doc, "Attendify uses `ResponsiveLayout` (`mobile/lib/core/layout/responsive_layout.dart`) which relies on `LayoutBuilder` to render optimized interfaces across screen sizes:", bold_prefix="Breakpoint Standards: ")
    add_bullet_item(doc, "Width < 600px. Single-column card stacks, bottom navigation bars, full-width modal sheets, touch-optimized button targets (minimum 48x48px).", bold_prefix="1. Compact Viewport (Mobile): ")
    add_bullet_item(doc, "Width between 600px and 1024px. Two-column grid layouts, vertical navigation rail, expanded table views.", bold_prefix="2. Medium Viewport (Tablet / Foldable): ")
    add_bullet_item(doc, "Width > 1024px. Multi-column data tables, persistent navigation sidebar, wide-screen calendar view, sticky action headers.", bold_prefix="3. Expanded Viewport (Desktop Web): ")

    add_section_title(doc, "16.2", "Platform Compatibility: Web vs. Native Android")
    add_body_p(doc, "The codebase uses conditional imports and platform guards to ensure flawless operation across Web and Android:")
    add_bullet_item(doc, "On Flutter Web, downloads create an in-memory HTML anchor element and trigger browser downloads; on Android, files are written to device storage using `path_provider`.", bold_prefix="File Downloads: ")
    add_bullet_item(doc, "On Android, audio chimes utilize native sound pools; on Flutter Web, web audio stubs prevent compilation crashes.", bold_prefix="Audio Effects: ")

    # -------------------------------------------------------------
    # CHAPTER 17: ERROR HANDLING AND DEBUGGING
    # -------------------------------------------------------------
    add_chapter_title(doc, "17", "Error Handling & Debugging Runbook")

    add_section_title(doc, "17.1", "Standardized ApiResponse Envelope")
    add_body_p(doc, "All network calls return a strongly typed `ApiResponse` object:", bold_prefix="Response Contract: ")
    add_code_block(doc,
"""class ApiResponse {
  final bool success;
  final String? message;
  final dynamic data;
  final Map<String, dynamic>? errors;
  final int statusCode;
  final Map<String, dynamic>? rawBody;
}""")

    add_section_title(doc, "17.2", "Frontend Developer Debugging Techniques")
    add_bullet_item(doc, "Use `flutter run -v` to inspect build compiler output and native Android Gradle logs.", bold_prefix="Verbose Compiler Logs: ")
    add_bullet_item(doc, "Launch Flutter DevTools (`flutter run --start-paused`) to inspect widget rebuild trees, measure rendering performance, and debug layout constraints.", bold_prefix="Flutter DevTools: ")
    add_bullet_item(doc, "Execute `adb logcat -s flutter` on connected Android devices to filter application-specific messages and FCM token registrations.", bold_prefix="Android Logcat: ")

    # -------------------------------------------------------------
    # CHAPTER 18: FRONTEND TESTING
    # -------------------------------------------------------------
    add_chapter_title(doc, "18", "Frontend Testing & Quality Assurance")

    add_section_title(doc, "18.1", "Testing Architecture & AppTestHost Harness")
    add_body_p(doc, "Attendify features an extensive automated test suite comprising **202 passing tests** across 36 test files in `mobile/test/`. All widget tests execute within the standardized `AppTestHost` harness (`mobile/test/support/app_test_host.dart`), which wraps tested widgets with `ShadApp.custom`, `AppTheme`, and pre-configured mocks for `FlutterSecureStorage` and `SharedPreferences`.", bold_prefix="Test Harness: ")

    add_section_title(doc, "18.2", "Test Inventory Breakdown")
    add_body_p(doc, "The automated frontend test suite covers five critical quality domains:")
    add_bullet_item(doc, "36 tests verifying `AppButton`, `AppShell`, `AppSpinner`, `AppToast`, `EventCard`, and responsive layouts.", bold_prefix="1. Core Widget Tests: ")
    add_bullet_item(doc, "18 tests verifying `AppThemeController` mode changes, theme persistence, and header toggle synchronization.", bold_prefix="2. Theme Integration Tests: ")
    add_bullet_item(doc, "42 tests verifying `ApiClient` header injection, 401 session termination, and Android emulator host auto-detection.", bold_prefix="3. Network & Auth Tests: ")
    add_bullet_item(doc, "28 tests verifying FCM token synchronization, foreground chimes, and lifecycle poller pause/resume.", bold_prefix="4. Notification Service Tests: ")
    add_bullet_item(doc, "78 tests verifying screen layouts across Student, Organizer, Admin, and Management dashboards.", bold_prefix="5. Role Screen Tests: ")

    add_section_title(doc, "18.3", "Running Frontend Tests")
    add_body_p(doc, "Execute the complete test suite from the `mobile/` directory:")
    add_code_block(doc, "flutter test")
    add_body_p(doc, "All 202 tests execute in under 15 seconds, providing immediate feedback for developers.")
