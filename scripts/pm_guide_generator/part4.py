"""
part4.py - Chapters 16 to 18 for Attendify Project Manager Guide.
Covers:
- Chapter 16: Project Handover & Maintenance (Checklists, Deployment Info, Roadmap)
- Chapter 17: Known Issues & Pending Work (Render Sleep, Carrier FCM, Future Milestones)
- Chapter 18: Project Manager Reference Templates (All 9 Complete Ready-to-Use Templates)
"""

from .styles import (
    add_chapter_title, add_section_title, add_subsection_title,
    add_body_p, add_bullet_item, add_callout, add_styled_table, add_code_block
)

def add_part4(doc):
    # -------------------------------------------------------------
    # CHAPTER 16: PROJECT HANDOVER AND MAINTENANCE
    # -------------------------------------------------------------
    add_chapter_title(doc, "16", "Project Handover & Maintenance Strategy")

    add_section_title(doc, "16.1", "Handover Checklist & Deliverables Verification")
    add_body_p(doc, "Formal handover of Attendify from the engineering team to the institutional operations and IT administration team requires verification across five essential operational dimensions:", bold_prefix="Handover Protocol: ")

    handover_headers = ["Handover Area", "Verification Item", "Target Recipient", "Verification Status"]
    handover_rows = [
        ["Source Code Repository", "Full Git repository with complete commit history and branch tags", "Institutional IT Lead", "VERIFIED & TRANSFERRED"],
        ["Backend REST API", "Laravel 11 backend with Sanctum security and 13 migrations", "Backend Operations Admin", "DEPLOYED ON RENDER"],
        ["Client Applications", "Flutter Web compiled assets and Android release APK build", "Campus Systems Lead", "COMPILED & VERIFIED"],
        ["Database Schema", "MySQL 8.0 DDL, migration suite, and seeder scripts", "Database Administrator", "VERIFIED IDEMPOTENT"],
        ["Automated Test Suites", "117 PHPUnit tests and 202 Flutter unit/widget tests passing", "QA Operations Lead", "100% PASS RATE"],
        ["System Documentation", "SRS v1.1, System Architecture, REST API spec, SA & PM Guides", "Project Management Office", "AUTHORED & CATALOGED"],
        ["Cloud Hosting Access", "Render web service credentials, environment variables, DB keys", "Lead DevOps Engineer", "CONFIGURED & SECURED"],
        ["Google Firebase Project", "Firebase Cloud Messaging service account credentials", "Notification Administrator", "KEY CONFIGURED"]
    ]
    add_styled_table(doc, handover_headers, handover_rows, col_widths=[1.5, 2.3, 1.4, 1.3])

    add_section_title(doc, "16.2", "System Documentation Catalog")
    add_body_p(doc, "The following formal documentation assets accompany the Attendify Release 1.1 handover:")
    add_bullet_item(doc, "Canonical requirements baseline defining functional and non-functional specifications.", bold_prefix="1. Software Requirements Specification (SRS v1.1): ")
    add_bullet_item(doc, "Comprehensive database schemas, ER diagrams, foreign key cascades, and sequence diagrams.", bold_prefix="2. System Architecture & Database Design: ")
    add_bullet_item(doc, "Canonical endpoint definitions, request schemas, status codes, and openapi.yaml.", bold_prefix="3. REST API Specification (v1.0): ")
    add_bullet_item(doc, "In-depth 33-chapter technical reference manual for software architects and analysts.", bold_prefix="4. Complete System Analyst Technical Documentation: ")
    add_bullet_item(doc, "Executive governance, risk, milestone, and operational guide for project leadership.", bold_prefix="5. Complete Project Manager Guide (This Document): ")

    add_section_title(doc, "16.3", "Ongoing Maintenance Responsibilities & Post-Launch Roadmap")
    add_body_p(doc, "Following handover, institutional IT assumes operational responsibility for routine system maintenance:")
    add_bullet_item(doc, "Verify completion of daily MySQL database backups and review error logs.", bold_prefix="Daily IT Tasks: ")
    add_bullet_item(doc, "Monitor notification retention purge task execution ('notifications:purge'); audit activity logs for privilege escalations.", bold_prefix="Weekly IT Tasks: ")
    add_bullet_item(doc, "Apply security patches to operating system, PHP runtime, and Laravel dependencies; review Render hosting resource utilization.", bold_prefix="Monthly IT Tasks: ")
    add_bullet_item(doc, "Archive completed semester event records; perform semester student roster synchronization; reissue student QR tokens upon matriculation.", bold_prefix="Semester Transition Tasks: ")

    # -------------------------------------------------------------
    # CHAPTER 17: KNOWN ISSUES AND PENDING WORK
    # -------------------------------------------------------------
    add_chapter_title(doc, "17", "Known Operational Constraints & Future Work")

    add_section_title(doc, "17.1", "Known Technical Constraints & Workarounds")
    add_body_p(doc, "To provide full transparency for project leadership, the following technical constraints are documented alongside recommended operational workarounds:", bold_prefix="Operational Constraints: ")

    known_headers = ["Issue ID", "Technical Constraint Description", "Operational Impact", "Workaround / Mitigation Strategy"]
    known_rows = [
        ["ISS-01", "Render Free-Tier Spin-Down Delay (~50s cold start).", "Initial request after 15 min of inactivity experiences a ~50 second delay while container boots.", "Document behavior in admin guides. Run automated keep-alive ping script during school event hours, or upgrade Render service to always-on instance tier ($7/month)."],
        ["ISS-02", "FCM Push Delivery on Strict Mobile Power Savers.", "Aggressive device battery optimizations on select Android OEMs (Xiaomi, Huawei) may delay background notifications.", "Utilize high-priority data payloads in FCM; instruct students to disable battery restrictions for Attendify; rely on in-app notification inbox as guaranteed fallback."],
        ["ISS-03", "Android Sideload Installation Warnings.", "Downloading release APK outside Google Play triggers 'Unknown Source' warning dialogs.", "Provide clear illustrated step-by-step installation guide to students; prepare institutional signing key for campus MDM or internal Google Play distribution track."]
    ]
    add_styled_table(doc, known_headers, known_rows, col_widths=[0.8, 1.8, 1.7, 2.2])

    add_section_title(doc, "17.2", "Pending Roadmap Features (Future Releases)")
    add_body_p(doc, "The following architectural enhancements are scheduled for evaluation in future releases (Release 2.0+):")
    add_bullet_item(doc, "Local SQLite offline cache on mobile devices allowing organizers to scan QR codes during campus network outages, with automatic background synchronization upon network reconnection.", bold_prefix="1. Offline Attendance Synchronization: ")
    add_bullet_item(doc, "Real-time bidirectional integration with campus Student Information Systems (SIS) for automatic student enrollment, college transfers, and graduation clearances.", bold_prefix="2. Automated SIS Database Connector: ")
    add_bullet_item(doc, "Official deployment of Attendify to the Google Play Store and Apple App Store for streamlined single-tap installation without APK sideloading.", bold_prefix="3. App Store Distribution: ")

    # -------------------------------------------------------------
    # CHAPTER 18: PROJECT MANAGER REFERENCE TEMPLATES
    # -------------------------------------------------------------
    add_chapter_title(doc, "18", "Project Manager Reference Templates")

    add_section_title(doc, "18.1", "Comprehensive Template Library Overview")
    add_body_p(doc, "This chapter provides the Project Manager with nine complete, ready-to-use executive management templates formatted for immediate operational deployment across the project lifecycle.", bold_prefix="Template Suite: ")

    add_subsection_title(doc, "18.1.1", "Template 1: Weekly Project Status Report")
    add_code_block(doc,
"""=============================================================================
TEMPLATE 1: WEEKLY PROJECT STATUS REPORT
Project: Attendify  |  Report Date: [ YYYY-MM-DD ]  |  Status: [ GREEN/AMBER/RED ]
Project Manager: [ PM Name ]  |  Period: [ Start Date ] to [ End Date ]
=============================================================================
1. EXECUTIVE STATUS SUMMARY:
   - Summary of progress, key deliverables completed, and major milestones.
2. MILESTONE BURNDOWN:
   - Milestone 1: [ Status / % Complete ]
   - Milestone 2: [ Status / % Complete ]
3. QUALITY & DEFECT METRICS:
   - Automated Tests: [ Total Passing / Total Tests ]
   - Open Defects: Critical: [ X ], High: [ Y ], Medium: [ Z ], Low: [ W ]
4. KEY RISKS & IMPEDIMENTS:
   - [ Risk Description and immediate mitigation action ]
5. NEXT PERIOD PRIORITIES:
   - Priority 1: [ Action item and owner ]
   - Priority 2: [ Action item and owner ]
=============================================================================""")

    add_subsection_title(doc, "18.1.2", "Template 2: Meeting Minutes & Action Items")
    add_code_block(doc,
"""=============================================================================
TEMPLATE 2: MEETING MINUTES & ACTION REGISTER
Meeting: [ Meeting Title, e.g., Sprint Planning / Governance Review ]
Date: [ YYYY-MM-DD ]  |  Time: [ HH:MM ]  |  Location: [ Room / Video Link ]
Attendees: [ List of Attendees ]  |  Minute Taker: [ Name ]
=============================================================================
1. DISCUSSION SUMMARY:
   - [ Key discussion topic and summary of deliberations ]
2. DECISIONS RECORD:
   - Decision 1: [ Formal record of decision agreed upon ]
3. ACTION ITEM REGISTER:
   | Action ID | Action Description | Owner | Due Date | Status |
   | ACT-01    | [ Action detail ]   | [Name]| [Date]   | [Open] |
=============================================================================""")

    add_subsection_title(doc, "18.1.3", "Template 3: Task & Work Package Tracker")
    add_code_block(doc,
"""=============================================================================
TEMPLATE 3: TASK & WORK PACKAGE TRACKER
Task ID: [ TSK-XXXX ]  |  Work Package: [ Subsystem Name ]
Assigned Role: [ Backend / Mobile / QA / DevOps ]  |  Assignee: [ Developer Name ]
Priority: [ Critical / High / Medium / Low ]  |  Status: [ In Progress / Completed ]
=============================================================================
1. TASK SCOPE: [ Detailed description of engineering deliverable ]
2. DEPENDENCIES: [ Pre-requisite task IDs ]
3. DELIVERABLE ARTIFACTS: [ Source code files, migrations, or documentation ]
4. ACCEPTANCE CRITERIA: [ Bullet points defining verifiable 'Done' ]
5. VERIFICATION SIGN-OFF: Tested By: [ QA Name ] on [ YYYY-MM-DD ]
=============================================================================""")

    add_subsection_title(doc, "18.1.4", "Template 4: Incident & Bug Report")
    add_code_block(doc,
"""=============================================================================
TEMPLATE 4: DEFECT INCIDENT REPORT
Bug ID: [ BUG-YYYY-XXXX ]  |  Severity: [ S1/S2/S3/S4 ]  |  Priority: [ P1/P2/P3/P4 ]
Environment: [ Production / Staging / Android Handset ]  |  Date: [ YYYY-MM-DD ]
=============================================================================
1. SUMMARY: [ Clear statement of incorrect system behavior ]
2. REPRODUCTION STEPS:
   1. [ Step 1 ] -> 2. [ Step 2 ] -> 3. [ Step 3 ]
3. OBSERVED VS EXPECTED RESULT:
   - Observed: [ Error code, crash log, or visual defect ]
   - Expected: [ Correct behavior specified in SRS ]
4. REMEDIATION & VERIFICATION:
   - Developer Commit: [ Git Hash ]  |  Retest Status: [ PASS / FAIL ]
=============================================================================""")

    add_subsection_title(doc, "18.1.5", "Template 5: Project Risk Register Entry")
    add_code_block(doc,
"""=============================================================================
TEMPLATE 5: RISK REGISTER ENTRY
Risk ID: [ RSK-XX ]  |  Category: [ Infrastructure / Security / Operations ]
Probability: [ Low / Medium / High ]  |  Impact: [ Low / Medium / Critical ]
Overall Risk Level: [ Low / Moderate / High / Critical ]
=============================================================================
1. RISK DESCRIPTION: [ Potential event that could impede project success ]
2. ROOT CAUSE / TRIGGER: [ Circumstances that would activate the risk ]
3. IMPACT ANALYSIS: [ Financial, operational, schedule, or reputational damage ]
4. MITIGATION STRATEGY: [ Proactive controls to reduce probability/impact ]
5. CONTINGENCY PLAN: [ Action plan to execute if risk event occurs ]
6. RISK OWNER: [ Role / Name responsible for monitoring ]
=============================================================================""")

    add_subsection_title(doc, "18.1.6", "Template 6: Formal Change Request (CR)")
    add_code_block(doc,
"""=============================================================================
TEMPLATE 6: FORMAL CHANGE REQUEST (CR)
CR ID: [ CR-YYYY-XXXX ]  |  Date: [ YYYY-MM-DD ]  |  Initiator: [ Name/Dept ]
Title: [ Short title of requested change ]
=============================================================================
1. DESCRIPTION & JUSTIFICATION: [ What change is proposed and why is it needed? ]
2. IMPACT ANALYSIS:
   - Architectural: [ Impact on database, API contract, or security ]
   - Schedule & Cost: [ Estimated developer days and delivery delay ]
3. RECOMMENDATIONS:
   - System Analyst: [ Recommended / Rejected ]
   - Technical Lead: [ Feasible / High Risk ]
4. GOVERNANCE DECISION: [ APPROVED / REJECTED / DEFERRED ]
   - Project Manager Signature: __________________ Date: ______________
=============================================================================""")

    add_subsection_title(doc, "18.1.7", "Template 7: Quality Assurance Test Summary")
    add_code_block(doc,
"""=============================================================================
TEMPLATE 7: QA TEST EXECUTION SUMMARY REPORT
Test Cycle: [ e.g., Release 1.1 Pre-Deployment Verification ]
Execution Date: [ YYYY-MM-DD ]  |  QA Lead: [ QA Engineer Name ]
=============================================================================
1. TEST SUITE METRICS:
   - Backend PHPUnit Tests: [ Executed: 117 | Passed: 117 | Failed: 0 ]
   - Mobile Flutter Tests:  [ Executed: 202 | Passed: 202 | Failed: 0 ]
   - Overall Test Pass Rate: 100.0%
2. CRITICAL MODULE VALIDATION:
   - Authentication & Session Revocation: [ PASS ]
   - QR Token Generation & Sub-second Scan: [ PASS ]
   - Waiting List FIFO Queue Promotion:    [ PASS ]
   - Light / Dark Mode Global Theming:     [ PASS ]
3. RECOMMENDATION: [ APPROVED FOR PRODUCTION RELEASE ]
=============================================================================""")

    add_subsection_title(doc, "18.1.8", "Template 8: Release Deployment Checklist")
    add_code_block(doc,
"""=============================================================================
TEMPLATE 8: RELEASE DEPLOYMENT CHECKLIST
Release Version: Attendify Release 1.1  |  Target Date: [ YYYY-MM-DD ]
Release Manager: [ Name ]  |  Git Commit: [ SHA ]
=============================================================================
PRE-DEPLOYMENT:
[ ] 1. All automated test suites passing 100% in CI pipeline.
[ ] 2. Database backup taken and point-in-time recovery verified.
[ ] 3. Environment variables and secrets configured in Render dashboard.
DEPLOYMENT EXECUTION:
[ ] 4. Code merged to main branch; Render web service build triggered.
[ ] 5. Run 'php artisan migrate --force' to apply pending schema migrations.
[ ] 6. GitHub Actions release APK compiled and verified for download.
POST-DEPLOYMENT SMOKE TEST:
[ ] 7. Health check endpoint responds with HTTP 200 OK.
[ ] 8. Test user logs in, toggles theme, and opens calendar screen.
[ ] 9. Sign-off: Release Manager: ___________________ Date: ____________
=============================================================================""")

    add_subsection_title(doc, "18.1.9", "Template 9: Operational Handover Sign-Off Form")
    add_code_block(doc,
"""=============================================================================
TEMPLATE 9: OPERATIONAL HANDOVER SIGN-OFF FORM
Project: Attendify  |  Handover Phase: Production Release 1.1
Transferring Entity: Engineering Project Team  |  Receiving Entity: Institutional IT
=============================================================================
VERIFICATION STATEMENT:
The Engineering Project Team hereby certifies that Attendify Release 1.1 has been
delivered in accordance with the Software Requirements Specification (SRS v1.1),
all 28 baseline deliverables are implemented and tested, and all architectural,
system analyst, and project management documentation has been authored.

ACKNOWLEDGMENT & ACCEPTANCE:
Institutional IT acknowledges receipt of source code repositories, cloud hosting
configurations, administrative database credentials, and operational runbooks.

TRANSFERRED BY:
Project Manager:      ________________________  Date: __________________
Lead Software Eng.:   ________________________  Date: __________________

ACCEPTED BY:
Institutional IT Dir: ________________________  Date: __________________
Student Affairs Dean: ________________________  Date: __________________
=============================================================================""")
