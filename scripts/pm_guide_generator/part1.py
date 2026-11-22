"""
part1.py - Chapters 1 to 5 for Attendify Project Manager Guide.
Covers:
- Chapter 1: Project Overview
- Chapter 2: Project Description
- Chapter 3: Project Stakeholders (with Stakeholder Responsibility Matrix)
- Chapter 4: Project Scope and Deliverables (Backend, Mobile, DB, Docs, Testing, Deployment)
- Chapter 5: System Modules and Features (13 Major Functional Areas)
"""

from .styles import (
    add_chapter_title, add_section_title, add_subsection_title,
    add_body_p, add_bullet_item, add_callout, add_styled_table, add_code_block
)

def add_part1(doc):
    # -------------------------------------------------------------
    # CHAPTER 1: PROJECT OVERVIEW
    # -------------------------------------------------------------
    add_chapter_title(doc, "1", "Project Overview")

    add_section_title(doc, "1.1", "Project Identification & Background")
    add_body_p(doc, "Attendify is an enterprise-grade School Event Registration and QR-Based Attendance Management System designed to modernize, secure, and automate campus-wide extracurricular and academic event operations.", bold_prefix="System Identity: ")
    add_body_p(doc, "Traditionally, institutional school events rely heavily on manual sign-in sheets, paper registration clipboards, and ad-hoc post-event data entry. In educational environments hosting hundreds or thousands of students across multiple colleges and degree programs, this manual approach results in massive operational inefficiencies, long check-in queues, high clerical error rates, fraudulent proxy attendance ('buddy punching'), and severe delays in publishing participation records required for co-curricular transcripts and clearances.", bold_prefix="Institutional Context: ")
    add_body_p(doc, "Attendify addresses these structural challenges by replacing manual paper workflows with an integrated digital ecosystem consisting of a secure central Laravel REST API backend, a responsive cross-platform Flutter client application (deployable as both a desktop/mobile web portal and an Android native APK), and a permanent cryptographic QR code identity infrastructure.", bold_prefix="Strategic Solution: ")

    add_section_title(doc, "1.2", "Problem Statement")
    add_body_p(doc, "Prior to the implementation of Attendify, the institution faced four major operational bottlenecks:")
    add_bullet_item(doc, "Physical queues at event entrances frequently caused 15 to 45-minute entry delays, disrupting event schedules and overwhelming event staff.", bold_prefix="Queue Bottlenecks: ")
    add_bullet_item(doc, "Students regularly signed physical sheets on behalf of absent peers, compromising the integrity of institutional attendance and clearance audits.", bold_prefix="Proxy Sign-Ins & Fraud: ")
    add_bullet_item(doc, "Organizers had no real-time mechanism to track hall occupancy, evaluate waiting list promotions dynamically, or cap room capacity safely.", bold_prefix="Capacity & Safety Violations: ")
    add_bullet_item(doc, "Aggregating attendance data across faculties required weeks of manual spreadsheet consolidation, creating friction during graduation clearances and scholarship evaluations.", bold_prefix="Data Lag & Reporting Delays: ")

    add_section_title(doc, "1.3", "Project Objectives")
    add_body_p(doc, "The primary strategic and technical objectives established for the Attendify project include:")
    add_bullet_item(doc, "Sub-second verification and recording of student arrivals at event entrances using camera-based QR code scanning.", bold_prefix="Objective 1 (Throughput): ")
    add_bullet_item(doc, "Elimination of personal data leakage in QR codes by issuing permanent 64-character cryptographic tokens verified strictly against centralized server records.", bold_prefix="Objective 2 (Identity & Privacy): ")
    add_bullet_item(doc, "Single active session enforcement, role-based access control (RBAC), and immutable audit logging for all mutations and attendance corrections.", bold_prefix="Objective 3 (Governance & Security): ")
    add_bullet_item(doc, "Targeted event broadcasting, automatic registration assignment by college or year level, and automated waiting-list FIFO promotion upon cancellations.", bold_prefix="Objective 4 (Automation): ")
    add_bullet_item(doc, "Unified responsive web access for administrators and organizers alongside native mobile capabilities for on-the-go scanning and student self-service.", bold_prefix="Objective 5 (Cross-Platform Usability): ")

    add_section_title(doc, "1.4", "Target User Communities")
    add_body_p(doc, "Attendify is architected to serve four distinct institutional stakeholder groups across the academic hierarchy:")
    add_bullet_item(doc, "Central IT and Student Affairs leaders who govern user provisioning, global event approvals, role assignments, audit investigations, and system integrity.", bold_prefix="1. Administrators: ")
    add_bullet_item(doc, "Faculty advisors, student council officers, and departmental staff who create events, define targeting criteria, scan student QR tokens, verify check-ins, and export event rosters.", bold_prefix="2. Event Organizers: ")
    add_bullet_item(doc, "Enrolled students who access their permanent institutional QR code, discover targeted events, register with real-time capacity feedback, and track their participation history.", bold_prefix="3. Students: ")
    add_bullet_item(doc, "Deans, Department Chairs, and Executive Directors who require high-level, read-only analytics, compliance oversight, and institutional participation reporting.", bold_prefix="4. School Management: ")

    add_section_title(doc, "1.5", "Project Scope Boundaries")
    add_body_p(doc, "To ensure on-time delivery and operational stability, the project boundaries are strictly delineated as follows:")
    add_bullet_item(doc, "User authentication via email or numeric Student ID; single-session enforcement; permanent student QR lifecycle; event proposal and approval governance; dynamic capacity tracking; FIFO waiting list queues; camera-based check-in/check-out; attendance correction audit trails; Firebase Cloud Messaging push notices; 7 report export formats (CSV, XLSX, PDF); and full Light/Dark/System Default theming.", bold_prefix="In-Scope Capabilities: ")
    add_bullet_item(doc, "Self-signup for students (all student accounts are pre-provisioned from school rosters); direct client database connections (strictly decoupled via REST); and runtime artificial intelligence (LLM chatbots or generative summaries are explicitly excluded per SRS v1.1).", bold_prefix="Explicitly Excluded Capabilities: ")

    add_callout(doc, "Attendify operates under a strict Zero Client-Database Exposure policy. The Flutter application interacts exclusively with the Laravel REST API backend over TLS. The database is never exposed directly to external networks or client applications.", title="Architectural Invariant", alert_type="note")

    # -------------------------------------------------------------
    # CHAPTER 2: PROJECT DESCRIPTION
    # -------------------------------------------------------------
    add_chapter_title(doc, "2", "Project Description & Architectural Mechanism")

    add_section_title(doc, "2.1", "How Attendify Works")
    add_body_p(doc, "The Attendify operational lifecycle revolves around the decoupling of permanent student identity from transient event participation records. Every student admitted to the institution is assigned a single active, 64-character hexadecimal cryptographic QR token upon account provisioning. This QR code never encodes the student's name, email, or student number; it is an opaque bearer pointer stored in the central database.", bold_prefix="Operational Mechanism: ")
    add_body_p(doc, "When an event organizer creates an event, they specify targeting criteria (such as College of Computer Studies, 3rd Year students). When published, eligible students automatically see the event on their personal dashboard and calendar. Students register with one tap, or are automatically placed on a FIFO waiting list if hall capacity is reached.", bold_prefix="Event Registration Flow: ")
    add_body_p(doc, "At the venue door, the student presents their permanent QR code on their smartphone (or as a printed physical badge). The organizer scans the QR code using the Attendify app camera. The app dispatches an authenticated REST request to the server, which validates the token, verifies event registration, determines late arrival against the event grace period, records the attendance timestamp, and broadcasts real-time dashboard updates.", bold_prefix="Live Scanning & Validation: ")

    add_section_title(doc, "2.2", "Main System Modules")
    add_body_p(doc, "Attendify is organized into modular functional subsystems across both backend and client tiers:")
    add_bullet_item(doc, "Sanctum token issuance, single-session UUID validation, credential resets, and session revocation.", bold_prefix="1. Security & Identity Engine: ")
    add_bullet_item(doc, "Drafting, administrative approval workflow, targeting assignment, room capacity, and cancellation reviews.", bold_prefix="2. Event Governance Engine: ")
    add_bullet_item(doc, "Camera-driven token ingestion, sub-second backend matching, grace period calculation, and walk-in handling.", bold_prefix="3. QR Attendance & Scanning Engine: ")
    add_bullet_item(doc, "Role-based dashboards, unified notifications inbox, and synchronized Light/Dark/System Default theming.", bold_prefix="4. User Experience & Adaptive UI: ")
    add_bullet_item(doc, "Summary analytics, attendance corrections with mandatory reason logging, and multi-format exports.", bold_prefix="5. Reporting & Audit Subsystem: ")

    add_section_title(doc, "2.3", "Platform Overview: Web Application & Native Android APK")
    add_body_p(doc, "Attendify leverages Flutter's cross-compilation toolchain to maintain a single unified codebase for dual target platforms:")
    add_bullet_item(doc, "Hosted on cloud infrastructure (Render) and served directly from the backend public distribution directory. Provides comprehensive administrative tables, wide-screen event management, bulk export tools, and responsive layouts for desktop and mobile browsers.", bold_prefix="Flutter Web Portal: ")
    add_bullet_item(doc, "Compiled via automated GitHub Actions CI/CD pipeline into release APK packages (`app-release.apk`). Provides hardware camera scanning via `mobile_scanner`, hardware vibration/haptic feedback, and background push notifications via Firebase Cloud Messaging.", bold_prefix="Native Android Mobile APK: ")

    # -------------------------------------------------------------
    # CHAPTER 3: PROJECT STAKEHOLDERS
    # -------------------------------------------------------------
    add_chapter_title(doc, "3", "Project Stakeholders & Responsibility Matrix")

    add_section_title(doc, "3.1", "Stakeholder Profiles & Governance Roles")
    add_body_p(doc, "Successful implementation, adoption, and ongoing maintenance of Attendify depends on clear division of responsibilities across administrative, technical, and operational teams:")

    add_bullet_item(doc, "Maintains project schedule, monitors milestone delivery, manages risk registers, coordinates cross-team communication, and controls change requests.", bold_prefix="Project Manager (PM): ")
    add_bullet_item(doc, "Maintains functional requirements, verifies compliance with SRS v1.1, validates API contracts, models workflows, and ensures architectural consistency.", bold_prefix="System Analyst (SA): ")
    add_bullet_item(doc, "Implement backend REST endpoints, database migrations, Sanctum security, business logic, Flutter UI screens, and client state controllers.", bold_prefix="Software Developers (Backend & Mobile): ")
    add_bullet_item(doc, "Execute automated test suites (PHPUnit and Flutter test), perform regression testing, validate cross-browser web builds, and verify physical APK device behavior.", bold_prefix="Quality Assurance & Testers: ")
    add_bullet_item(doc, "Manage institutional master data, approve event proposals, handle user account suspensions, inspect QR tokens, and review system audit trails.", bold_prefix="System Administrators: ")
    add_bullet_item(doc, "Propose academic/extracurricular events, scan student QR badges at venue entrances, perform attendance corrections with documented justification, and download rosters.", bold_prefix="Event Organizers & Departmental Staff: ")
    add_bullet_item(doc, "Pre-provisioned institutional learners who access their personal QR badge, register for campus events, receive reminders, and monitor attendance records.", bold_prefix="Enrolled Students: ")
    add_bullet_item(doc, "Deans and institutional executives who review aggregate attendance analytics, participation trends, and institutional compliance reports (strictly Read-Only).", bold_prefix="School Management / Leadership: ")

    add_section_title(doc, "3.2", "Stakeholder Responsibility Matrix (RACI)")
    add_body_p(doc, "The RACI matrix below defines the governance level for all critical project lifecycle activities (R = Responsible, A = Accountable, C = Consulted, I = Informed):")

    raci_headers = ["Project Lifecycle Activity", "PM", "SA", "Dev", "QA", "Admin", "Org", "Mgmt"]
    raci_rows = [
        ["Requirements Baseline & Scope Control", "A", "R", "C", "C", "C", "I", "I"],
        ["Database Schema & Migration Authoring", "I", "C", "R", "C", "I", "I", "I"],
        ["Backend REST API Implementation", "I", "C", "R", "C", "I", "I", "I"],
        ["Flutter Client Application Development", "I", "C", "R", "C", "I", "I", "I"],
        ["Automated Testing (PHPUnit & Flutter)", "I", "I", "R", "A", "I", "I", "I"],
        ["Event Proposal & Publishing Approval", "I", "I", "I", "I", "A", "R", "I"],
        ["Venue QR Check-In / Check-Out", "I", "I", "I", "I", "I", "R", "I"],
        ["Manual Attendance Correction & Audit", "I", "I", "I", "I", "A", "R", "I"],
        ["Production Deployment & Server Hosting", "A", "C", "R", "C", "C", "I", "I"],
        ["Post-Deployment Operations & Support", "A", "C", "C", "I", "R", "R", "I"]
    ]
    add_styled_table(doc, raci_headers, raci_rows, col_widths=[2.0, 0.6, 0.6, 0.6, 0.6, 0.7, 0.7, 0.7])

    # -------------------------------------------------------------
    # CHAPTER 4: PROJECT SCOPE AND DELIVERABLES
    # -------------------------------------------------------------
    add_chapter_title(doc, "4", "Project Scope & Deliverable Verification Matrix")

    add_section_title(doc, "4.1", "Standardized Scope Status Classification")
    add_body_p(doc, "All deliverables in the Attendify project are tracked against standardized status designations:")
    add_bullet_item(doc, "The component is fully authored, passing automated tests, and integrated into active builds.", bold_prefix="Implemented: ")
    add_bullet_item(doc, "Core backend or frontend code exists, but secondary flows or edge validations remain underway.", bold_prefix="Partially Implemented: ")
    add_bullet_item(doc, "Scheduled for future sprint execution; architectural specifications completed.", bold_prefix="Pending: ")
    add_bullet_item(doc, "Code authored and deployed, undergoing formal QA test cases or staging verification.", bold_prefix="Under Testing: ")
    add_bullet_item(doc, "Requires live multi-user or physical carrier network testing in production conditions.", bold_prefix="Unverified: ")
    add_bullet_item(doc, "Impeded by an external dependency, infrastructure limitation, or blocking defect.", bold_prefix="Blocked: ")

    add_section_title(doc, "4.2", "Comprehensive Deliverables Matrix")
    add_body_p(doc, "The following table provides the Project Manager with an exhaustive catalog of all subsystem deliverables:")

    deliv_headers = ["Subsystem", "Deliverable Name / Description", "Scope Category", "Current Status"]
    deliv_rows = [
        ["Backend", "Sanctum Token & Single Active Session Middleware", "Core Security", "Implemented"],
        ["Backend", "Permanent 64-char QR Token Issuance & Revocation", "Identity Engine", "Implemented"],
        ["Backend", "Event Proposal, Approval & Cancellation Lifecycle", "Event Engine", "Implemented"],
        ["Backend", "Dynamic Capacity & FIFO Waiting List Queue Engine", "Registration", "Implemented"],
        ["Backend", "Sub-second QR Check-in/Out with Late Grace Logic", "Attendance", "Implemented"],
        ["Backend", "Mandatory Reason Attendance Correction & Activity Log", "Audit Engine", "Implemented"],
        ["Backend", "FCM Push Notification Dispatch Service (HTTP v1)", "Notifications", "Implemented"],
        ["Backend", "30-Day Notification Retention & Scheduled Purge", "Maintenance", "Implemented"],
        ["Backend", "7 Multi-Format Report Exporters (CSV, XLSX, PDF)", "Reporting", "Implemented"],
        ["Database", "MySQL 8.0 DDL & 13 Idempotent Laravel Migrations", "Data Schema", "Implemented"],
        ["Database", "Production Seeders (Roles, Departments, Test Users)", "Data Seeding", "Implemented"],
        ["Mobile", "AetherUI Design Tokens & Light/Dark/System Themes", "Design System", "Implemented"],
        ["Mobile", "Top Navigation Bar Theme Toggle & Profile Header", "Navigation", "Implemented"],
        ["Mobile", "Role-Based Adaptive AppShell Navigation (20 Screens)", "UI Shell", "Implemented"],
        ["Mobile", "Camera-Based Live QR Scanner with Audio/Haptic Feedback", "Hardware UI", "Implemented"],
        ["Mobile", "Permanent Student QR Badge Display & Reissue Screen", "Student UI", "Implemented"],
        ["Mobile", "In-App Notification Inbox & Preferences Screen", "Notifications", "Implemented"],
        ["Mobile", "Settings Screen with Tri-State Theme Selector", "Settings UI", "Implemented"],
        ["Mobile", "Background FCM Push Token Registration on Android", "Push Messaging", "Under Testing"],
        ["Testing", "117 Automated Backend PHPUnit Tests on SQLite :memory:", "Backend QA", "Implemented"],
        ["Testing", "202 Automated Flutter Widget and Unit Tests", "Mobile QA", "Implemented"],
        ["Deployment", "Render Cloud Hosting for Web App and REST API", "Infrastructure", "Implemented"],
        ["Deployment", "GitHub Actions CI/CD Android APK Build Pipeline", "Build Pipeline", "Implemented"],
        ["Documentation", "Software Requirements Specification (SRS v1.1)", "Governance", "Implemented"],
        ["Documentation", "System Architecture & Database Design DDL", "Architecture", "Implemented"],
        ["Documentation", "REST API v1 Specification & openapi.yaml", "API Contract", "Implemented"],
        ["Documentation", "Complete System Analyst Technical Manual", "Documentation", "Implemented"],
        ["Documentation", "Complete Project Manager Operational Guide", "Documentation", "Implemented"]
    ]
    add_styled_table(doc, deliv_headers, deliv_rows, col_widths=[1.1, 2.8, 1.4, 1.2])

    # -------------------------------------------------------------
    # CHAPTER 5: SYSTEM MODULES AND FEATURES
    # -------------------------------------------------------------
    add_chapter_title(doc, "5", "System Modules & Functional Specifications")

    add_section_title(doc, "5.1", "Overview of Functional Architecture")
    add_body_p(doc, "This chapter explains every major module of the Attendify system in non-technical managerial language. For each module, project leadership can review the operational purpose, authorized user communities, expected behavior, technical dependencies, current implementation status, and formal acceptance criteria.")

    modules_data = [
        {
            "name": "User Authentication & Single Active Session Management",
            "purpose": "Provide secure identity verification for all institutional users while preventing concurrent credential sharing and unauthorized account proliferation.",
            "users": "Administrators, Organizers, Students, and School Management.",
            "behavior": "Users authenticate using their institutional email or numeric Student ID and password. Upon successful validation, the system generates a Sanctum personal access token bound to a newly minted session UUID (`users.active_session_id`). Any preexisting active session token for that account is revoked immediately. If a student logs in on a second device, the primary device is automatically logged out with a 401 session expiration warning.",
            "deps": "Laravel Sanctum, `EnsureSingleActiveSession` middleware, Flutter `ApiClient` network interceptor.",
            "status": "Implemented",
            "criteria": "Single session enforced across devices; previous tokens revoked upon fresh login; passwords hashed using Bcrypt; inactive sessions timed out appropriately."
        },
        {
            "name": "Student Profile & Academic Data Management",
            "purpose": "Maintain institutional student academic records (college, degree program, year level) required for audience targeting and attendance attribution.",
            "users": "Students (view only), Administrators (full management).",
            "behavior": "Student profiles are synchronized from institutional databases or created via administrator provisioning. Self-service account registration is disabled to prevent student identity spoofing. Students can review their academic details and contact information within their profile view but cannot unilaterally modify their degree or college attribution.",
            "deps": "Database tables `users` and `student_profiles`, foreign key cascade constraints.",
            "status": "Implemented",
            "criteria": "Students can view profile data; administrators can update student department/year; self-registration is permanently blocked."
        },
        {
            "name": "Event Lifecycle & Administrative Approval Governance",
            "purpose": "Govern event proposals from creation to completion, ensuring institutional oversight before campus announcements are published.",
            "users": "Organizers (create/edit/submit), Administrators (review/approve/reject/cancel).",
            "behavior": "Organizers draft events with title, venue, start/end dates, grace periods, capacity limits, and targeting criteria. The event enters `draft` status. The organizer submits the event, transitioning it to `pending_approval`. Only an Administrator can approve publishing (`published`). If an organizer must cancel a published event, they submit a cancellation request with justification, which an Administrator must approve before the event transitions to `cancelled` and notification blasts are dispatched.",
            "deps": "Database table `events`, `EventStatus` enum state machine, notification services.",
            "status": "Implemented",
            "criteria": "Strict state machine validation; unauthorized role cannot publish; cancellations require administrative approval."
        },
        {
            "name": "Event Audience Targeting & Automatic Eligibility Assignment",
            "purpose": "Direct campus events to specific student demographics (by college, department, or year level) to avoid alert fatigue and ensure relevant participation.",
            "users": "Organizers (configure), Students (discover targeted events).",
            "behavior": "When an organizer creates an event, they specify target criteria: All Students, specific Colleges, or specific Year Levels (1st through 5th year). When published, the backend queries enrolled student profiles matching the criteria and generates targeted calendar views and automated event discovery feeds.",
            "deps": "Database tables `events`, `departments`, `student_profiles`.",
            "status": "Implemented",
            "criteria": "Targeted students see relevant events; ineligible students are prevented from registering unless designated as open-invitation."
        },
        {
            "name": "Event Calendar & Interactive Dashboards",
            "purpose": "Provide visual scheduling, date filtering, and real-time operational status across upcoming, ongoing, and completed campus events.",
            "users": "All user roles (tailored to role permissions).",
            "behavior": "Displays a synchronized calendar widget and chronological event cards. Users can filter by month, week, or event status. Tapping an event reveals location details, start/end times, available seats, and registration status.",
            "deps": "Flutter `EventCalendarScreen`, REST API `/api/v1/events` endpoint.",
            "status": "Implemented",
            "criteria": "Calendar dates accurately highlight scheduled events; role-appropriate actions display on event selection."
        },
        {
            "name": "Permanent Student QR Code Identity Engine",
            "purpose": "Provide a secure, permanent, contactless student identifier for venue check-ins without exposing personal identity in the barcode.",
            "users": "Students (present QR / request reissue), Organizers (scan QR), Administrators (inspect / revoke).",
            "behavior": "Each student is issued a permanent 64-character hexadecimal random token upon account activation. The QR code displays cleanly in the student app. The token contains zero embedded personal information. If a student loses their phone or suspects credential compromise, they can request a QR reissue; the backend atomically revokes all previous tokens and issues a fresh token inside a database transaction.",
            "deps": "Database table `student_qrs`, `bin2hex(random_bytes(32))`, cryptographic generator.",
            "status": "Implemented",
            "criteria": "QR token is 64 hex characters; no PII embedded; previous tokens revoked upon reissue; sub-second token lookup."
        },
        {
            "name": "QR-Based Attendance & Live Venue Scanning Engine",
            "purpose": "Enable fast, reliable attendance check-in and check-out at venue doors using device cameras, eliminating manual paperwork.",
            "users": "Organizers and Administrators.",
            "behavior": "Event staff open the scanner within Attendify. The camera reads the student's permanent QR token. The system verifies that the event is `published` or `ongoing`, confirms the student is registered, checks whether check-in or check-out is active, evaluates late arrival against the event grace period, records the attendance record, and sounds an audible/haptic confirmation.",
            "deps": "Flutter `mobile_scanner` package, backend `AttendanceController::scan` endpoint.",
            "status": "Implemented",
            "criteria": "Scanning processes in under 1 second; duplicate scans within the same session are rejected; late arrivals automatically flagged."
        },
        {
            "name": "Dynamic Capacity Management & FIFO Waiting List Queue",
            "purpose": "Prevent venue overcrowding and automate seat allocation when registered students cancel.",
            "users": "Students (register/cancel), Organizers (monitor capacity).",
            "behavior": "Events define a maximum capacity limit. Once registrations equal capacity, subsequent registrants are automatically placed on a First-In, First-Out (FIFO) waiting list with an assigned queue position. If a registered student cancels, the system automatically promotes the student at waiting list position 1 to `registered` inside a database transaction and decrements remaining queue positions.",
            "deps": "Database table `event_registrations`, atomic database transactions.",
            "status": "Implemented",
            "criteria": "Registrations capped at capacity; queue positions maintained accurately; automated promotion occurs instantly upon cancellation."
        },
        {
            "name": "Attendance Records, Manual Corrections & Audit Trail",
            "purpose": "Maintain an immutable, verifiable ledger of student attendance with mandatory justification for any manual adjustments.",
            "users": "Organizers (request/correct own events), Administrators (audit/correct all).",
            "behavior": "Attendance records store check-in/out timestamps, arrival status (present, late, excused, walk_in), and device info. If an organizer must manually adjust a record (e.g., student forgot phone), they must supply a mandatory reason text. The system records the adjustment in `attendance_corrections` and logs an entry in `activity_logs`.",
            "deps": "Database tables `attendances`, `attendance_corrections`, `activity_logs`.",
            "status": "Implemented",
            "criteria": "Mandatory reason required for correction; original and new status preserved; correction actor logged permanently."
        },
        {
            "name": "Notifications & Campus Announcements",
            "purpose": "Broadcast urgent event notices, schedule alterations, room changes, and registration confirmations across web and mobile.",
            "users": "All user roles (Organizers create announcements; Students/Staff receive).",
            "behavior": "Organizers post announcements linked to events. Critical notices (event cancellations, attendance confirmations) are dispatched immediately. Notifications appear in the in-app inbox and can trigger push notifications.",
            "deps": "Database tables `notifications`, `announcements`, `notification_preferences`.",
            "status": "Implemented",
            "criteria": "Announcements broadcast accurately; in-app notification count updates; 30-day retention policy purges expired notices."
        },
        {
            "name": "Firebase Cloud Messaging (FCM) Push Subsystem",
            "purpose": "Deliver real-time mobile push notifications to student devices even when the Attendify application is closed.",
            "users": "Students and Organizers.",
            "behavior": "Upon native Android app launch, the device registers an FCM registration token stored in `fcm_tokens`. When critical events occur, the backend dispatches HTTP v1 push notifications to Google FCM servers for immediate device alerting.",
            "deps": "Firebase Admin SDK / HTTP v1 REST endpoint, Google Service Account credentials.",
            "status": "Under Testing",
            "criteria": "Token registration succeeds; HTTP v1 payload dispatched by backend; physical device carrier delivery verified."
        },
        {
            "name": "Institutional Reports & Multi-Format Data Export",
            "purpose": "Empower academic leaders and staff with comprehensive attendance summaries, participation audits, and clearance reports.",
            "users": "Organizers (own events), Administrators (all events), School Management (read-only analytics).",
            "behavior": "Users can generate 7 distinct report types: Event Attendance Summary, Detailed Attendee Roster, Student Participation History, College Participation Metrics, Absentee Analysis, Event Capacity Utilization, and Audit Correction Log. Reports export instantly in CSV, Microsoft Excel (XLSX), or PDF formats.",
            "deps": "Laravel Excel / PhpSpreadsheet, DOMPDF / Barryvdh PDF, REST `/api/v1/reports/*`.",
            "status": "Implemented",
            "criteria": "Accurate calculation of attendance percentages; instant download in CSV, XLSX, and PDF; read-only role restrictions enforced."
        },
        {
            "name": "User Roles, Permissions & Activity Audit Logging",
            "purpose": "Enforce strict Role-Based Access Control (RBAC) across all operations and log state-changing mutations for forensic compliance.",
            "users": "Administrators (inspect all logs), All Roles (governed by RBAC).",
            "behavior": "Every API endpoint is protected by role-checking middleware. State-changing actions (logins, event publications, cancellations, manual corrections, QR reissues) automatically write to `activity_logs` with actor ID, IP address, user agent, module, and JSON before/after snapshots.",
            "deps": "Database tables `roles`, `role_user`, `activity_logs`, `ActivityLog` model.",
            "status": "Implemented",
            "criteria": "Management role restricted to Read-Only; unauthorized role mutations return 403 Forbidden; all sensitive operations logged."
        }
    ]

    for idx, mod in enumerate(modules_data, 1):
        add_subsection_title(doc, f"5.{idx}", mod["name"])
        add_body_p(doc, mod["purpose"], bold_prefix="Operational Purpose: ")
        add_body_p(doc, mod["users"], bold_prefix="Authorized User Roles: ")
        add_body_p(doc, mod["behavior"], bold_prefix="Expected System Behavior: ")
        add_body_p(doc, mod["deps"], bold_prefix="Technical Dependencies: ")
        add_body_p(doc, mod["status"], bold_prefix="Current Implementation Status: ")
        add_body_p(doc, mod["criteria"], bold_prefix="Managerial Acceptance Criteria: ")
