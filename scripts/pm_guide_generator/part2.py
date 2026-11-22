"""
part2.py - Chapters 6 to 10 for Attendify Project Manager Guide.
Covers:
- Chapter 6: Project Timeline and Milestones (Sprints 1 to 6 Breakdown)
- Chapter 7: Task and Responsibility Management (Task Tracking Table)
- Chapter 8: Project Progress Monitoring (Procedures & Status Report Template)
- Chapter 9: Risk Management (Detailed Risk Register & Mitigation Matrix)
- Chapter 10: Issue and Bug Management (Triage, Severity vs Priority, Bug Report Template)
"""

from .styles import (
    add_chapter_title, add_section_title, add_subsection_title,
    add_body_p, add_bullet_item, add_callout, add_styled_table, add_code_block
)

def add_part2(doc):
    # -------------------------------------------------------------
    # CHAPTER 6: PROJECT TIMELINE AND MILESTONES
    # -------------------------------------------------------------
    add_chapter_title(doc, "6", "Project Timeline & Milestone Schedule")

    add_section_title(doc, "6.1", "Agile Phased Implementation Methodology")
    add_body_p(doc, "The Attendify development lifecycle was executed using an Agile sprint methodology structured across six core developmental sprints. This phased approach allowed the engineering team to validate architectural primitives early, establish secure cryptographic foundations, and progressively layer complex business rules, user interfaces, reporting pipelines, and regression test suites.", bold_prefix="Implementation Framework: ")
    add_body_p(doc, "In accordance with institutional project management standards, historical milestones that have been completed and verified against the production codebase are documented with their verified deliverables. Future milestone dates, campus-wide rollout ceremonies, and semester transitions where exact dates have not yet been formally scheduled by school leadership are explicitly marked as 'To Be Determined' (TBD) to preserve factual integrity.", bold_prefix="Governance & Integrity Note: ")

    add_section_title(doc, "6.2", "Sprint Breakdown & Milestone Progress")
    add_body_p(doc, "The table below summarizes the six core developmental sprints, their planned and completed deliverables, and their current verification status:")

    sprint_headers = ["Phase / Sprint", "Focus Area", "Key Deliverables Achieved", "Status", "Completion Date"]
    sprint_rows = [
        ["Sprint 1", "Requirements & Architecture", "SRS v1.1 finalized; System Architecture & MySQL DDL; OpenAPI REST contract; 20-screen UI inventory defined.", "Implemented", "Completed (Historical)"],
        ["Sprint 2", "Backend Core & Security", "Laravel 11 backend setup; Sanctum auth; Single active session middleware; 64-char QR generator; Event lifecycle state machine.", "Implemented", "Completed (Historical)"],
        ["Sprint 3", "Registration & Scanning", "Dynamic room capacity engine; FIFO waiting list queue; Sub-second camera QR scan endpoint; Late arrival calculation; Walk-in support.", "Implemented", "Completed (Historical)"],
        ["Sprint 4", "Reports & Notifications", "7 multi-format report exporters (CSV/XLSX/PDF); FCM push dispatch service; In-app notifications; 30-day purge scheduler.", "Implemented", "Completed (Historical)"],
        ["Sprint 5", "Flutter UI & Dual Theming", "20 adaptive screens in AetherUI; Centralized AppThemeController; Header theme toggle; Light/Dark/System Default theming.", "Implemented", "Completed (Historical)"],
        ["Sprint 6", "Verification & Deployment", "117 PHPUnit tests (100% pass on SQLite); 202 Flutter tests; Render cloud hosting deployment; GitHub Actions APK CI/CD.", "Implemented", "Completed (Historical)"],
        ["Sprint 7 (Upcoming)", "Campus Pilot & Field Testing", "Physical Android carrier testing; Multi-gate venue load test; Pilot launch during Departmental Sports Festival.", "Pending", "TBD (Q1 Academic Year)"],
        ["Sprint 8 (Upcoming)", "Institution-Wide Rollout", "Campus-wide student onboarding; Final SIS database connector sync; Post-launch governance handover.", "Pending", "TBD (Q2 Academic Year)"]
    ]
    add_styled_table(doc, sprint_headers, sprint_rows, col_widths=[1.1, 1.4, 2.3, 0.9, 1.1])

    # -------------------------------------------------------------
    # CHAPTER 7: TASK AND RESPONSIBILITY MANAGEMENT
    # -------------------------------------------------------------
    add_chapter_title(doc, "7", "Task & Responsibility Governance")

    add_section_title(doc, "7.1", "Task Tracking Structure & Priority Classification")
    add_body_p(doc, "Engineering work packages in Attendify are governed by a standardized Work Breakdown Structure (WBS). Every task is tracked with a unique Task ID, role assignment, execution priority, dependency chain, expected deliverable, and verifiable acceptance criteria.", bold_prefix="Task Management Model: ")
    add_body_p(doc, "Priority levels are categorized as Critical (blocker to system security or core attendance), High (essential feature required for normal operations), Medium (operational enhancement or secondary flow), and Low (cosmetic refinement or minor workflow optimization).", bold_prefix="Priority Standards: ")

    add_section_title(doc, "7.2", "Core Project Task Inventory")
    add_body_p(doc, "The following task register reflects the structural work packages across the Attendify system lifecycle:")

    task_headers = ["Task ID", "Task Description", "Assigned Role", "Pri.", "Status", "Dependencies", "Acceptance Criteria"]
    task_rows = [
        ["TSK-01", "Design MySQL 8.0 schema and author 13 idempotent migrations", "Backend Dev", "Critical", "Completed", "SRS v1.1 Approval", "All tables pass migration refresh without syntax or FK errors."],
        ["TSK-02", "Implement Sanctum auth with single active session enforcement", "Backend Dev", "Critical", "Completed", "TSK-01 (DB Schema)", "Concurrent login from second device invalidates primary session token."],
        ["TSK-03", "Author 64-character permanent cryptographic student QR generator", "Backend Dev", "Critical", "Completed", "TSK-01, TSK-02", "Generates bin2hex(random_bytes(32)); previous tokens revoked on reissue."],
        ["TSK-04", "Build event lifecycle state machine (draft -> pending -> published)", "Backend Dev", "High", "Completed", "TSK-01 (Events Table)", "Only Admin role can publish or approve event cancellations."],
        ["TSK-05", "Implement room capacity capping and FIFO waiting list auto-promotion", "Backend Dev", "High", "Completed", "TSK-04 (Event Engine)", "Cancellations promote waiting list #1 to registered in DB transaction."],
        ["TSK-06", "Develop sub-second QR scan endpoint with late arrival grace logic", "Backend Dev", "Critical", "Completed", "TSK-03, TSK-05", "Check-in after start + grace is flagged 'late'; attendance recorded sub-sec."],
        ["TSK-07", "Create manual attendance correction endpoint with mandatory reason", "Backend Dev", "High", "Completed", "TSK-06 (Attendance)", "Correction updates record, inserts into corrections & activity_logs."],
        ["TSK-08", "Build 7 institutional report exporters for CSV, XLSX, and PDF", "Backend Dev", "Medium", "Completed", "TSK-06, TSK-07", "Exports download clean data files with accurate percentage formulas."],
        ["TSK-09", "Implement Firebase Cloud Messaging HTTP v1 dispatch service", "Backend Dev", "Medium", "Completed", "Google Service Acct", "HTTP v1 payload dispatches successfully to FCM endpoint."],
        ["TSK-10", "Configure notification retention scheduler for 30-day purge", "Backend Dev", "Low", "Completed", "TSK-09 (Notifs)", "Artisan command purges notifications created > 30 days ago."],
        ["TSK-11", "Design AetherUI design token system and dual-theme palettes", "Mobile Dev", "High", "Completed", "UI Design System", "High-contrast light and dark palettes strictly adhere to black/white brand."],
        ["TSK-12", "Implement centralized AppThemeController with persistent storage", "Mobile Dev", "High", "Completed", "TSK-11 (Tokens)", "User theme preference persists across app restarts and logouts."],
        ["TSK-13", "Add responsive theme toggle button to top navigation bar", "Mobile Dev", "Medium", "Completed", "TSK-12 (Controller)", "Sun/Moon button sits between bell and profile; toggles theme instantly."],
        ["TSK-14", "Build 20 role-based screens with adaptive AppShell navigation", "Mobile Dev", "Critical", "Completed", "TSK-11, TSK-12", "All 20 screens render responsive layouts for mobile and wide web."],
        ["TSK-15", "Integrate mobile_scanner camera with haptic/audible feedback", "Mobile Dev", "Critical", "Completed", "TSK-06, TSK-14", "Camera scans student QR badges seamlessly on Android devices."],
        ["TSK-16", "Configure Render cloud hosting for Web App and REST API", "DevOps / Lead", "High", "Completed", "TSK-01 to TSK-15", "Web app loads from public root; API responds on https endpoint."],
        ["TSK-17", "Set up GitHub Actions CI/CD automated Android APK build pipeline", "DevOps / Lead", "High", "Completed", "Flutter Toolchain", "Push to main branch automatically compiles and outputs release APK."],
        ["TSK-18", "Author 117 automated PHPUnit test suites on SQLite :memory:", "QA / Backend", "Critical", "Completed", "TSK-01 to TSK-10", "117 tests pass with 100% green status and zero database pollution."],
        ["TSK-19", "Author 202 automated Flutter unit and widget tests", "QA / Mobile", "Critical", "Completed", "TSK-11 to TSK-15", "202 mobile tests pass verifying navigation, themes, and controllers."],
        ["TSK-20", "Conduct physical Android carrier network FCM delivery testing", "QA / Mobile", "High", "Under Testing", "TSK-09, TSK-17", "Push notifications reliably alert physical devices on cellular data."]
    ]
    add_styled_table(doc, task_headers, task_rows, col_widths=[0.7, 1.8, 0.9, 0.5, 0.8, 0.9, 1.2])

    # -------------------------------------------------------------
    # CHAPTER 8: PROJECT PROGRESS MONITORING
    # -------------------------------------------------------------
    add_chapter_title(doc, "8", "Project Progress Monitoring & Reporting")

    add_section_title(doc, "8.1", "Progress Monitoring Procedures")
    add_body_p(doc, "To maintain schedule adherence and prevent scope creep, project governance relies on continuous automated metric tracking, weekly synchronization cadences, and quantitative Key Performance Indicators (KPIs):", bold_prefix="Monitoring Framework: ")
    add_bullet_item(doc, "All source code changes must be committed via pull requests validated by continuous integration. Every push triggers automated test suites for both backend and mobile.", bold_prefix="Continuous Verification: ")
    add_bullet_item(doc, "The Project Manager tracks deliverable completion against the RACI matrix and sprint backlog, logging progress percentages weekly.", bold_prefix="Milestone Variance Tracking: ")
    add_bullet_item(doc, "Defects identified during automated testing or manual QA are logged in the issue tracker, categorized by severity, and assigned resolution SLAs.", bold_prefix="Defect Burndown Monitoring: ")

    add_section_title(doc, "8.2", "Core Project KPIs")
    add_bullet_item(doc, "Target: 100%. Current Achievement: 100% across all 28 baseline deliverables outlined in the Project Charter.", bold_prefix="1. Deliverable Completion Rate: ")
    add_bullet_item(doc, "Target: 100%. Current Achievement: 100% (117 of 117 PHPUnit tests passing; 202 of 202 Flutter tests passing).", bold_prefix="2. Automated Test Pass Rate: ")
    add_bullet_item(doc, "Target: 0 Critical / High bugs at release baseline. Current Achievement: 0 open Critical/High defects.", bold_prefix="3. Defect Density at Release: ")
    add_bullet_item(doc, "Target: 99.0% availability. Monitored via health-check endpoints on Render hosting.", bold_prefix="4. Deployment Availability: ")

    add_section_title(doc, "8.3", "Project Status Report Template")
    add_body_p(doc, "The following standardized status report template is utilized by the Project Manager for executive briefings to institutional leadership:")

    add_code_block(doc, 
"""=============================================================================
ATTENDIFY EXECUTIVE PROJECT STATUS REPORT
Reporting Period: [Date Range, e.g., November 15 – November 22, 2026]
Project Manager: [Project Manager Name]  |  Baseline: Release 1.1
=============================================================================
1. EXECUTIVE SUMMARY & OVERALL HEALTH:
   - Overall Project Status: [ GREEN / AMBER / RED ]
   - Schedule Variance: [ On Track / +X Days / -X Days ]
   - Scope Variance: [ Zero Scope Creep / Controlled Change Approved ]
   - Key Achievement: Completion of dual Light/Dark/System Default theme system,
     passing 117 backend & 202 mobile tests, and production web deployment.

2. MILESTONE PROGRESS:
   - Sprint 1 (Requirements & Architecture): 100% Completed
   - Sprint 2 (Backend Core & Security):     100% Completed
   - Sprint 3 (Registration & Scanning):     100% Completed
   - Sprint 4 (Reports & Notifications):     100% Completed
   - Sprint 5 (Flutter UI & Theming):        100% Completed
   - Sprint 6 (Verification & Deployment):   100% Completed
   - Upcoming Milestone: Campus Pilot Field Testing (Scheduled: TBD)

3. DELIVERABLE BURNDOWN (THIS REPORTING CYCLE):
   - [x] Centralized AppThemeController and SharedPreferences persistence
   - [x] Top navigation theme toggle button (Notification -> Theme -> Profile)
   - [x] Settings screen tri-state theme selector (Light / Dark / System Default)
   - [x] Verification across 20 screens in Flutter Web and Android APK builds

4. QUALITY ASSURANCE & DEFECT STATUS:
   - Automated Backend Tests:  117 / 117 Passing (100%)
   - Automated Mobile Tests:   202 / 202 Passing (100%)
   - Open Critical/High Bugs:  0
   - Open Medium/Low Issues:   1 (Render free-tier ~50s cold-start spin-down)

5. KEY RISKS & MITIGATION ACTIVITIES:
   - Risk: Render free-tier instance inactivity sleep causes initial delay.
     Mitigation: Document cold-start behavior; evaluate paid tier for live events.
   - Risk: FCM push notification delivery on physical carrier networks.
     Mitigation: Conduct staging verification on real Android handsets.

6. PLANNED ACTIVITIES FOR NEXT PERIOD:
   - Finalize institutional handover documentation.
   - Coordinate pilot venue testing during upcoming school departmental assembly.
=============================================================================""")

    # -------------------------------------------------------------
    # CHAPTER 9: RISK MANAGEMENT
    # -------------------------------------------------------------
    add_chapter_title(doc, "9", "Project Risk Management & Mitigation Register")

    add_section_title(doc, "9.1", "Risk Management Framework")
    add_body_p(doc, "Risk management in Attendify follows a proactive identification, qualitative assessment, mitigation planning, and continuous monitoring framework. Every identified technical and operational threat is evaluated on Probability (Low, Medium, High) and Impact (Low, Medium, High), resulting in an overall Risk Level (Low, Moderate, High, Critical).", bold_prefix="Risk Governance Model: ")

    add_section_title(doc, "9.2", "Detailed Project Risk Register")
    add_body_p(doc, "The matrix below details all identified project risks, their potential impacts, and implemented or recommended mitigation strategies:")

    risk_headers = ["Risk ID", "Risk Description", "Category", "Prob.", "Impact", "Level", "Mitigation Strategy & Contingency Plan"]
    risk_rows = [
        ["RSK-01", "Render free-tier cloud instance spins down after 15 min of inactivity, delaying initial user request by ~50 seconds.", "Infrastructure", "High", "Medium", "Moderate", "Document cold-start delay in user guides. Implement automated scheduled ping cron during school hours or upgrade to Render Starter plan ($7/mo) prior to high-traffic campus events."],
        ["RSK-02", "Simultaneous check-ins at multi-door venues exhaust MySQL database connection pool.", "Performance", "Medium", "High", "High", "Tune MySQL max_connections; utilize persistent PDO connections; implement Redis queue buffering for non-critical logging; conduct venue load testing prior to 1,000+ attendee events."],
        ["RSK-03", "Concurrent login bypass allows students to share credentials for proxy attendance.", "Security", "Low", "High", "Moderate", "Single active session middleware strictly enforced; generating new session UUID revokes prior tokens immediately; audits alert administrators to rapid IP geographic shifts."],
        ["RSK-04", "FCM push notifications fail to alert physical Android devices due to aggressive OS battery saver or carrier network firewalls.", "Integration", "Medium", "Medium", "Moderate", "Utilize FCM high-priority data payloads; implement in-app notification inbox as guaranteed fallback; verify on physical Android carrier networks during Sprint 7 pilot."],
        ["RSK-05", "Students fail to install Android APK due to Google Play Protect warnings for unsigned third-party sideloads.", "Deployment", "High", "Medium", "High", "Provide official step-by-step installation runbook; configure institutional signing key; evaluate hosting APK on campus intranet portal or internal Google Play track."],
        ["RSK-06", "Accidental or malicious database loss during server maintenance or migration.", "Data Loss", "Low", "Critical", "High", "Automate daily off-site encrypted MySQL dumps to secure S3 storage; maintain immutable migration files; test point-in-time recovery runbook semi-annually."],
        ["RSK-07", "Organizer improperly edits attendance records to artificially inflate student participation figures.", "Integrity", "Medium", "High", "High", "Mandatory justification reason required for all corrections; system records dual entries in attendance_corrections and activity_logs with immutable before/after snapshots."],
        ["RSK-08", "Environment configuration drift between local development, staging, and production hosting.", "DevOps", "Medium", "Medium", "Moderate", "Centralize environment variables in .env.example; enforce strict CI/CD linting; maintain identical Docker/PHP runtime configurations across environments."]
    ]
    add_styled_table(doc, risk_headers, risk_rows, col_widths=[0.6, 1.8, 0.8, 0.5, 0.5, 0.6, 2.0])

    add_callout(doc, "Risk RSK-01 (Render Free-Tier Spin-Down) represents the primary operational latency risk in the current staging environment. For production campus-wide launch, transitioning the Render web service to an always-on instance tier eliminates cold-start spin-down completely.", title="Infrastructure Operational Notice", alert_type="warning")

    # -------------------------------------------------------------
    # CHAPTER 10: ISSUE AND BUG MANAGEMENT
    # -------------------------------------------------------------
    add_chapter_title(doc, "10", "Issue & Defect Management Lifecycle")

    add_section_title(doc, "10.1", "Defect Classification & Severity Matrix")
    add_body_p(doc, "The Attendify quality governance protocol classifies all defects into distinct severity and priority tiers to ensure systematic triage and adherence to resolution Service Level Agreements (SLAs):", bold_prefix="Defect Governance: ")

    add_bullet_item(doc, "System crash, database corruption, security vulnerability, or complete failure of QR check-in scanning. Workaround: None. Resolution SLA: Under 4 hours.", bold_prefix="Severity 1 (Critical): ")
    add_bullet_item(doc, "Major feature failure (e.g., event approval flow blocked, waiting list promotion failure, report export failure). Workaround: Difficult or complex. Resolution SLA: Under 24 hours.", bold_prefix="Severity 2 (High): ")
    add_bullet_item(doc, "Non-critical functionality impairment (e.g., notification badge count mismatch, minor filter glitch on calendar). Workaround: Readily available. Resolution SLA: Under 3 business days.", bold_prefix="Severity 3 (Medium): ")
    add_bullet_item(doc, "Cosmetic flaw, minor alignment variance, or typographical error in text strings. Workaround: Not required. Resolution SLA: Next scheduled release.", bold_prefix="Severity 4 (Low): ")

    add_section_title(doc, "10.2", "Issue Resolution & Retesting Workflow")
    add_body_p(doc, "Every reported defect must progress through five mandatory lifecycle states:")
    add_bullet_item(doc, "Issue submitted by tester, organizer, or developer with full reproduction steps, environment details, and screenshots.", bold_prefix="1. Logging & Triage: ")
    add_bullet_item(doc, "Project Manager and Tech Lead review the issue, assign severity/priority, and allocate to the responsible subsystem engineer.", bold_prefix="2. Assignment & Reproduction: ")
    add_bullet_item(doc, "Developer creates a reproduction unit test, resolves the root cause in code, and confirms automated tests pass locally.", bold_prefix="3. Remediation & PR: ")
    add_bullet_item(doc, "QA team deploys the fix to staging, executes regression test suites, and verifies the defect is resolved without secondary regressions.", bold_prefix="4. Independent Retesting: ")
    add_bullet_item(doc, "Defect is marked 'Closed' in the issue register and merged into the main release branch.", bold_prefix="5. Verification & Closure: ")

    add_section_title(doc, "10.3", "Standardized Bug Report Template")
    add_body_p(doc, "All defects discovered during testing and operations must be documented using the template below:")

    add_code_block(doc,
"""=============================================================================
ATTENDIFY DEFECT INCIDENT REPORT
Bug ID: [ BUG-YYYY-XXXX ]  |  Reported Date: [ YYYY-MM-DD ]
Reporter: [ Name / Role ]   |  Assignee: [ Developer Name ]
=============================================================================
1. DEFECT CLASSIFICATION:
   - Subsystem:      [ Backend API / Flutter Web / Android APK / Database ]
   - Severity:       [ S1 - Critical / S2 - High / S3 - Medium / S4 - Low ]
   - Priority:       [ P1 - Blocker / P2 - High / P3 - Normal / P4 - Low ]
   - Environment:    [ Production (Render) / Staging / Local / Android Handset ]
   - App Version:    Release 1.1 (Commit Hash: [ e.g., 7f8a3d2 ])

2. SUMMARY & DESCRIPTION:
   - Title: [ Concise description of the defect ]
   - Overview: [ Detailed explanation of unexpected system behavior ]

3. STEP-BY-STEP REPRODUCTION PROCEDURE:
   1. Log into Attendify as role: [ Administrator / Organizer / Student ]
   2. Navigate to screen: [ Screen Name, e.g., Event Registration Screen ]
   3. Perform action: [ e.g., Tap 'Register' when capacity equals 50/50 ]
   4. Observe system response: [ e.g., Error message or UI hang ]

4. OBSERVED VS. EXPECTED BEHAVIOR:
   - Observed Behavior: [ What actually happened, error code, or stack trace ]
   - Expected Behavior: [ What should have happened per SRS v1.1 ]

5. EVIDENCE & LOG ARTIFACTS:
   - Screenshot / Screen Recording: [ Attached URI / Path ]
   - API Request Payload & Response Envelope: [ Attached JSON ]
   - Console / Log Output: [ Attached stack trace ]

6. RESOLUTION & RETESTING SIGN-OFF:
   - Root Cause Analysis: [ Technical explanation of the underlying fault ]
   - Remediation Commit: [ Git Commit SHA ]
   - Retest Result: [ PASS / FAIL - Tested by QA on YYYY-MM-DD ]
   - Closure Status: [ CLOSED - Approved by Project Manager ]
=============================================================================""")
