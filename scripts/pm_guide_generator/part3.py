"""
part3.py - Chapters 11 to 15 for Attendify Project Manager Guide.
Covers:
- Chapter 11: Quality Assurance & Testing (Strategy, Verification Evidence, Module Criteria)
- Chapter 12: Deployment & Release Management (Render Hosting, GitHub Actions APK, Rollback)
- Chapter 13: Communication & Team Coordination (Protocols, Cadence, Meeting Template)
- Chapter 14: Change Management (Formal Workflow, Evaluation, Change Request Template)
- Chapter 15: Project Performance Evaluation (KPIs, Pass Rates, Deployment Health)
"""

from .styles import (
    add_chapter_title, add_section_title, add_subsection_title,
    add_body_p, add_bullet_item, add_callout, add_styled_table, add_code_block
)

def add_part3(doc):
    # -------------------------------------------------------------
    # CHAPTER 11: QUALITY ASSURANCE AND TESTING
    # -------------------------------------------------------------
    add_chapter_title(doc, "11", "Quality Assurance & Multi-Tier Testing Strategy")

    add_section_title(doc, "11.1", "Multi-Tier Testing Architecture")
    add_body_p(doc, "Quality assurance for Attendify is built upon a multi-layered testing pyramid designed to catch defects at the lowest possible cost and latency. The testing strategy integrates automated unit tests, widget interaction tests, mock service tests, API endpoint validations, and end-to-end regression runs.", bold_prefix="Testing Philosophy: ")
    add_bullet_item(doc, "Validates business rules, state transitions, cryptographic generation, and database interactions in pure isolation.", bold_prefix="1. Backend Unit & Feature Tests: ")
    add_bullet_item(doc, "Validates widget layout, user interaction, theme switching, form validation, and state controllers in the Flutter engine without requiring a physical device.", bold_prefix="2. Flutter Widget & Unit Tests: ")
    add_bullet_item(doc, "Validates the HTTP contract between Flutter's ApiClient and Laravel's REST controllers, ensuring consistent request envelopes and error handling.", bold_prefix="3. API Integration Contract Testing: ")
    add_bullet_item(doc, "Validates complete user journeys (e.g., student discovers event, registers, organizer scans QR token, attendance is recorded, report is generated).", bold_prefix="4. End-to-End User Acceptance Testing (UAT): ")

    add_section_title(doc, "11.2", "Current Verification Evidence & Test Metrics")
    add_body_p(doc, "Prior to tagging Release 1.1, both backend and mobile test suites were executed in full. The results provide empirical evidence of production readiness:", bold_prefix="Empirical Test Results: ")

    qa_summary_headers = ["Testing Suite", "Framework / Harness", "Tests Executed", "Assertions", "Pass Rate", "Status"]
    qa_summary_rows = [
        ["Backend API & Feature Tests", "PHPUnit 11 (SQLite :memory:)", "117 tests", "600+ assertions", "100.0%", "PASSING (Green)"],
        ["Mobile Unit & Widget Tests", "Flutter Test Harness", "202 tests", "450+ assertions", "100.0%", "PASSING (Green)"],
        ["Theme Switching Validation", "Automated Widget Verification", "18 tests", "36 assertions", "100.0%", "PASSING (Green)"],
        ["Single Session Enforcement", "PHPUnit Session Interceptor", "12 tests", "48 assertions", "100.0%", "PASSING (Green)"],
        ["Total Verification Baseline", "Combined Test Suites", "319 tests", "1,050+ assertions", "100.0%", "PASSING (Green)"]
    ]
    add_styled_table(doc, qa_summary_headers, qa_summary_rows, col_widths=[1.5, 1.4, 0.9, 0.9, 0.8, 1.0])

    add_callout(doc, "Backend tests execute strictly against an in-memory SQLite database ('DB_CONNECTION=sqlite', 'DB_DATABASE=:memory:'). This prevents test suites from modifying, mutating, or wiping local development MySQL data or staging servers.", title="Testing Safety Constraint", alert_type="note")

    add_section_title(doc, "11.3", "Module-Specific Acceptance Criteria")
    add_body_p(doc, "To verify operational readiness across the system, the QA lead and Project Manager enforce the following acceptance criteria per subsystem:")
    add_bullet_item(doc, "Issuing fresh session token automatically revokes previous active session; 401 response code returned upon invalid token; password reset enforces Bcrypt hashing.", bold_prefix="Authentication & RBAC: ")
    add_bullet_item(doc, "Student cannot register if event capacity is full; placed on FIFO waiting list; cancellation promotes waiting list position 1; duplicate registration returns error.", bold_prefix="Event Registration & Waiting List: ")
    add_bullet_item(doc, "Scanning valid QR code returns 200 with student details; scan after event start + grace period flags 'late'; duplicate scan returns 409 conflict; scanner latency under 1,000ms.", bold_prefix="QR Attendance Scanning: ")
    add_bullet_item(doc, "Toggling theme between Light and Dark immediately updates colors across all 20 screens; preference persists across app restart and logout; contrast meets WCAG AA standards.", bold_prefix="Theme & Visual Consistency: ")

    # -------------------------------------------------------------
    # CHAPTER 12: DEPLOYMENT AND RELEASE MANAGEMENT
    # -------------------------------------------------------------
    add_chapter_title(doc, "12", "Deployment Architecture & Release Management")

    add_section_title(doc, "12.1", "Production Hosting Architecture")
    add_body_p(doc, "Attendify operates on a cloud-hosted modern deployment pipeline designed for high availability, security, and straightforward administrative maintenance:", bold_prefix="Hosting Overview: ")
    add_bullet_item(doc, "The Laravel backend application and pre-compiled Flutter Web production assets are deployed to Render. The web server listens on HTTPS and serves the Flutter single-page application directly from the public web root, while routing all REST requests to the '/api/v1/*' routes.", bold_prefix="Render Web Service: ")
    add_bullet_item(doc, "Relational data is stored in a managed MySQL 8.0 / MariaDB relational database. All schema changes are applied strictly through idempotent Laravel migrations.", bold_prefix="Relational Database: ")
    add_bullet_item(doc, "Client APK packages for Android devices are built automatically via GitHub Actions upon git pushes to the main branch and distributed directly to organizers and students.", bold_prefix="Android APK CI/CD: ")

    add_section_title(doc, "12.2", "Environment Configuration & Secret Management")
    add_body_p(doc, "Environment-specific settings are decoupled from source code through environment variables managed in Render's dashboard and local '.env' configurations:", bold_prefix="Secret Governance: ")
    add_bullet_item(doc, "Production database credentials (host, port, database, username, password).", bold_prefix="Database Connection: ")
    add_bullet_item(doc, "Base URL pointing to the active API endpoint ('https://attendify-fugh.onrender.com/api/v1').", bold_prefix="API Endpoint URL: ")
    add_bullet_item(doc, "Path to the Google Cloud Service Account JSON key for HTTP v1 push dispatch.", bold_prefix="FCM Service Credentials: ")
    add_bullet_item(doc, "Application encryption key ('APP_KEY') used for token signing and password hashing.", bold_prefix="Cryptographic Keys: ")

    add_section_title(doc, "12.3", "Release Versioning & Rollback Procedures")
    add_body_p(doc, "Attendify adheres to Semantic Versioning (MAJOR.MINOR.PATCH):")
    add_bullet_item(doc, "Current release is tagged as Version 1.1.0 (Production Release with Full Theming).", bold_prefix="Release 1.1.0: ")
    add_bullet_item(doc, "In the event of a critical defect in production, the Project Manager initiates an emergency rollback. Render supports one-click rollbacks to previous build commits. For database migrations, developers author reverse migrations rather than manually modifying the database.", bold_prefix="Rollback Protocol: ")

    # -------------------------------------------------------------
    # CHAPTER 13: COMMUNICATION AND TEAM COORDINATION
    # -------------------------------------------------------------
    add_chapter_title(doc, "13", "Team Communication & Governance Protocols")

    add_section_title(doc, "13.1", "Communication Cadence & Channels")
    add_body_p(doc, "Structured communication channels ensure alignment between executive leadership, project management, engineering teams, and campus stakeholders:", bold_prefix="Communication Model: ")
    add_bullet_item(doc, "15-minute daily standup to identify blocking issues, review sprint burndown, and coordinate daily tasks.", bold_prefix="Daily Technical Standup: ")
    add_bullet_item(doc, "Executive review with Project Manager, System Analyst, and Lead Developers to evaluate deliverable completion, risk register status, and upcoming milestones.", bold_prefix="Weekly Progress Meeting: ")
    add_bullet_item(doc, "Bi-weekly demonstration of completed features to School Management and departmental stakeholders.", bold_prefix="Stakeholder Review & Demo: ")

    add_section_title(doc, "13.2", "Issue Escalation Pathway")
    add_body_p(doc, "When an issue exceeds the authority of a developer or tester, it follows a defined escalation chain:")
    add_bullet_item(doc, "Developer identifies technical obstacle -> Escalates to Technical Lead within 2 hours.", bold_prefix="Level 1 (Technical Block): ")
    add_bullet_item(doc, "Technical Lead identifies scope variance or timeline delay -> Escalates to Project Manager within 4 hours.", bold_prefix="Level 2 (Scope / Schedule Impact): ")
    add_bullet_item(doc, "Project Manager evaluates institutional impact -> Escalates to Institutional Steering Committee / School Management.", bold_prefix="Level 3 (Policy / Governance Impact): ")

    add_section_title(doc, "13.3", "Weekly Progress Meeting Minutes Template")
    add_code_block(doc,
"""=============================================================================
ATTENDIFY WEEKLY PROGRESS MEETING MINUTES
Date: [ YYYY-MM-DD ]  |  Time: [ HH:MM - HH:MM ]  |  Location: [ Conf Room / Virtual ]
Chairperson: [ Project Manager Name ]  |  Minute Taker: [ Name ]
Attendees: [ PM, SA, Backend Lead, Mobile Lead, QA Lead, Steering Committee Rep ]
=============================================================================
1. AGENDA TOPICS:
   - Review of action items from previous meeting
   - Subsystem delivery progress (Backend API, Flutter Web, Android APK)
   - QA automated testing metrics and defect review
   - Deployment status on Render cloud hosting
   - Review of active project risks and upcoming milestones

2. PROGRESS SUMMARY & DECISIONS MADE:
   - Topic 1: [ e.g., Verification of Light/Dark theme switching across all 20 screens ]
     Decision: [ Approved for Release 1.1 baseline ]
   - Topic 2: [ e.g., Automated APK build pipeline via GitHub Actions ]
     Decision: [ APK artifact generation validated and ready for distribution ]

3. ACTION ITEMS & WORK ASSIGNMENTS:
   - Action Item 1: [ Specific task description ]
     Owner: [ Assigned Role / Name ]  |  Deadline: [ YYYY-MM-DD ]
   - Action Item 2: [ Specific task description ]
     Owner: [ Assigned Role / Name ]  |  Deadline: [ YYYY-MM-DD ]

4. ADJOURNMENT & NEXT MEETING:
   - Meeting adjourned at [ Time ]. Next meeting scheduled for [ YYYY-MM-DD ].
=============================================================================""")

    # -------------------------------------------------------------
    # CHAPTER 14: CHANGE MANAGEMENT
    # -------------------------------------------------------------
    add_chapter_title(doc, "14", "Change Management & Scope Control")

    add_section_title(doc, "14.1", "Change Control Workflow")
    add_body_p(doc, "To prevent uncontrolled scope expansion ('scope creep') and maintain technical integrity, all modifications to functional requirements, database schemas, or API contracts must undergo formal Change Request (CR) governance:", bold_prefix="Change Governance: ")
    add_bullet_item(doc, "Stakeholder submits a formal Change Request describing the proposed enhancement or alteration.", bold_prefix="1. Submission: ")
    add_bullet_item(doc, "System Analyst and Technical Lead evaluate architectural feasibility, timeline impact, and regression risks.", bold_prefix="2. Impact Assessment: ")
    add_bullet_item(doc, "Project Manager reviews the assessment with the Steering Committee to approve, reject, or defer the request.", bold_prefix="3. Governance Decision: ")
    add_bullet_item(doc, "Approved changes are prioritized in the sprint backlog with updated acceptance criteria and automated tests.", bold_prefix="4. Backlog Scheduling: ")
    add_bullet_item(doc, "Project specifications (SRS, Architecture, API spec, context.md) are updated synchronously before code edits.", bold_prefix="5. Documentation Sync: ")

    add_section_title(doc, "14.2", "Standardized Change Request Template")
    add_code_block(doc,
"""=============================================================================
ATTENDIFY FORMAL CHANGE REQUEST (CR)
Change Request ID: [ CR-2026-XXXX ]  |  Date: [ YYYY-MM-DD ]
Initiator: [ Name / Department ]      |  Project Manager: [ PM Name ]
=============================================================================
1. CHANGE DESCRIPTION & JUSTIFICATION:
   - Title: [ Concise title of proposed change ]
   - Subsystem: [ Backend / Mobile UI / Database Schema / External Integration ]
   - Detailed Description: [ Explain what needs to change and why ]
   - Business Justification: [ Why is this change necessary for school operations? ]

2. IMPACT ASSESSMENT:
   - Architectural Impact: [ Low / Medium / High - e.g., Requires migration ]
   - Schedule Impact:      [ Estimated delay or sprint adjustment in days ]
   - Resource Impact:      [ Developer / QA hours required ]
   - Risk Assessment:      [ Impact on existing features or API contracts ]

3. GOVERNANCE REVIEW & APPROVAL:
   - System Analyst Recommendation: [ Recommended / Not Recommended / Deferred ]
   - Technical Lead Recommendation: [ Feasible / High Risk / Infeasible ]
   - Project Manager Decision:     [ APPROVED / REJECTED / DEFERRED TO v2.0 ]
   - Reason for Decision:          [ Summary of governing rationale ]

4. SIGN-OFF:
   - Project Manager Signature: _______________________ Date: ______________
   - Steering Committee Rep:    _______________________ Date: ______________
=============================================================================""")

    # -------------------------------------------------------------
    # CHAPTER 15: PROJECT PERFORMANCE EVALUATION
    # -------------------------------------------------------------
    add_chapter_title(doc, "15", "Project Performance & Operational Evaluation")

    add_section_title(doc, "15.1", "Evaluation Metrics & Operational Indicators")
    add_body_p(doc, "Project performance is evaluated using empirical metrics across deliverable completion, automated quality, deployment health, and architectural compliance:", bold_prefix="Performance Review: ")

    eval_headers = ["Performance Dimension", "Target Benchmark", "Achieved Metric", "Evaluation Rating"]
    eval_rows = [
        ["Scope & Deliverables", "100% of baseline deliverables", "28 of 28 deliverables implemented", "EXCELLENT (100%)"],
        ["Automated Test Coverage", ">= 95% test pass rate", "100% (319/319 tests passing)", "SUPERIOR (100%)"],
        ["Critical Defect Density", "0 Critical/High bugs at release", "0 Open Critical or High bugs", "EXCELLENT"],
        ["Architectural Integrity", "Decoupled client-server; 0 direct DB", "100% compliance with REST API", "EXCELLENT"],
        ["Production Deployment", "Automated CI/CD build & hosting", "Render Web & GitHub Actions active", "VERIFIED"],
        ["Documentation Completeness", "Complete SA & PM manuals authored", "Full documentation generated", "COMPLETED"]
    ]
    add_styled_table(doc, eval_headers, eval_rows, col_widths=[1.8, 1.8, 1.8, 1.1])

    add_section_title(doc, "15.2", "Project Manager Final Performance Verdict")
    add_body_p(doc, "The Attendify project has met 100% of its foundational engineering deliverables for Release 1.1. Core architectural requirements—including cryptographic single-session security, permanent 64-character QR tokens, FIFO waiting list promotion, sub-second camera scanning, 7 institutional report exporters, and dual-theme accessibility—have been authored, verified with 319 passing automated tests, and deployed to active cloud infrastructure. The system is structurally sound, stable, and ready for institutional pilot testing.", bold_prefix="Executive Evaluation Summary: ")
