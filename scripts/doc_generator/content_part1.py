"""
content_part1.py - Chapters 1 through 8 for Attendify System Analyst Documentation.
"""

from .styles import (
    add_chapter_title, add_section_title, add_subsection_title,
    add_body_p, add_bullet_item, add_callout, add_styled_table, add_code_block
)

def build_part1(doc):
    # =========================================================================
    # CHAPTER 1: DOCUMENT INFORMATION & REVISION HISTORY
    # =========================================================================
    add_chapter_title(doc, 1, "Document Information and Revision History")

    add_body_p(doc, "This document serves as the formal System Analyst Technical and Functional Reference Manual for the School Event Registration and QR-Based Attendance Management System (commercialized as Attendify). It captures the end-to-end operational architecture, business logic, security constraints, database design, REST API specifications, and workflow state machines governing the Attendify software platform.")

    add_section_title(doc, "1.1", "Document Identification & Metadata")
    doc_meta_headers = ["Attribute", "Specification Details"]
    doc_meta_rows = [
        ["Document Title", "Attendify Complete System Analyst Technical & Functional Manual"],
        ["Document Reference ID", "ATT-SAD-2026-V1.1"],
        ["Target Audience", "System Analysts, Technical Leads, Software Engineers, Operations & QA Teams"],
        ["Software Release Baseline", "Version 1.1.0 (Production Architecture Baseline)"],
        ["Publication Date", "November 2026"],
        ["Security Classification", "Confidential — Institutional Operations Reference"],
        ["Platform Compatibility", "Android (API 26+), Flutter Web, Linux Desktop, Render PaaS Hosting"]
    ]
    add_styled_table(doc, doc_meta_headers, doc_meta_rows, [2.2, 4.3])

    add_section_title(doc, "1.2", "Document Purpose & Reader Guidelines")
    add_body_p(doc, "The purpose of this document is to provide a single, authoritative reference for system analysts, auditors, and engineering personnel. It bridges high-level academic administrative requirements with actual low-level implementation details in the Laravel backend and Flutter mobile client. Readers can understand, analyze, verify, or modify system behavior without continually inspecting raw source files.")

    add_section_title(doc, "1.3", "Document Revision History")
    rev_headers = ["Version", "Release Date", "Primary Author / Role", "Summary of Architectural & Functional Changes"]
    rev_rows = [
        ["v1.0.0", "Oct 20, 2026", "Lead Architect", "Initial baseline architecture: Laravel 11 REST API, MySQL DDL schema, 4 fixed RBAC roles, permanent 64-char QR tokens, single active session enforcement, and Flutter AetherUI client."],
        ["v1.0.1", "Nov 12, 2026", "System Analyst Team", "Added granular Audience Targeting (department, course, year level, custom sections) and automated student event assignment."],
        ["v1.0.2", "Nov 15, 2026", "Backend & Mobile Lead", "Implemented resilient Firebase Cloud Messaging (FCM HTTP v1), dedicated notification channel ('attendify_important_v1'), and custom sound chime ('sfxmint_ready_chime_07')."],
        ["v1.0.3", "Nov 15, 2026", "Full-Stack Engineer", "Integrated cross-platform report exports (CSV, XLSX via Maatwebsite, PDF via DomPDF) with specialized Web Blob and Android scoped storage downloaders."],
        ["v1.1.0", "Nov 22, 2026", "Lead System Analyst", "Implemented global reactive Light/Dark/System Default theme system across Web and Android; consolidated production-ready technical manual."]
    ]
    add_styled_table(doc, rev_headers, rev_rows, [0.8, 1.1, 1.5, 3.1])

    # =========================================================================
    # CHAPTER 2: EXECUTIVE SUMMARY
    # =========================================================================
    add_chapter_title(doc, 2, "Executive Summary")

    add_body_p(doc, "Higher education institutions routinely organize hundreds of co-curricular, academic, and cultural events per semester. In typical legacy operational environments, attendance tracking relies on manual paper sign-in sheets, unverified spreadsheets, or fragmented Google Forms. These manual workflows suffer from severe structural liabilities:")
    add_bullet_item(doc, "Vulnerability to Attendance Fraud: Rampant proxy signing and forged signatures undermine institutional compliance and academic integrity.", bold_prefix="1. Fraud & Proxy Scanning: ")
    add_bullet_item(doc, "Delayed Data Processing: Manual tallying and spreadsheet consolidation take days or weeks, preventing real-time attendance verification.", bold_prefix="2. Data Lag & Operational Bottlenecks: ")
    add_bullet_item(doc, "Capacity Mismanagement: Physical event venues overflow or sit underutilized due to the absence of automated waiting list queues.", bold_prefix="3. Inflexible Capacity Allocation: ")
    add_bullet_item(doc, "Audit Failures: Inability to trace who scanned attendance, when check-in occurred, or why attendance status corrections were executed.", bold_prefix="4. Lack of Operational Auditability: ")

    add_body_p(doc, "Attendify solves these institutional challenges through a modern, decoupled client-server architecture engineered for high concurrency, zero data loss, and absolute auditability. The platform bridges a central Laravel 11 REST API backend with a high-performance cross-platform Flutter application.")

    add_callout(doc, "Core Architectural Invariant: In Attendify, the permanent QR code (a cryptographically secure 64-character hexadecimal token) represents the permanent institutional identity of the student; event registrations and attendance rows represent the student's participation in a specific event. Zero Personal Identifiable Information (PII) is ever embedded in the QR payload.", title="Core Architectural Rule", alert_type="tip")

    add_section_title(doc, "2.1", "Key System Innovations")
    add_bullet_item(doc, "Permanent Cryptographic Student QR: Each student receives a unique 64-character hex token generated via 256 bits of cryptographic entropy. Even if intercepted, the QR reveals zero names, student numbers, or emails.", bold_prefix="• Cryptographic Identity Isolation: ")
    add_bullet_item(doc, "Enforced Single Active Session: Logging in on a new device immediately invalidates all previous sessions through active session UUID tracking and Sanctum token revocation.", bold_prefix="• Account Sharing Prevention: ")
    add_bullet_item(doc, "Automated Waiting List & Queue Promotion: Atomic database transactions promote the next waiting-list student immediately upon participant cancellation, ensuring optimal venue utilization.", bold_prefix="• Transactional Queue Promotion: ")
    add_bullet_item(doc, "Comprehensive Audit Trail: Every state mutation—event publishing, attendance check-in, manual correction, or QR reissue—is logged with immutable user, IP, and timestamp records.", bold_prefix="• Universal Accountability: ")
    add_bullet_item(doc, "Tri-Format Institutional Reporting: On-demand generation and instant file downloading of 7 institutional report types in PDF, Excel (.xlsx), and CSV formats.", bold_prefix="• Regulatory & Institutional Reporting: ")

    # =========================================================================
    # CHAPTER 3: INTRODUCTION AND BACKGROUND
    # =========================================================================
    add_chapter_title(doc, 3, "Introduction and Background")

    add_body_p(doc, "Attendify was conceptualized to serve collegiate campuses, polytechnic colleges, and university systems requiring reliable, fast, and secure event attendance management. The project operates under strict institutional guidelines prioritizing student privacy, data integrity, and role separation.")

    add_section_title(doc, "3.1", "Institutional Context & Operational Challenges")
    add_body_p(doc, "Collegiate events span diverse operational types: mandatory department convocations, general student assemblies, elective club seminars, and sports competitions. Managing event entry across multiple physical doors requires rapid verification without network timeouts or barcode scanning lag.")
    add_body_p(doc, "In legacy workflows, staff members stood at entry doors with printed rosters. Students manually signed their names next to printed student IDs. Post-event, student council officers spent 10 to 20 hours transcribing handwritten marks into Microsoft Excel. Inevitably, illegible handwriting, duplicate student entries, and unrecorded walk-ins created inaccurate attendance percentages that skewed institutional compliance reports.")

    add_section_title(doc, "3.2", "System Evolution to Release 1.1")
    add_body_p(doc, "The development lifecycle of Attendify proceeded through structured phases:")
    add_bullet_item(doc, "Phase 1 (Core Foundation): Design of the 13 relational domain tables in MySQL 8.0, establishment of Laravel 11 Sanctum authentication with single-session enforcement, and AetherUI Flutter components.", bold_prefix="• Baseline Construction: ")
    add_bullet_item(doc, "Phase 2 (Lifecycle & Scanner): Implementation of the multi-state event approval engine (draft -> pending_approval -> published) and high-speed camera scanner using mobile_scanner.", bold_prefix="• Operational Core: ")
    add_bullet_item(doc, "Phase 3 (Enterprise Hardening): Integration of granular audience targeting, Firebase Cloud Messaging push notifications, and multi-format report exports.", bold_prefix="• Advanced Enterprise Features: ")
    add_bullet_item(doc, "Phase 4 (Universal Appearance): Implementation of complete reactive Light Mode and Dark Mode system with SharedPreferences local persistence, maintaining Attendify's signature high-contrast black-and-white visual identity.", bold_prefix="• Release 1.1 Finalization: ")

    # =========================================================================
    # CHAPTER 4: SYSTEM PURPOSE, OBJECTIVES, AND SCOPE
    # =========================================================================
    add_chapter_title(doc, 4, "System Purpose, Objectives, and Scope")

    add_section_title(doc, "4.1", "Primary System Purpose")
    add_body_p(doc, "The overarching purpose of Attendify is to automate, secure, and streamline the entire collegiate event lifecycle—from initial organizer drafting and administrative approval to student mobile registration, permanent QR attendance check-in, and institutional report generation.")

    add_section_title(doc, "4.2", "Detailed System Objectives")
    add_bullet_item(doc, "Sub-second verification of student QR codes during high-volume event check-in.", bold_prefix="1. Scanning Velocity: ")
    add_bullet_item(doc, "Zero student PII exposure in physical or digital QR tokens.", bold_prefix="2. Information Privacy: ")
    add_bullet_item(doc, "Single active session enforcement preventing account sharing and proxy scans.", bold_prefix="3. Authentication Rigor: ")
    add_bullet_item(doc, "Strict Role-Based Access Control (RBAC) isolating Administrator, Organizer, Student, and Management privileges.", bold_prefix="4. Separation of Concerns: ")
    add_bullet_item(doc, "Full data auditability with immutable operational activity logs.", bold_prefix="5. Regulatory Compliance: ")
    add_bullet_item(doc, "Multi-platform accessibility across mobile (Android APK) and desktop (Flutter Web).", bold_prefix="6. Ubiquitous Accessibility: ")

    add_section_title(doc, "4.3", "Functional Scope (In-Scope Modules)")
    add_bullet_item(doc, "Authentication & Session Management: Dual Student ID / Email login, Sanctum Bearer tokens, single-session active enforcement.", bold_prefix="• Module 1: ")
    add_bullet_item(doc, "Student Profile Governance: Immutable academic records synchronized from SIS; student discrepancy correction request workflow.", bold_prefix="• Module 2: ")
    add_bullet_item(doc, "Event Lifecycle & Governance: Multi-state approval workflow requiring Administrator sign-off for publishing and cancellation.", bold_prefix="• Module 3: ")
    add_bullet_item(doc, "Audience Targeting & Capacity: Granular department/course/year filtering, automated student assignment, and waiting list promotion.", bold_prefix="• Module 4: ")
    add_bullet_item(doc, "Permanent QR Identity Management: 64-character cryptographic hex tokens with transactional self-service revocation and reissuance.", bold_prefix="• Module 5: ")
    add_bullet_item(doc, "QR Attendance Check-In / Check-Out: Real-time validation, late grace period calculation, walk-in handling, and visual identity verification.", bold_prefix="• Module 6: ")
    add_bullet_item(doc, "Participation Verification & Corrections: Formal attendance correction workflow with mandatory operational justification and audit logging.", bold_prefix="• Module 7: ")
    add_bullet_item(doc, "Multi-Channel Notifications: In-app notification inbox, user preferences, 30-day automated purge, and FCM push notifications.", bold_prefix="• Module 8: ")
    add_bullet_item(doc, "Institutional Reporting & Export: Real-time generation of 7 report categories in PDF, Excel (.xlsx), and CSV formats.", bold_prefix="• Module 9: ")
    add_bullet_item(doc, "Audit Logging: Automatic capture of state-changing operations into an immutable activity_logs relational store.", bold_prefix="• Module 10: ")
    add_bullet_item(doc, "AetherUI & Global Theming: Reactive Light Mode, Dark Mode, and System Default theming with persistent local storage.", bold_prefix="• Module 11: ")

    add_section_title(doc, "4.4", "Out-of-Scope System Boundaries")
    add_callout(doc, "Per Software Requirements Specification (SRS) Section 17 & 33.7, runtime Artificial Intelligence (such as conversational chatbots, automated AI report writers, or third-party LLM APIs) is strictly out of scope for Attendify v1.x. All attendance evaluations, waiting list promotions, and report tallies are strictly deterministic. Furthermore, direct student self-registration and online payment gateways are excluded to prevent institutional data contamination.", title="Scope Boundaries", alert_type="warning")

    # =========================================================================
    # CHAPTER 5: SYSTEM ARCHITECTURE AND TECHNOLOGY STACK
    # =========================================================================
    add_chapter_title(doc, 5, "System Architecture and Technology Stack")

    add_body_p(doc, "Attendify is built upon a decoupled, multi-tier client-server architecture. The client tier never communicates directly with the database; all business logic, validation, transaction boundaries, and state transitions are executed exclusively within the Laravel REST API backend.")

    add_section_title(doc, "5.1", "High-Level Architecture Diagram")
    arch_diagram = (
        "+-----------------------------------------------------------------------------------+\n"
        "|                             CLIENT APPLICATION TIER                               |\n"
        "|  +-----------------------------------------------------------------------------+  |\n"
        "|  |                      FLUTTER CLIENT (Android APK & Web PWA)                 |  |\n"
        "|  |  - AetherUI Design Tokens (Light / Dark Mode)    - PushNotificationService  |  |\n"
        "|  |  - ApiClient (Bearer Token, 401 Session Intercept) - FileDownloader (Web/IO) |  |\n"
        "|  |  - mobile_scanner (Camera QR Decoder)             - RealtimeNotificationSync |  |\n"
        "|  +-----------------------------------------------------------------------------+  |\n"
        "+-----------------------------------------+-----------------------------------------+\n"
        "                                          | HTTPS / REST JSON v1 (Bearer Token)\n"
        "+-----------------------------------------v-----------------------------------------+\n"
        "|                             API GATEWAY & ROUTING TIER                            |\n"
        "|  +-----------------------------------------------------------------------------+  |\n"
        "|  |  routes/api.php: Rate Limiting (throttle:5,1 auth; throttle:60,1 scanner)   |  |\n"
        "|  |  Middleware Pipeline: auth:sanctum -> single.session -> role:{slug}         |  |\n"
        "|  +-----------------------------------------------------------------------------+  |\n"
        "+-----------------------------------------+-----------------------------------------+\n"
        "                                          | Internal Dispatch\n"
        "+-----------------------------------------v-----------------------------------------+\n"
        "|                       BUSINESS LOGIC & APPLICATION SERVICES                       |\n"
        "|  +-----------------------------------------------------------------------------+  |\n"
        "|  |  - AuthController: Single-Session UUID generation & invalidation             |  |\n"
        "|  |  - EventController: State Machine (draft -> pending -> published -> ...)   |  |\n"
        "|  |  - RegistrationController: Transactional capacity check & auto-promotion    |  |\n"
        "|  |  - AttendanceController: Late evaluation, walk-in creation, visual verify   |  |\n"
        "|  |  - NotificationService: Preferences filtering & FCM HTTP v1 dispatch       |  |\n"
        "|  |  - ReportController: DomPDF / Maatwebsite Excel / CSV streaming generation  |  |\n"
        "|  |  - ActivityLog: Immutable event audit logging                               |  |\n"
        "|  +-----------------------------------------------------------------------------+  |\n"
        "+--------------------+---------------------------------------+----------------------+\n"
        "                     |                                       |\n"
        "                     v MySQL / MariaDB (InnoDB)              v Google OAuth2\n"
        "+------------------------------------+      +---------------------------------------+\n"
        "|          DATA STORAGE TIER         |      |       EXTERNAL INTEGRATION TIER       |\n"
        "|  - school_event_attendance DB      |      |  - Firebase Cloud Messaging (FCM v1)  |\n"
        "|  - 13 Relational Domain Tables     |      |  - Google Identity Service Account    |\n"
        "|  - InnoDB ACID Transactions        |      |  - FCM Device Token Registration Pool |\n"
        "+------------------------------------+      +---------------------------------------+\n"
    )
    add_code_block(doc, arch_diagram)

    add_section_title(doc, "5.2", "Comprehensive Technology Stack Specification")
    tech_headers = ["Layer / Component", "Technology Selected", "Version", "Operational Role & Justification"]
    tech_rows = [
        ["Backend Framework", "Laravel Framework", "11.x", "Provides robust routing, Eloquent ORM, middleware pipelines, and enterprise validation."],
        ["Runtime Environment", "PHP", "8.2 / 8.3+", "High-performance server runtime with strict typing and modern asynchronous capabilities."],
        ["API Authentication", "Laravel Sanctum", "4.x", "Lightweight, cryptographically signed API token issuance paired with session UUID checking."],
        ["Relational Database", "MySQL / MariaDB", "8.0+ / 13.x", "ACID-compliant relational store with InnoDB foreign key enforcement and row-level locking."],
        ["Test In-Memory DB", "SQLite", "3.x", "Executes unit and integration test suites in-memory (:memory:) with zero mutation of live data."],
        ["PDF Export Engine", "barryvdh/laravel-dompdf", "3.x", "Renders customized institutional attendance rosters and summary reports via HTML5/CSS3 Blade."],
        ["Excel Export Engine", "maatwebsite/excel", "3.1+", "Generates binary Excel (.xlsx) spreadsheets with styled headers and formula calculations."],
        ["Push Messaging", "Firebase Cloud Messaging", "HTTP v1", "Dispatches low-latency push alerts to registered mobile devices via Google OAuth2 service account."],
        ["Frontend Framework", "Flutter / Dart SDK", "3.47+ / 3.13+", "Cross-platform client compiled natively for Android and Web from a single unified codebase."],
        ["UI Design System", "AetherUI / shadcn_ui", "0.2.x", "Clean, high-contrast black-and-white visual identity with Inter typography and LucideIcons."],
        ["QR Code Scanning", "mobile_scanner", "5.1+", "High-speed camera barcode and QR recognition utilizing native Android CameraX and WebRTC."],
        ["QR Code Generation", "qr_flutter", "4.1+", "Client-side rendering of cryptographic 64-character tokens into crisp, high-contrast QR matrices."]
    ]
    add_styled_table(doc, tech_headers, tech_rows, [1.3, 1.4, 0.9, 2.9])

    # =========================================================================
    # CHAPTER 6: SYSTEM REQUIREMENTS AND DEPENDENCIES
    # =========================================================================
    add_chapter_title(doc, 6, "System Requirements and Dependencies")

    add_section_title(doc, "6.1", "Server Hardware & Operating System Requirements")
    add_body_p(doc, "The Attendify backend can be hosted on standard cloud Virtual Private Servers (VPS), dedicated physical servers, or containerized Platforms as a Service (PaaS) such as Render or AWS ECS.")

    hw_headers = ["Resource Attribute", "Minimum Specification (Dev/Testing)", "Recommended Specification (Production Campus)"]
    hw_rows = [
        ["Processor (CPU)", "1 Core (2.0 GHz x86_64 / ARM64)", "4 Cores (3.0 GHz+ x86_64, e.g., AMD EPYC / Intel Xeon)"],
        ["System Memory (RAM)", "1 GB Available RAM", "8 GB DDR4/DDR5 ECC RAM"],
        ["Storage Capacity", "10 GB SSD / NVMe Storage", "50 GB+ NVMe SSD (High IOPS for concurrent report exports)"],
        ["Network Throughput", "10 Mbps Dedicated Bandwidth", "100 Mbps+ Symmetrical Bandwidth with SSL/TLS termination"],
        ["Host Operating System", "Ubuntu 22.04 LTS / Debian 12 / Windows 10+", "Ubuntu Server 24.04 LTS / Alpine Linux (Dockerized Container)"]
    ]
    add_styled_table(doc, hw_headers, hw_rows, [1.8, 2.3, 2.4])

    add_section_title(doc, "6.2", "Required PHP Extensions & Server Modules")
    add_body_p(doc, "The PHP runtime environment must have the following core extensions compiled and active in php.ini:")
    add_bullet_item(doc, "Required for secure password hashing and random cryptographic token generation.", bold_prefix="• openssl & sodium: ")
    add_bullet_item(doc, "Required for high-performance parameterized relational database communication.", bold_prefix="• pdo & pdo_mysql / pdo_sqlite: ")
    add_bullet_item(doc, "Required for Unicode string handling, JSON serialization, and internationalization.", bold_prefix="• mbstring, ctype & json: ")
    add_bullet_item(doc, "Required for XML parsing and DomPDF institutional document formatting.", bold_prefix="• xml, dom & tokenizer: ")
    add_bullet_item(doc, "Required for Excel file compression and profile avatar manipulation.", bold_prefix="• zip, gd & bcmath: ")

    add_section_title(doc, "6.3", "Client Device & Browser Requirements")
    add_bullet_item(doc, "Requires Android 8.0 (Oreo / API Level 26) or higher. Device must possess a functioning rear camera (minimum 5 MP autofocus) for physical QR attendance scanning.", bold_prefix="• Android Mobile Devices: ")
    add_bullet_item(doc, "Fully supported on Google Chrome (v100+), Mozilla Firefox (v100+), Apple Safari (v15+), and Microsoft Edge (v100+). Requires JavaScript, WebGL, and WebRTC camera permissions.", bold_prefix="• Web Browsers (Desktop/Tablet): ")

    # =========================================================================
    # CHAPTER 7: USER ROLES AND ACCESS PERMISSIONS
    # =========================================================================
    add_chapter_title(doc, 7, "User Roles and Access Permissions")

    add_body_p(doc, "Attendify enforces strict, immutable Role-Based Access Control (RBAC). Roles are permanently mapped to role slugs in the database (roles table) and verified across every API request via the CheckRole middleware.")

    add_section_title(doc, "7.1", "The Four Immutable Roles")
    add_bullet_item(doc, "Role ID 1. Possesses complete administrative authority across all modules. Manages staff and student accounts, approves or rejects event publication and cancellation requests, inspects permanent student QR tokens, broadcasts system-wide announcements, and reviews immutable activity logs.", bold_prefix="1. Administrator (administrator): ")
    add_bullet_item(doc, "Role ID 2. Academic staff, student council officers, and club advisers. Permitted to draft events, submit events for administrative review, request event cancellations, operate the QR camera scanner (check-in and check-out), mark manual attendance with reasons, execute attendance corrections for their assigned events, and export attendance reports.", bold_prefix="2. Event Organizer / Staff (organizer): ")
    add_bullet_item(doc, "Role ID 3. Pre-provisioned institutional student learners. Permitted to authenticate using Student ID number or school email, view their permanent cryptographic QR code, reissue QR tokens if compromised, browse published events, register or join waiting lists, cancel own registrations, view personal attendance history, and submit profile discrepancy correction requests.", bold_prefix="3. Student (student): ")
    add_bullet_item(doc, "Role ID 4. Deans, department chairs, and academic auditors. Strictly Read-Only (RO) monitoring authority. Permitted to observe dashboards, inspect event registries, monitor live attendance tables, and generate/download reports. Prohibited from mutating any data, approving events, scanning attendance, or altering user profiles.", bold_prefix="4. School Management (management): ")

    add_section_title(doc, "7.2", "Comprehensive Role-Permission Matrix")
    matrix_headers = ["Functional Operation / Module", "Administrator", "Organizer", "Student", "Management"]
    matrix_rows = [
        ["Authenticate via ID / Email & Password", "ALLOW", "ALLOW", "ALLOW", "ALLOW"],
        ["View Personal Profile & Settings", "ALLOW", "ALLOW", "ALLOW", "ALLOW"],
        ["Mutate Student Profile Directly", "ALLOW (Admin API)", "DENY", "DENY (403)", "DENY"],
        ["Submit Student Profile Correction Request", "DENY", "DENY", "ALLOW", "DENY"],
        ["Manage System Users & Passwords", "ALLOW", "DENY", "DENY", "DENY"],
        ["Draft & Edit Own Events", "ALLOW", "ALLOW", "DENY", "DENY"],
        ["Submit Event for Approval", "ALLOW", "ALLOW", "DENY", "DENY"],
        ["Approve / Reject Event Publishing", "ALLOW", "DENY", "DENY", "DENY"],
        ["Approve / Reject Event Cancellation", "ALLOW", "DENY", "DENY", "DENY"],
        ["Register / Join Waiting List for Event", "DENY", "DENY", "ALLOW", "DENY"],
        ["Cancel Personal Event Registration", "DENY", "DENY", "ALLOW", "DENY"],
        ["Staff Cancel Student Registration", "ALLOW", "ALLOW", "DENY", "DENY"],
        ["View / Reissue Own Permanent QR", "DENY", "DENY", "ALLOW", "DENY"],
        ["Inspect Student QR Audit History", "ALLOW", "DENY", "DENY", "DENY"],
        ["Administrative Force QR Reissue", "ALLOW", "DENY", "DENY", "DENY"],
        ["Operate QR Attendance Scanner (In/Out)", "ALLOW", "ALLOW", "DENY", "DENY"],
        ["Manual Attendance Marking with Reason", "ALLOW", "ALLOW", "DENY", "DENY"],
        ["Correct Attendance Record with Reason", "ALLOW", "ALLOW", "DENY", "DENY"],
        ["Broadcast System Announcements", "ALLOW", "DENY", "DENY", "DENY"],
        ["View Management / Executive Dashboards", "ALLOW", "DENY", "DENY", "ALLOW (RO)"],
        ["Export Reports (CSV, XLSX, PDF)", "ALLOW", "ALLOW", "DENY", "ALLOW (RO)"],
        ["Inspect System Activity & Audit Logs", "ALLOW", "DENY", "DENY", "DENY"]
    ]
    add_styled_table(doc, matrix_headers, matrix_rows, [2.5, 1.0, 1.0, 1.0, 1.0])

    # =========================================================================
    # CHAPTER 8: AUTHENTICATION AND ACCOUNT MANAGEMENT
    # =========================================================================
    add_chapter_title(doc, 8, "Authentication and Account Management")

    add_section_title(doc, "8.1", "Unified Authentication Mechanics")
    add_body_p(doc, "Attendify utilizes a single, unified authentication gateway located at POST /api/v1/auth/login. This endpoint accepts both staff emails and student identifiers without requiring user role pre-selection. Rate limiting is strictly enforced at 5 attempts per minute per IP address (throttle:5,1) to mitigate brute-force dictionary attacks.")

    add_body_p(doc, "Identifier resolution logic operates as follows:")
    add_bullet_item(doc, "If the incoming 'login' parameter contains an '@' character, the backend queries the users table for a matching email address.", bold_prefix="1. Email Resolution: ")
    add_bullet_item(doc, "If the 'login' parameter does not contain an '@' character, the backend queries the students table matching student_id_number, and subsequently resolves the linked User record via user_id.", bold_prefix="2. Student ID Number Resolution: ")

    add_section_title(doc, "8.2", "Single Active Session Enforcement Architecture")
    add_body_p(doc, "A critical institutional requirement is preventing students or staff from sharing accounts to log in on multiple devices simultaneously. Attendify enforces single active session security via the following multi-step architectural workflow:")

    session_flow = (
        "1. USER CREDENTIALS VALIDATED (POST /api/v1/auth/login)\n"
        "   |\n"
        "   v\n"
        "2. BACKEND REVOKES ALL EXISTING SANCTUM TOKENS FOR THIS USER:\n"
        "   $user->tokens()->delete();\n"
        "   |\n"
        "   v\n"
        "3. GENERATE FRESH CRYPTOGRAPHIC SESSION UUID:\n"
        "   $sessionId = Str::uuid()->toString();\n"
        "   $user->update(['active_session_id' => $sessionId]);\n"
        "   |\n"
        "   v\n"
        "4. ISSUE SANCTUM TOKEN NAMED WITH EMBEDDED SESSION ID:\n"
        "   $token = $user->createToken('session-' . $sessionId)->plainTextToken;\n"
        "   |\n"
        "   v\n"
        "5. ON SUBSEQUENT REQUESTS (EnforceSingleSession Middleware):\n"
        "   - Extracts session UUID from current token name: str_replace('session-', '', $tokenName)\n"
        "   - Compares with users.active_session_id in database.\n"
        "   - IF MISMATCH (User logged in elsewhere):\n"
        "     * Returns HTTP 401 Unauthorized with error_code: 'ERR_SESSION_TERMINATED'\n"
        "   - IF MATCH: Request proceeds to controller.\n"
        "   |\n"
        "   v\n"
        "6. FLUTTER CLIENT API INTERCEPTOR (ApiClient):\n"
        "   - Detects HTTP 401 with 'ERR_SESSION_TERMINATED'.\n"
        "   - Halts polling services (RealtimeNotificationService.stop()).\n"
        "   - Triggers non-dismissible modal: 'Session Terminated on This Device'.\n"
        "   - Clears local storage and redirects user to LoginScreen.\n"
    )
    add_code_block(doc, session_flow)

    add_section_title(doc, "8.3", "Password Management & Account Status Governance")
    add_body_p(doc, "Attendify eliminates public, unverified 'Forgot Password' email reset forms. In collegiate environments, open reset forms are frequent targets of social engineering and denial-of-service email spam.")
    add_bullet_item(doc, "Administrative Password Reset: Administrators reset user passwords on demand via POST /api/v1/admin/users/{id}/reset-password. This operation forces an immediate session termination by setting active_session_id = null and deleting all Sanctum tokens.", bold_prefix="• Administrative Resets: ")
    add_bullet_item(doc, "Account Lifecycle Statuses: Users exist in one of three states: 'pending' (awaiting email verification), 'active' (authorized for normal system operations), or 'inactive' (suspended; all logins and API requests are blocked immediately).", bold_prefix="• Status Lifecycle: ")
