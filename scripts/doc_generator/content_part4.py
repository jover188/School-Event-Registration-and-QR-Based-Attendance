"""
content_part4.py - Chapters 25 through 33 for Attendify System Analyst Documentation.
"""

from .styles import (
    add_chapter_title, add_section_title, add_subsection_title,
    add_body_p, add_bullet_item, add_callout, add_styled_table, add_code_block
)

def build_part4(doc):
    # =========================================================================
    # CHAPTER 25: COMPLETE SYSTEM WORKFLOWS
    # =========================================================================
    add_chapter_title(doc, 25, "Complete System Workflows")

    add_section_title(doc, "25.1", "Workflow 1: Student Account Provisioning & Login")
    wf1_text = (
        "1. SIS Synchronization: School database seeds student records into 'users' and 'students' tables.\n"
        "2. Student Launches App: Student enters Student ID ('20260001') and institutional password.\n"
        "3. Backend Authentication: POST /api/v1/auth/login verifies credentials.\n"
        "4. Session Management: Backend generates fresh active_session_id UUID, invalidates old sessions, and issues Bearer token.\n"
        "5. Dashboard Navigation: AppShell mounts StudentDashboardScreen; queries GET /api/v1/student/qr to prepare QR token.\n"
    )
    add_code_block(doc, wf1_text)

    add_section_title(doc, "25.2", "Workflow 2: Event Creation, Approval, and Publishing")
    wf2_text = (
        "1. Organizer Drafts Event: POST /api/v1/events with venue, dates, capacity, audience rules, save_as_draft=true.\n"
        "2. Submission for Review: POST /api/v1/events/{id}/submit-approval transitions status to 'pending_approval'.\n"
        "3. Admin Notification: Administrator sees pending event badge in AdminDashboardScreen.\n"
        "4. Approval Decision: POST /api/v1/admin/events/{id}/review with action='approved'.\n"
        "5. Publication & Broadcast: Event status -> 'published'. EventNotificationService resolves eligible students and dispatches broadcast.\n"
    )
    add_code_block(doc, wf2_text)

    add_section_title(doc, "25.3", "Workflow 3: Registration, Capacity Overflow & Auto-Promotion")
    wf3_text = (
        "1. Student Requests Registration: POST /api/v1/events/{id}/register.\n"
        "2. ACID Capacity Check (Inside DB::transaction):\n"
        "   - IF count(registered) < max_participants: Enrolls student with status='registered'.\n"
        "   - IF count(registered) >= max_participants: Enrolls student on waiting list with status='waiting_list', position = max+1.\n"
        "3. Registered Student Cancels: DELETE /api/v1/events/{id}/cancel-registration.\n"
        "4. Automatic Promotion (Inside DB::transaction):\n"
        "   - Cancelling student status updated to 'cancelled'.\n"
        "   - Lowest waiting_list_position student (position 1) is automatically promoted to status='registered'.\n"
        "   - Remaining waiting list entries have their positions decremented by 1.\n"
        "   - Promoted student receives high-priority 'waiting_list_promoted' push notification.\n"
    )
    add_code_block(doc, wf3_text)

    add_section_title(doc, "25.4", "Workflow 4: QR-Based Attendance Scanning (Check-In & Check-Out)")
    wf4_text = (
        "1. Student Presents QR: Mobile screen or printed badge displays permanent 64-char QR.\n"
        "2. Camera Recognition: Organizer camera scans QR via mobile_scanner package.\n"
        "3. API Verification: POST /api/v1/events/{id}/attendance/scan { qr_token: '...', mode: 'check_in' }.\n"
        "4. Backend Evaluation: Verifies token validity -> checks pre-registration -> computes late grace period.\n"
        "5. Database Commit: Creates/updates attendances row with check_in_time and status (present/late/walk_in).\n"
        "6. Visual On-Screen Feedback: Scanner UI displays green confirmation with student photo avatar and full name.\n"
    )
    add_code_block(doc, wf4_text)

    # =========================================================================
    # CHAPTER 26: SECURITY AND AUTHORIZATION
    # =========================================================================
    add_chapter_title(doc, 26, "Security and Authorization Architecture")

    add_body_p(doc, "Attendify adheres to the Principle of Least Privilege and employs a defense-in-depth security model across network, application, and database layers.")

    add_section_title(doc, "26.1", "Multi-Tier Security Measures")
    sec_headers = ["Security Domain", "Mechanism Employed", "Threat Mitigated", "Architectural Layer"]
    sec_rows = [
        ["API Authentication", "Laravel Sanctum Token Hashing", "Credential interception & token forgery", "API Middleware"],
        ["Session Integrity", "EnforceSingleSession (UUID check)", "Account sharing & concurrent proxy scans", "Application Service"],
        ["Rate Limiting", "throttle:5,1 (Auth), throttle:60,1 (Scanner)", "Brute-force password guessing & scanner DoS", "Route Gateway"],
        ["Data Privacy", "Cryptographic 64-char QR token (Zero PII)", "Identity theft from barcode interception", "Domain Model"],
        ["SQL Injection", "Eloquent Parameterized PDO Queries", "Database exfiltration & SQL injection attacks", "Database Engine"],
        ["Cross-Site Scripting", "Sanitized Blade & JSON Unicode Escapes", "Stored & Reflected XSS in student profiles", "Presentation Layer"],
        ["Audit Accountability", "Immutable activity_logs Relational Store", "Repudiation of administrative actions", "Audit Subsystem"]
    ]
    add_styled_table(doc, sec_headers, sec_rows, [1.4, 1.8, 1.9, 1.4])

    add_section_title(doc, "26.2", "Cryptographic Token Storage & Invalidation")
    add_body_p(doc, "Sanctum tokens are hashed using SHA-256 prior to database storage in personal_access_tokens. When a user logs out or has their password administratively reset, tokens are deleted immediately, rendering any cached Bearer token instantly useless.")

    # =========================================================================
    # CHAPTER 27: DEPLOYMENT AND HOSTING ARCHITECTURE
    # =========================================================================
    add_chapter_title(doc, 27, "Deployment and Hosting Architecture")

    add_section_title(doc, "27.1", "Render PaaS Cloud Hosting Architecture")
    add_body_p(doc, "Attendify is deployed as a unified containerized service on Render (PaaS). The deployment coordinates both the Laravel REST API backend and the compiled Flutter Web single-page application from a single origin, completely eliminating Cross-Origin Resource Sharing (CORS) preflight latencies in production.")

    add_section_title(doc, "27.2", "Web Static Asset Hosting & SPA Routing")
    add_body_p(doc, "The Flutter Web production release (flutter build web --release --base-href /) is hosted directly within backend/public/. To ensure seamless client-side routing:")
    add_bullet_item(doc, "The HTML base href is strictly configured as <base href=\"/\"> in backend/public/index.html.", bold_prefix="• Root Base Href: ")
    add_bullet_item(doc, "Laravel's routes/web.php includes a catch-all route Route::get('/app/{any?}', ...) ensuring deep links or page refreshes return index.html rather than an Apache 404.", bold_prefix="• Fallback SPA Route: ")

    # =========================================================================
    # CHAPTER 28: CONFIGURATION AND ENVIRONMENT VARIABLES
    # =========================================================================
    add_chapter_title(doc, 28, "Configuration and Environment Variables")

    add_body_p(doc, "System behavior is governed by environment variables defined in backend/.env. Sensitive API secrets and credentials must never be committed to source control.")

    env_headers = ["Environment Variable", "Configuration Purpose", "Production Guideline", "Sample Sanitized Value"]
    env_rows = [
        ["APP_ENV", "Defines application environment", "Must be set to 'production'", "production"],
        ["APP_DEBUG", "Controls verbose stack traces", "Strictly false in production", "false"],
        ["APP_URL", "Canonical domain root", "Must match live HTTPS domain", "https://attendify-fugh.onrender.com"],
        ["DB_CONNECTION", "Relational database driver", "Must be 'mysql'", "mysql"],
        ["DB_HOST / DB_PORT", "Database server host and port", "Private cloud network IP or 127.0.0.1", "127.0.0.1:3306"],
        ["DB_DATABASE", "Relational database name", "Dedicated application database", "school_event_attendance"],
        ["SANCTUM_STATEFUL_DOMAINS", "Domains using Sanctum cookies", "Comma-separated hostnames", "attendify-fugh.onrender.com"],
        ["FIREBASE_CREDENTIALS", "Path to Google Service Account JSON", "Mount via Render secret files", "/etc/secrets/firebase_service_account.json"],
        ["FCM_CHANNEL_ID", "Android notification channel", "Must match mobile app manifest", "attendify_important_v1"]
    ]
    add_styled_table(doc, env_headers, env_rows, [1.8, 1.7, 1.5, 1.5])

    # =========================================================================
    # CHAPTER 29: TESTING PROCEDURES AND TEST CASES
    # =========================================================================
    add_chapter_title(doc, 29, "Testing Procedures and Test Cases")

    add_section_title(doc, "29.1", "Automated Testing Architecture")
    add_body_p(doc, "Attendify maintains two independent, comprehensive automated test suites enforcing regression-free development:")
    add_bullet_item(doc, "117 Feature and Unit tests (600 assertions) passing on SQLite in-memory database (:memory:). Ensures that tests execute in sub-minute times with zero risk of corrupting local MySQL data.", bold_prefix="• Backend Test Suite (PHPUnit): ")
    add_bullet_item(doc, "202 Unit, Widget, and Integration tests passing with 0 static analyzer issues across Flutter core themes, controllers, layouts, and role dashboards.", bold_prefix="• Mobile Test Suite (Flutter Test): ")

    add_section_title(doc, "29.2", "Core Test Verification Matrix")
    test_headers = ["Test Suite / Class", "Subsystem", "Test Count", "Core Invariant Verified"]
    test_rows = [
        ["SchoolAttendanceWorkflowTest", "Backend", "18 Tests", "End-to-end event lifecycle, registration queue, and QR scan."],
        ["AuthorizationPolicyTest", "Backend", "14 Tests", "Strict RBAC role boundaries and 403 Forbidden enforcement."],
        ["ReportExportTest", "Backend", "12 Tests", "CSV, XLSX, and PDF report generation across all 7 report types."],
        ["AuthAndStaffOperationsTest", "Backend", "16 Tests", "Single-session invalidation and administrative operations."],
        ["StudentProfileSecurityTest", "Backend", "8 Tests", "Profile immutability and discrepancy request workflow."],
        ["ThemeControllerTest", "Mobile", "10 Tests", "AppThemeController singleton, SharedPreferences persistence."],
        ["ThemeIntegrationTest", "Mobile", "3 Tests", "MaterialApp + ShadApp dynamic reactive themeMode binding."],
        ["ThemeToggleButtonTest", "Mobile", "9 Tests", "Header Sun/Moon toggle icon switching and synchronization."],
        ["ThemeSettingsTest", "Mobile", "6 Tests", "ProfileScreen 3-way theme selector and persistence."],
        ["AccountLayoutTest", "Mobile", "8 Tests", "Login layout adaptation across Light and Dark mode tokens."]
    ]
    add_styled_table(doc, test_headers, test_rows, [2.1, 1.0, 1.0, 2.4])

    # =========================================================================
    # CHAPTER 30: KNOWN LIMITATIONS, ISSUES, AND PENDING VERIFICATION
    # =========================================================================
    add_chapter_title(doc, 30, "Known Limitations and Operational Boundaries")

    add_section_title(doc, "30.1", "Documented System Limitations")
    add_bullet_item(doc, "The QR scanner requires an active internet connection to validate attendance against the central database. Offline queue-and-forward scanning is omitted to ensure real-time capacity and single-session security.", bold_prefix="1. Online Network Dependency: ")
    add_bullet_item(doc, "Public self-registration is intentionally disabled. Student accounts must be provisioned via SIS synchronization or administrative creation.", bold_prefix="2. No Public Self-Registration: ")
    add_bullet_item(doc, "In accordance with institutional guidelines, all attendance algorithms and reports are deterministic; no runtime LLM or AI features are present.", bold_prefix="3. No In-App Runtime AI: ")

    add_section_title(doc, "30.2", "Pending Physical Verification Items")
    add_body_p(doc, "While all FCM code paths, sound bindings, and token endpoints are verified in software, end-to-end background push notification delivery over physical carrier cellular networks requires final validation on physical Android hardware registered with Google Play Services.")

    # =========================================================================
    # CHAPTER 31: TROUBLESHOOTING GUIDE
    # =========================================================================
    add_chapter_title(doc, 31, "Troubleshooting Guide and Operational Runbook")

    add_section_title(doc, "31.1", "Diagnostic Decision Matrix")
    trouble_headers = ["Observed Symptom", "Probable Root Cause", "Step-by-Step Resolution Procedure"]
    trouble_rows = [
        ["'Session Terminated' Modal on Client", "User logged in on another device or admin reset password.", "Expected security behavior. Instruct user to log in again if they wish to use this device."],
        ["White Blank Screen on Web Deployment", "HTML <base href> mismatch or missing SPA route fallback.", "Verify backend/public/index.html has <base href=\"/\"> and routes/web.php has /app/{any?} fallback route."],
        ["HTTP 401 Unauthorized on API", "Sanctum token expired or authorization header omitted.", "Ensure ApiClient passes 'Authorization: Bearer {token}'. Re-authenticate to obtain fresh token."],
        ["Scanner Error 'ERR_INVALID_QR'", "Student displaying revoked or invalid QR code token.", "Instruct student to tap 'Reissue QR' in Attendify app to synchronize a fresh active token."],
        ["Push Notifications Not Received", "Missing Google Service Account JSON or disabled channel.", "Verify FIREBASE_CREDENTIALS path in backend .env and confirm notifications permission granted on device."],
        ["Report Download Fails on Mobile", "Missing storage write permissions on Android.", "Verify path_provider downloads directory resolution in file_downloader_io.dart."]
    ]
    add_styled_table(doc, trouble_headers, trouble_rows, [1.8, 1.9, 2.8])

    # =========================================================================
    # CHAPTER 32: GLOSSARY OF TECHNICAL TERMS
    # =========================================================================
    add_chapter_title(doc, 32, "Glossary of Technical Terms")

    glossary_headers = ["Technical Term", "Formal System Analyst Definition"]
    glossary_rows = [
        ["ACID", "Atomicity, Consistency, Isolation, Durability; database transaction guarantees implemented in InnoDB."],
        ["AetherUI", "Attendify's proprietary Flutter design system adhering to high-contrast black-and-white visual identity."],
        ["Bearer Token", "Cryptographically signed HTTP authorization credential issued by Laravel Sanctum."],
        ["DomPDF", "PHP library converting HTML5/CSS3 Blade templates into binary Adobe Acrobat PDF documents."],
        ["FCM HTTP v1", "Google Firebase Cloud Messaging v1 REST protocol utilizing OAuth2 service accounts for push alerts."],
        ["Late Grace Period", "Configurable window (default 15 minutes) post-event start where check-in is marked 'present' rather than 'late'."],
        ["PII", "Personally Identifiable Information; legal names, student numbers, and contact details isolated from QR tokens."],
        ["RBAC", "Role-Based Access Control; security model restricting API operations based on user role slugs."],
        ["SIS", "Student Information System; the campus-wide database holding authoritative student enrollment records."],
        ["Single Active Session", "Security policy invalidating previous authentication tokens upon login from a new device."],
        ["Waiting List Queue", "Sequential FIFO queue holding student registrations when an event reaches maximum capacity."],
        ["Walk-In Participant", "A student admitted and checked into an event at the venue door without prior online pre-registration."]
    ]
    add_styled_table(doc, glossary_headers, glossary_rows, [1.8, 4.7])

    # =========================================================================
    # CHAPTER 33: APPENDIX AND SUPPORTING REFERENCES
    # =========================================================================
    add_chapter_title(doc, 33, "Appendix and Supporting References")

    add_section_title(doc, "33.1", "Source Code File Map")
    add_body_p(doc, "Key architectural files across the Attendify repository:")
    add_bullet_item(doc, "Centralized API routes for all 47 v1 endpoints.", bold_prefix="• backend/routes/api.php: ")
    add_bullet_item(doc, "Scheduled tasks (24h/1h reminders, 30-day purge, event auto-completion).", bold_prefix="• backend/routes/console.php: ")
    add_bullet_item(doc, "Push notification dispatch and notification preference filtering.", bold_prefix="• backend/app/Services/NotificationService.php: ")
    add_bullet_item(doc, "Audience targeting resolution and event reminder dispatcher.", bold_prefix="• backend/app/Services/EventNotificationService.php: ")
    add_bullet_item(doc, "Single active session enforcement middleware.", bold_prefix="• backend/app/Http/Middleware/EnforceSingleSession.php: ")
    add_bullet_item(doc, "Centralized HTTP client with Bearer token injection and 401 interception.", bold_prefix="• mobile/lib/core/network/api_client.dart: ")
    add_bullet_item(doc, "Cross-platform file downloading for CSV, XLSX, and PDF exports.", bold_prefix="• mobile/lib/core/network/file_downloader.dart: ")
    add_bullet_item(doc, "Centralized reactive theme controller managing Light, Dark, and System modes.", bold_prefix="• mobile/lib/core/theme/theme_controller.dart: ")
    add_bullet_item(doc, "Firebase Cloud Messaging coordinator handling tokens, chime sounds, and routing.", bold_prefix="• mobile/lib/core/services/push_notification_service.dart: ")
    add_bullet_item(doc, "Adaptive 30-second in-app notification polling daemon.", bold_prefix="• mobile/lib/core/services/realtime_notification_service.dart: ")

    add_section_title(doc, "33.2", "Authoritative Specification References")
    add_bullet_item(doc, "System Context, Invariants, and Database Tables Reference.", bold_prefix="• context.md: ")
    add_bullet_item(doc, "Finalized Software Requirements Specification (v1.1 baseline).", bold_prefix="• School_Event_Attendance_SRS_v1.0.md: ")
    add_bullet_item(doc, "Entity-Relationship Diagrams, Sequence Diagrams, and MySQL 8.0 DDL.", bold_prefix="• System_Architecture_and_Database_Design.md: ")
    add_bullet_item(doc, "Complete REST API Route and JSON Envelope Specification.", bold_prefix="• REST_API_Specification.md: ")
    add_bullet_item(doc, "OpenAPI 3.0.3 machine-readable contract.", bold_prefix="• openapi.yaml: ")
    add_bullet_item(doc, "Mandatory workspace constraints and agent coding guidelines.", bold_prefix="• AGENTS.md: ")

    # Closing sign-off block
    add_callout(doc, "Documentation Sign-Off: This manual represents the complete, verified, and authoritative System Analyst reference for Attendify Release 1.1.0. All documented endpoints, tables, and workflows have been verified against the production code repository.", title="Authoritative Sign-Off", alert_type="tip")
