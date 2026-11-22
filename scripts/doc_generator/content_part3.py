"""
content_part3.py - Chapters 17 through 24 for Attendify System Analyst Documentation.
"""

from .styles import (
    add_chapter_title, add_section_title, add_subsection_title,
    add_body_p, add_bullet_item, add_callout, add_styled_table, add_code_block
)

def build_part3(doc):
    # =========================================================================
    # CHAPTER 17: NOTIFICATION AND ANNOUNCEMENT MANAGEMENT
    # =========================================================================
    add_chapter_title(doc, 17, "Notification and Announcement Management")

    add_body_p(doc, "Attendify features a multi-channel notification subsystem delivering real-time institutional alerts. Notifications inform users about event publication, registration confirmations, schedule updates, cancellations, and waiting-list queue promotions.")

    add_section_title(doc, "17.1", "Notification Preferences & Mandatory Types")
    add_body_p(doc, "Users can customize their notification preferences via PUT /api/v1/notifications/preferences, mapping to boolean flags in the notification_preferences table:")
    add_bullet_item(doc, "Toggles alerts when new events targeting the student are published.", bold_prefix="• new_event_published: ")
    add_bullet_item(doc, "Toggles confirmations when registering or joining waiting lists.", bold_prefix="• registration_confirmed: ")
    add_bullet_item(doc, "Toggles 24-hour and 1-hour pre-event reminder alerts.", bold_prefix="• event_reminders: ")
    add_bullet_item(doc, "Toggles venue, time, or speaker update announcements.", bold_prefix="• event_updates: ")
    add_bullet_item(doc, "Toggles alerts when promoted from the waiting list to confirmed attendee.", bold_prefix="• waiting_list_promoted: ")
    add_bullet_item(doc, "Toggles general broadcast announcements from administrators.", bold_prefix="• admin_announcements: ")

    add_callout(doc, "Mandatory Notification Invariant: Per SRS Requirement NOTIF-004, two notification categories are strictly mandatory and cannot be disabled by any user: 1. 'event_cancellation' (notifying students that an event is aborted) and 2. 'attendance_recorded' (providing verifiable receipt that check-in or check-out was logged). These bypass all preference filters.", title="Mandatory Notification Policy", alert_type="note")

    add_section_title(doc, "17.2", "Automated Scheduled Jobs & 30-Day Retention Policy")
    add_body_p(doc, "The backend scheduler (routes/console.php) coordinates automated maintenance tasks:")
    add_bullet_item(doc, "Scans for published events starting in 24 hours (±15 min) and dispatches reminder notifications to registered students.", bold_prefix="• 24-Hour Reminder (event-reminder-24h): ")
    add_bullet_item(doc, "Dispatches final preparation alerts 60 minutes prior to event start.", bold_prefix="• 1-Hour Reminder (event-reminder-1h): ")
    add_bullet_item(doc, "To prevent database bloat, notifications older than 30 days are automatically pruned from the notifications table (WHERE created_at < now()->subDays(30)).", bold_prefix="• 30-Day Retention Purge (notifications:purge): ")

    # =========================================================================
    # CHAPTER 18: FIREBASE CLOUD MESSAGING (FCM) AND PUSH NOTIFICATIONS
    # =========================================================================
    add_chapter_title(doc, 18, "Firebase Cloud Messaging and Push Notifications")

    add_section_title(doc, "18.1", "Push Notification Architecture")
    add_body_p(doc, "Push notifications bridge the Laravel backend and mobile devices using the Firebase Cloud Messaging (FCM) HTTP v1 API. The integration utilizes a Google Cloud Service Account OAuth2 token to securely authenticate requests to https://fcm.googleapis.com/v1/projects/{projectId}/messages:send.")

    fcm_flow = (
        "+-----------------------------------------------------------------------------------+\n"
        "|                             PUSH NOTIFICATION PIPELINE                            |\n"
        "|                                                                                   |\n"
        "|  1. Event Triggered (e.g., Event Cancelled or Waiting List Promoted)              |\n"
        "|     NotificationService::send($userId, $title, $message, $type, $payload)        |\n"
        "|                                                                                   |\n"
        "|  2. Database Persistence: In-app record saved in 'notifications' table           |\n"
        "|                                                                                   |\n"
        "|  3. Device Token Resolution: Query 'device_tokens' for active user tokens         |\n"
        "|                                                                                   |\n"
        "|  4. Payload Assembly:                                                             |\n"
        "|     - High priority Android config ('HIGH', PRIORITY_MAX)                         |\n"
        "|     - Channel ID: 'attendify_important_v1'                                        |\n"
        "|     - Custom Sound Chime: 'sfxmint_ready_chime_07'                                 |\n"
        "|     - Data payload: notification_id, event_id, notification_type                  |\n"
        "|                                                                                   |\n"
        "|  5. HTTP v1 Dispatch via Google Service Account Bearer Token                      |\n"
        "|                                                                                   |\n"
        "|  6. Mobile Client Handling (PushNotificationService):                             |\n"
        "|     - Foreground: Plays chime & increments unread badge via RealtimeSync          |\n"
        "|     - Background / Terminated: Android System Tray banner with chime sound        |\n"
        "|     - On Tap: Navigates directly to EventDetailScreen or NotificationsScreen      |\n"
        "+-----------------------------------------------------------------------------------+\n"
    )
    add_code_block(doc, fcm_flow)

    add_section_title(doc, "18.2", "Sound & Channel Configuration")
    add_body_p(doc, "Attendify configures an explicit Android Notification Channel named 'attendify_important_v1' with NotificationManager.IMPORTANCE_HIGH. Important event announcements, reminders, and cancellations trigger the custom chime asset 'sfxmint_ready_chime_07' placed in android/app/src/main/res/raw/.")

    add_section_title(doc, "18.3", "Device Token Registration & Rotation")
    add_body_p(doc, "When the Flutter app boots, PushNotificationService retrieves the local device token via FirebaseMessaging.instance.getToken() and registers it via POST /api/v1/device-tokens. When FCM rotates tokens, onTokenRefresh automatically updates the mapping in the backend. When a user logs out, DELETE /api/v1/device-tokens unlinks the device token to prevent subsequent users on that physical hardware from receiving private alerts.")

    add_callout(doc, "Operational Verification Status: The FCM HTTP v1 dispatch pipeline, token registration endpoints, channel sound bindings, and foreground chime listeners are fully implemented and verified via automated test suites. Background push delivery on physical Android hardware operates over public Google Play Services and requires live Google Services configuration in production.", title="FCM Verification Note", alert_type="tip")

    # =========================================================================
    # CHAPTER 19: IN-APP NOTIFICATION INBOX
    # =========================================================================
    add_chapter_title(doc, 19, "In-App Notification Inbox")

    add_section_title(doc, "19.1", "Real-Time Polling & Unread Synchronization")
    add_body_p(doc, "To provide immediate visual alerts even on devices without Google Play Services (e.g., Web browsers or custom Android distributions), Attendify implements an active client polling daemon via RealtimeNotificationService:")
    add_bullet_item(doc, "Executes GET /api/v1/notifications/unread-count on an adaptive 30-second timer when the application is active in the foreground.", bold_prefix="• Polling Daemon: ")
    add_bullet_item(doc, "Maintains a reactive ValueNotifier<int> unreadCount that drives the red badge overlay on the top header notification bell across all dashboards.", bold_prefix="• Header Badge Binding: ")
    add_bullet_item(doc, "When the user opens the NotificationsScreen or marks notifications as read, the unread count resets to 0 instantly without requiring a full page refresh.", bold_prefix="• Instant Reconciliation: ")

    add_section_title(doc, "19.2", "Notification Action & Navigation Routing")
    add_body_p(doc, "Each notification contains a JSON payload with an event_id. Tapping an event-related notification in the inbox automatically navigates the student directly to EventDetailScreen for that event, providing seamless one-tap registration or venue review.")

    # =========================================================================
    # CHAPTER 20: REPORTS AND DATA EXPORT
    # =========================================================================
    add_chapter_title(doc, 20, "Reports and Data Export")

    add_section_title(doc, "20.1", "The Seven Institutional Report Types")
    add_body_p(doc, "Attendify generates 7 specialized institutional reports catering to academic department heads, student affairs directors, and accreditation reviewers:")

    rep_headers = ["Report Name", "API Route Parameter", "Target Consumers", "Key Data Attributes Included"]
    rep_rows = [
        ["Event Attendance Roster", "event-attendance/{id}", "Organizers, Dept Chairs", "Full student roster, check-in/out timestamps, status (present/late/absent), scanner staff ID."],
        ["Student Attendance History", "student-history/{id}", "Academic Advisers, Dean", "All events attended by an individual student, participation rates, excuses, tardiness counts."],
        ["Registration Summary", "registration-summary/{id}", "Event Organizers, Admin", "Total capacity, registered count, waiting list queue, cancellation tallies, venue utilization rate."],
        ["Participation Summary", "participation-summary", "School Management, Auditors", "Macro metrics across date ranges, cross-department attendance rates, college-wide trends."],
        ["Absenteeism Report", "absentee/{id}", "Student Affairs, Advisers", "Roster of pre-registered students who failed to attend, contact details for academic intervention."],
        ["Walk-In Participant Report", "walk-in/{id}", "Organizers, Facilities", "Roster of students admitted at the door without pre-registration, admission timestamps."],
        ["Organizer Summary Report", "organizer-summary", "Deans, HR, Student Council", "Performance audit of events organized by specific staff/clubs, completion metrics, feedback."]
    ]
    add_styled_table(doc, rep_headers, rep_rows, [1.6, 1.6, 1.4, 1.9])

    add_section_title(doc, "20.2", "Multi-Format Export Engines")
    add_bullet_item(doc, "High-speed streaming export via Response::stream with standard RFC 4180 formatting. Suitable for external data science analysis or SIS database bulk ingestion.", bold_prefix="1. Comma-Separated Values (CSV): ")
    add_bullet_item(doc, "Engineered via Maatwebsite\\Excel with bold header fills, formatted dates, borders, and auto-adjusted column widths. Ideal for departmental spreadsheets.", bold_prefix="2. Microsoft Excel (.xlsx): ")
    add_bullet_item(doc, "Rendered via barryvdh/laravel-dompdf from clean Blade templates. Includes institutional logo, official letterhead, page numbers, signature lines, and strict printable styling.", bold_prefix="3. Adobe Acrobat (PDF): ")

    add_section_title(doc, "20.3", "Cross-Platform FileDownloader Architecture")
    add_body_p(doc, "Downloading binary files on Web vs Mobile requires distinct operating system mechanisms. Attendify abstracts this via FileDownloader:")
    add_bullet_item(doc, "Utilizes dart:html to generate an in-memory Blob URL, binds it to an invisible <a> tag with the 'download' attribute, and dispatches a programmatic click event.", bold_prefix="• Web Implementation (file_downloader_web.dart): ")
    add_bullet_item(doc, "Utilizes path_provider and dart:io to locate the public Downloads directory (/storage/emulated/0/Download), streams bytes directly, and displays a system download notification toast.", bold_prefix="• Mobile Implementation (file_downloader_io.dart): ")

    # =========================================================================
    # CHAPTER 21: ACTIVITY LOGS AND AUDIT TRAIL
    # =========================================================================
    add_chapter_title(doc, 21, "Activity Logs and Audit Trail")

    add_section_title(doc, "21.1", "Immutable Audit Architecture")
    add_body_p(doc, "Attendify enforces comprehensive auditability. Every state-altering administrative or operational action is captured in the activity_logs table via the centralized helper ActivityLog::log($action, $module, $recordId, $metadata). Records in this table are append-only; update and delete operations are prohibited at the model level.")

    add_section_title(doc, "21.2", "Audited Operational Events")
    add_bullet_item(doc, "Login successes, login failures, session invalidations, forced logouts.", bold_prefix="• Authentication: ")
    add_bullet_item(doc, "Event drafting, submission, approval, rejection, and cancellation requests.", bold_prefix="• Event Governance: ")
    add_bullet_item(doc, "Student self-service QR reissues, administrative QR reissues, QR inspections.", bold_prefix="• QR Security: ")
    add_bullet_item(doc, "QR check-in, QR check-out, manual attendance marking, post-event corrections with reasons.", bold_prefix="• Attendance: ")
    add_bullet_item(doc, "User creation, status toggling (active/inactive), administrative password resets.", bold_prefix="• User Administration: ")

    # =========================================================================
    # CHAPTER 22: DATABASE STRUCTURE AND RELATIONSHIPS
    # =========================================================================
    add_chapter_title(doc, 22, "Database Structure and Relationships")

    add_body_p(doc, "The Attendify database (school_event_attendance) comprises 13 core domain tables engineered in MySQL 8.0 / MariaDB 13.x with InnoDB row-level locking, utf8mb4 collation, and strict foreign key integrity.")

    add_section_title(doc, "22.1", "Complete Entity Catalog")
    table_headers = ["Table Name", "Primary Key", "Foreign Keys", "Description & Invariant Rules"]
    table_rows = [
        ["roles", "id", "None", "Defines the 4 fixed roles: administrator, organizer, student, management."],
        ["users", "id", "role_id -> roles.id", "Central authentication identity with active_session_id for single-session enforcement."],
        ["students", "id", "user_id -> users.id", "Official institutional student records; student_id_number is unique."],
        ["student_qrs", "id", "student_id -> students.id", "Permanent 64-char hex QR tokens; exactly one active token per student."],
        ["events", "id", "organizer_id -> users.id", "Events with multi-state approval, capacity limits, and audience targeting rules."],
        ["event_approvals", "id", "event_id -> events.id, admin_id -> users.id", "Formal administrative review records for publishing and cancellation."],
        ["event_registrations", "id", "event_id -> events.id, student_id -> students.id", "Participant registrations and waiting list queue; unique on [event_id, student_id]."],
        ["attendances", "id", "event_id, student_id, scanner_id", "Attendance records (present, late, absent, walk_in); unique on [event_id, student_id]."],
        ["attendance_corrections", "id", "attendance_id -> attendances.id, corrected_by -> users.id", "Immutable audit records for attendance corrections with mandatory justification."],
        ["notifications", "id", "user_id -> users.id", "In-app notification records with title, message, type, and payload JSON."],
        ["notification_preferences", "id", "user_id -> users.id", "User notification preference matrix (booleans for event categories)."],
        ["device_tokens", "id", "user_id -> users.id", "Active FCM push notification registration tokens for Android and Web."],
        ["activity_logs", "id", "user_id -> users.id", "Immutable system audit trail with IP address, user agent, and action metadata."]
    ]
    add_styled_table(doc, table_headers, table_rows, [1.5, 0.9, 1.8, 2.3])

    add_section_title(doc, "22.2", "Entity-Relationship Model (Textual ERD)")
    erd_text = (
        "  [roles] 1 -----< [users] 1 ----- 1 [students]\n"
        "                     |                  |\n"
        "                     |                  +-----< [student_qrs]\n"
        "                     |                  |\n"
        "                     |                  +-----< [event_registrations] >-----+ [events]\n"
        "                     |                  |                                   |\n"
        "                     |                  +-----< [attendances] >-------------+\n"
        "                     |                               |\n"
        "                     |                               +-----< [attendance_corrections]\n"
        "                     |\n"
        "                     +-----< [event_approvals] >----------------------------+ [events]\n"
        "                     +-----< [notifications]\n"
        "                     +-----< [notification_preferences] (1:1)\n"
        "                     +-----< [device_tokens]\n"
        "                     +-----< [activity_logs]\n"
    )
    add_code_block(doc, erd_text)

    # =========================================================================
    # CHAPTER 23: REST API ARCHITECTURE AND IMPORTANT ENDPOINTS
    # =========================================================================
    add_chapter_title(doc, 23, "REST API Architecture and Important Endpoints")

    add_section_title(doc, "23.1", "Standard API Response Envelopes")
    add_body_p(doc, "All REST API endpoints conform to a standardized JSON response envelope:")
    add_body_p(doc, "Success Response Shape (HTTP 200 / 201):")
    add_code_block(doc, '{\n  "success": true,\n  "message": "Operation completed successfully.",\n  "data": { ... }\n}')
    add_body_p(doc, "Error Response Shape (HTTP 400 / 401 / 403 / 404 / 422 / 500):")
    add_code_block(doc, '{\n  "success": false,\n  "error_code": "ERR_SPECIFIC_CODE",\n  "message": "Human-readable failure description.",\n  "errors": { "field": ["Validation message"] }\n}')

    add_section_title(doc, "23.2", "Core Endpoint Catalog")
    api_headers = ["HTTP Verb & Route Path", "Middleware Required", "Role Authorized", "Operational Summary"]
    api_rows = [
        ["POST /api/v1/auth/login", "throttle:5,1", "Public", "Authenticates via email or Student ID; issues session token."],
        ["POST /api/v1/auth/logout", "auth:sanctum, single.session", "All Roles", "Revokes active session token and clears session ID."],
        ["GET /api/v1/events", "auth:sanctum, single.session", "All Roles", "Lists events filtered by status, category, date, and audience eligibility."],
        ["POST /api/v1/events", "auth:sanctum, role:admin,organizer", "Admin, Organizer", "Drafts new event with audience targeting and capacity."],
        ["POST /api/v1/events/{id}/submit-approval", "role:admin,organizer", "Admin, Organizer", "Transitions event from draft to pending_approval."],
        ["POST /api/v1/admin/events/{id}/review", "role:administrator", "Administrator", "Approves (publishes) or rejects pending event."],
        ["POST /api/v1/events/{id}/register", "role:student", "Student", "Registers student or places on waiting list."],
        ["DELETE /api/v1/events/{id}/cancel-registration", "role:student", "Student", "Cancels registration; promotes next waiting list student."],
        ["POST /api/v1/events/{id}/attendance/scan", "throttle:60,1, role:admin,org", "Admin, Organizer", "Scans permanent QR code; records check-in or check-out."],
        ["PUT /api/v1/attendance/{id}/correct", "role:admin,organizer", "Admin, Organizer", "Corrects attendance status with mandatory justification."],
        ["GET /api/v1/student/qr", "role:student", "Student", "Returns active permanent QR code token for display."],
        ["POST /api/v1/student/qr/reissue", "role:student", "Student", "Atomically revokes old QR and generates fresh token."],
        ["GET /api/v1/reports/export", "role:admin,org,management", "Admin, Org, Mgmt", "Exports reports in CSV, XLSX, or PDF format."],
        ["POST /api/v1/device-tokens", "auth:sanctum, single.session", "All Roles", "Registers active mobile/web FCM device token."],
        ["GET /api/v1/admin/logs", "role:administrator", "Administrator", "Returns paginated immutable activity logs with filters."]
    ]
    add_styled_table(doc, api_headers, api_rows, [1.9, 1.3, 1.1, 2.2])

    # =========================================================================
    # CHAPTER 24: FRONTEND AND BACKEND COMMUNICATION
    # =========================================================================
    add_chapter_title(doc, 24, "Frontend and Backend Communication")

    add_section_title(doc, "24.1", "ApiClient Architecture")
    add_body_p(doc, "All network communication in the Flutter application flows through a centralized ApiClient singleton (mobile/lib/core/network/api_client.dart). Key architectural capabilities include:")
    add_bullet_item(doc, "Automatically prepends the Authorization: Bearer {token} header to every protected request.", bold_prefix="• Automatic Bearer Injection: ")
    add_bullet_item(doc, "Persists authentication tokens securely in hardware-backed storage (FlutterSecureStorage on Android, encrypted local storage on Web).", bold_prefix="• Hardware-Backed Token Storage: ")
    add_bullet_item(doc, "Intercepts HTTP 401 Unauthorized responses. If error_code is ERR_SESSION_TERMINATED, triggers the global onSessionTerminated callback to display the termination modal.", bold_prefix="• 401 Session Interception: ")
    add_bullet_item(doc, "Standardized timeout configuration (15 seconds default) with structured exception handling preventing unhandled asynchronous crashes.", bold_prefix="• Resilient Timeout & Exception Guard: ")
