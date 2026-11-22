"""
content_part2.py - Chapters 9 through 16 for Attendify System Analyst Documentation.
"""

from .styles import (
    add_chapter_title, add_section_title, add_subsection_title,
    add_body_p, add_bullet_item, add_callout, add_styled_table, add_code_block
)

def build_part2(doc):
    # =========================================================================
    # CHAPTER 9: STUDENT PROFILE MANAGEMENT
    # =========================================================================
    add_chapter_title(doc, 9, "Student Profile Management")

    add_body_p(doc, "Attendify treats student records as authoritative institutional academic identities synchronized from the campus Student Information System (SIS). Consequently, student profiles are governed by strict immutability rules to ensure academic transcripts, disciplinary audits, and graduation clearances cannot be forged.")

    add_section_title(doc, "9.1", "Official Student Information Restrictions")
    add_body_p(doc, "The students table contains the following official institutional fields:")
    add_bullet_item(doc, "Unique numerical student matriculation identifier (e.g., '20260001'). Immutable.", bold_prefix="• student_id_number: ")
    add_bullet_item(doc, "Official legal name of the student. Immutable by student.", bold_prefix="• first_name, middle_name, last_name: ")
    add_bullet_item(doc, "Academic program of study (e.g., 'BS Information Technology').", bold_prefix="• course / degree program: ")
    add_bullet_item(doc, "Academic progression level (e.g., '1st Year', '2nd Year', '3rd Year', '4th Year').", bold_prefix="• year_level: ")
    add_bullet_item(doc, "Class cohort grouping (e.g., 'BSIT 3-A').", bold_prefix="• section: ")
    add_bullet_item(doc, "Higher academic unit (e.g., 'College of Computer Studies').", bold_prefix="• department: ")

    add_callout(doc, "Security Barrier: If an authenticated student client attempts to submit a PUT or POST request to /api/v1/profile with altered personal or academic fields, the backend AuthController strictly denies the operation with HTTP 403 Forbidden ('Student profiles are immutable institutional records') and logs the unauthorized modification attempt to activity_logs.", title="Profile Immutability Rule", alert_type="warning")

    add_section_title(doc, "9.2", "Student Discrepancy Correction Request Workflow")
    add_body_p(doc, "When a student legally changes their surname or transfers courses, they cannot self-edit their record. Instead, they submit a formal discrepancy ticket via POST /api/v1/profile/correction-request:")
    add_bullet_item(doc, "Student inputs requested field changes and provides an explanatory justification note.", bold_prefix="1. Submission: ")
    add_bullet_item(doc, "Backend validates input, ensures student has active status, and logs a 'profile_correction_requested' event in activity_logs.", bold_prefix="2. Logging & Notification: ")
    add_bullet_item(doc, "An Administrator reviews the student's supporting institutional paperwork and applies verified changes via the administrative endpoint PUT /api/v1/admin/students/{id}/profile.", bold_prefix="3. Administrative Review & Mutation: ")

    add_section_title(doc, "9.3", "Privacy Protections")
    add_body_p(doc, "In accordance with data privacy regulations, personal mobile phone numbers (contact_number) are omitted from public API representations and client profile screens. Avatar images (profile_photo_path) are served over secure URLs and utilized exclusively for on-screen physical identification during QR attendance check-in.")

    # =========================================================================
    # CHAPTER 10: EVENT MANAGEMENT
    # =========================================================================
    add_chapter_title(doc, 10, "Event Management and Lifecycle Governance")

    add_body_p(doc, "Events represent the central operational entity in Attendify. To prevent unauthorized campus gatherings or scheduling conflicts, event progression follows a formal finite state machine enforced at the model and controller layers.")

    add_section_title(doc, "10.1", "Event Finite State Machine")
    event_sm = (
        "                    [Event Created by Organizer]\n"
        "                                 |\n"
        "                                 v\n"
        "                           +------------+\n"
        "                           |   DRAFT    | <------------------+\n"
        "                           +------------+                     |\n"
        "                                 |                            |\n"
        "                      (Submit for Approval)                   |\n"
        "                                 v                            |\n"
        "                      +----------------------+\n"
        "                      |   PENDING_APPROVAL   |\n"
        "                      +----------------------+\n"
        "                        /                  \\\n"
        "       (Admin Rejected)/                    \\(Admin Approved)\n"
        "                      v                      v\n"
        "             [Reverted to DRAFT]        +-----------+\n"
        "                                        | PUBLISHED | <--- (Scanning Allowed)\n"
        "                                        +-----------+\n"
        "                                          /       \\\n"
        "                       (Scheduled Start) /         \\ (Admin Approved Cancel)\n"
        "                                        v           v\n"
        "                                  +-----------+  +-----------+\n"
        "                                  |  ONGOING  |  | CANCELLED |\n"
        "                                  +-----------+  +-----------+\n"
        "                                        |\n"
        "                                        | (Scheduled End)\n"
        "                                        v\n"
        "                                  +-----------+\n"
        "                                  | COMPLETED |\n"
        "                                  +-----------+\n"
    )
    add_code_block(doc, event_sm)

    add_section_title(doc, "10.2", "Detailed State Definitions & Transitions")
    state_headers = ["State Enum", "Allowable Actions", "Restricted Actions", "Trigger / Transition Event"]
    state_rows = [
        ["draft", "Edit all fields, delete draft, submit for approval", "Cannot register students, cannot scan QR codes", "Created via POST /api/v1/events with save_as_draft=true."],
        ["pending_approval", "View details, admin review (approve/reject)", "Cannot edit fields, cannot register students", "Submitted via POST /api/v1/events/{id}/submit-approval."],
        ["published", "Students register/join waiting list; QR scanning permitted", "Organizer cannot modify dates/venue without admin", "Approved via POST /api/v1/admin/events/{id}/review."],
        ["ongoing", "QR scanning active (check-in / check-out), live attendance monitor", "Registration closed (unless walk-in allowed)", "Triggered automatically when current time >= start_time."],
        ["completed", "Export reports, review analytics, submit corrections", "Scanning locked, registration permanently closed", "Triggered when current time > end_time via auto-close."],
        ["cancelled", "Review cancellation audit trail, export historical logs", "All operations locked; registrations marked cancelled", "Approved via POST /api/v1/admin/events/{id}/review-cancellation."]
    ]
    add_styled_table(doc, state_headers, state_rows, [1.2, 1.8, 1.8, 1.7])

    add_section_title(doc, "10.3", "Event Cancellation Governance")
    add_body_p(doc, "Event organizers cannot unilaterally cancel a published event. When cancellation is necessary (e.g., severe weather or speaker illness), the organizer calls POST /api/v1/events/{id}/request-cancellation with an explanatory reason. The event remains published until an Administrator reviews and approves the cancellation via POST /api/v1/admin/events/{id}/review-cancellation.")
    add_body_p(doc, "Upon administrative cancellation approval:")
    add_bullet_item(doc, "The event status transitions to 'cancelled'.", bold_prefix="1. Status Transition: ")
    add_bullet_item(doc, "All active registrations and waiting list entries are atomically updated to 'cancelled'.", bold_prefix="2. Roster Invalidation: ")
    add_bullet_item(doc, "EventNotificationService dispatches mandatory cancellation alerts (in-app + FCM push) to all registered and waitlisted students.", bold_prefix="3. Mandatory Alerts: ")

    # =========================================================================
    # CHAPTER 11: EVENT AUDIENCE TARGETING AND AUTOMATIC ASSIGNMENT
    # =========================================================================
    add_chapter_title(doc, 11, "Event Audience Targeting and Automatic Assignment")

    add_section_title(doc, "11.1", "Audience Targeting Modes")
    add_body_p(doc, "Events in Attendify can be open campus-wide or restricted to specific cohorts using four targeting types (target_audience_type column):")
    add_bullet_item(doc, "Event is visible and open for registration to every active student in the institution.", bold_prefix="1. 'all' (Campus-Wide): ")
    add_bullet_item(doc, "Restricted to students enrolled in specific academic degree programs (target_courses JSON array).", bold_prefix="2. 'course' (Program Specific): ")
    add_bullet_item(doc, "Restricted to specific student seniority levels (target_year_levels JSON array, e.g., ['1st Year', '2nd Year']).", bold_prefix="3. 'year_level' (Seniority Specific): ")
    add_bullet_item(doc, "Multi-dimensional targeting combining department, course, year level, and specific sections (target_sections JSON array).", bold_prefix="4. 'custom' (Cohort Granular): ")

    add_section_title(doc, "11.2", "Eligibility Evaluation Algorithm")
    add_body_p(doc, "Eligibility is evaluated dynamically on the backend via Event::isStudentEligible(?Student $student). When a student browses events (GET /api/v1/events) or attempts registration (POST /api/v1/events/{id}/register), the backend executes:")

    elig_code = (
        "public function isStudentEligible(?Student $student): bool {\n"
        "    if (!$student) return false;\n"
        "    $type = $this->target_audience_type ?? 'all';\n"
        "    if ($type === 'all' || empty($type)) return true;\n"
        "    if ($type === 'department') {\n"
        "        return in_array($student->department, $this->target_departments ?? [], true);\n"
        "    }\n"
        "    if ($type === 'course') {\n"
        "        return in_array($student->course, $this->target_courses ?? [], true);\n"
        "    }\n"
        "    if ($type === 'year_level') {\n"
        "        return in_array($student->year_level, $this->target_year_levels ?? [], true);\n"
        "    }\n"
        "    if ($type === 'custom') {\n"
        "        // Multi-attribute intersection check\n"
        "        $courseMatch = empty($this->target_courses) || in_array($student->course, $this->target_courses, true);\n"
        "        $yearMatch   = empty($this->target_year_levels) || in_array($student->year_level, $this->target_year_levels, true);\n"
        "        $secMatch    = empty($this->target_sections) || in_array($student->section, $this->target_sections, true);\n"
        "        return $courseMatch && $yearMatch && $secMatch;\n"
        "    }\n"
        "    return false;\n"
        "}\n"
    )
    add_code_block(doc, elig_code)

    add_section_title(doc, "11.3", "Automatic Announcement Dispatch")
    add_body_p(doc, "When an Administrator approves an event where send_announcement = true, the backend executes Event::eligibleStudentUserIds() to resolve all matching students across the campus database. It dispatches a broadcast notification informing them that registration has officially opened.")

    # =========================================================================
    # CHAPTER 12: EVENT CALENDAR AND DASHBOARD
    # =========================================================================
    add_chapter_title(doc, 12, "Event Calendar and Role Dashboards")

    add_section_title(doc, "12.1", "Interactive Event Calendar Architecture")
    add_body_p(doc, "The Calendar module provides a month-grid, week-agenda, and daily schedule interface for students and staff. Calendar events are filtered in real-time based on the user's role and student targeting eligibility.")
    add_bullet_item(doc, "Color-Coded Categories: Events are visually grouped by academic category: Academic (Teal #14B8A6), Cultural (Pink #EC4899), Sports (Amber #F59E0B), and General Seminars (Zinc #18181B).", bold_prefix="• Category Badges: ")
    add_bullet_item(doc, "Registration Status Overlay: For students, calendar tiles visually highlight whether the student is Registered (Green check), on the Waiting List (Orange clock), or Not Registered.", bold_prefix="• Registration Context: ")

    add_section_title(doc, "12.2", "Role-Tailored Dashboards")
    add_body_p(doc, "Each role is served by a dedicated backend dashboard aggregation endpoint:")
    add_bullet_item(doc, "GET /api/v1/dashboard/admin returns total user counts, active events, overall student attendance rate percentage, pending approval queues, and real-time activity log stream.", bold_prefix="1. Administrator Dashboard: ")
    add_bullet_item(doc, "GET /api/v1/dashboard/organizer returns active events managed by the authenticated organizer, upcoming events calendar, participant registration counts, and scanner shortcuts.", bold_prefix="2. Organizer Dashboard: ")
    add_bullet_item(doc, "GET /api/v1/dashboard/student returns upcoming registered events, active waiting list queue numbers, permanent QR status, and recent attendance verification history.", bold_prefix="3. Student Dashboard: ")
    add_bullet_item(doc, "GET /api/v1/dashboard/management returns macro-level institutional metrics, cross-department attendance rates, absentee trends, and audit trail summaries with zero edit controls.", bold_prefix="4. Management Dashboard: ")

    # =========================================================================
    # CHAPTER 13: PERMANENT QR CODE MANAGEMENT
    # =========================================================================
    add_chapter_title(doc, 13, "Permanent QR Code Management")

    add_section_title(doc, "13.1", "The Permanent QR Principle")
    add_body_p(doc, "Unlike legacy ticketing systems where a new QR code is generated for every event registration, Attendify assigns each student exactly ONE active permanent QR code. This architectural design yields major operational advantages:")
    add_bullet_item(doc, "Students can print their QR on physical ID badges, save it to their mobile wallet, or display it from the Attendify app. They never experience missing event tickets.", bold_prefix="• Frictionless Physical Integration: ")
    add_bullet_item(doc, "The physical QR contains zero names, birthdays, or emails. Intercepting a photograph of the QR yields only a cryptographic hash with zero personal information.", bold_prefix="• Privacy by Design: ")

    add_section_title(doc, "13.2", "Token Generation & Cryptographic Entropy")
    add_body_p(doc, "QR tokens are generated using cryptographically secure random byte generators:")
    add_code_block(doc, "$qrToken = bin2hex(random_bytes(32)); // 64 lowercase hexadecimal characters (256 bits of entropy)")
    add_body_p(doc, "With 256 bits of entropy, the probability of token collision or brute-force guessing is mathematically zero (less than 1 in 10^77).")

    add_section_title(doc, "13.3", "Self-Service & Administrative QR Reissuance")
    add_body_p(doc, "If a student loses their physical ID badge or suspects their QR was photographed, they can reissue a fresh token instantly via POST /api/v1/student/qr/reissue. Administrators can also force a reissue via POST /api/v1/admin/students/{id}/qr/reissue.")
    add_body_p(doc, "The reissuance sequence executes inside an ACID database transaction:")
    add_bullet_item(doc, "All existing active rows in student_qrs for this student are updated to status = 'revoked' and revoked_at = now().", bold_prefix="1. Revocation: ")
    add_bullet_item(doc, "A fresh 64-character token is inserted with status = 'active'.", bold_prefix="2. Generation: ")
    add_bullet_item(doc, "An immutable activity log entry ('qr_reissued') is written recording the operator's IP address and user agent.", bold_prefix="3. Audit Trail: ")

    # =========================================================================
    # CHAPTER 14: QR-BASED ATTENDANCE MANAGEMENT
    # =========================================================================
    add_chapter_title(doc, 14, "QR-Based Attendance Management")

    add_section_title(doc, "14.1", "Attendance Relational Schema")
    add_body_p(doc, "Attendance records are maintained in the attendances table, governed by a composite unique constraint on [event_id, student_id]. A student can have at most one attendance record per event.")

    att_schema_headers = ["Field Name", "Data Type", "Nullability", "Operational Purpose"]
    att_schema_rows = [
        ["id", "BIGINT UNSIGNED", "No (PK)", "Unique auto-incrementing attendance identifier."],
        ["event_id", "BIGINT UNSIGNED", "No (FK)", "Links to events.id. Cascades on event deletion."],
        ["student_id", "BIGINT UNSIGNED", "No (FK)", "Links to students.id. Cascades on student deletion."],
        ["event_registration_id", "BIGINT UNSIGNED", "Yes (FK)", "Links to original registration row (null for walk-in if unlinked)."],
        ["check_in_time", "DATETIME", "Yes", "Exact timestamp when student checked in at venue."],
        ["check_out_time", "DATETIME", "Yes", "Exact timestamp when student checked out at venue exit."],
        ["status", "ENUM", "No", "'present', 'absent', 'late', 'excused', 'walk_in'."],
        ["scanner_id", "BIGINT UNSIGNED", "Yes (FK)", "User ID of the organizer/admin whose camera scanned the QR code."]
    ]
    add_styled_table(doc, att_schema_headers, att_schema_rows, [1.5, 1.3, 1.0, 2.7])

    add_section_title(doc, "14.2", "Status Enum Definitions")
    add_bullet_item(doc, "Student pre-registered and checked in before or during the late grace period.", bold_prefix="• present: ")
    add_bullet_item(doc, "Student pre-registered but check-in timestamp exceeded the event start time plus late grace period.", bold_prefix="• late: ")
    add_bullet_item(doc, "Student pre-registered but never checked in before event conclusion.", bold_prefix="• absent: ")
    add_bullet_item(doc, "Student was officially excused from attendance by an administrator (e.g., medical leave).", bold_prefix="• excused: ")
    add_bullet_item(doc, "Student attended without pre-registration (admitted under walk-in policy).", bold_prefix="• walk_in: ")

    # =========================================================================
    # CHAPTER 15: CHECK-IN AND CHECK-OUT WORKFLOWS
    # =========================================================================
    add_chapter_title(doc, 15, "Check-In and Check-Out Workflows")

    add_section_title(doc, "15.1", "Real-Time QR Scanner Execution")
    add_body_p(doc, "Event staff scan student QR codes using the mobile scanner interface (POST /api/v1/events/{id}/attendance/scan). The request accepts two parameters: qr_token (64-char string) and mode ('check_in' or 'check_out'). The scanner route is rate-limited to 60 scans per minute per client IP (throttle:60,1) to prevent Denial of Service while permitting rapid scanning lines.")

    scan_flow = (
        "                    [Student Displays Permanent QR]\n"
        "                                 |\n"
        "                                 v\n"
        "                   [Organizer Scans via Camera]\n"
        "                                 |\n"
        "                                 v\n"
        "             POST /api/v1/events/{id}/attendance/scan\n"
        "             { qr_token: 'a9f8e...', mode: 'check_in' }\n"
        "                                 |\n"
        "                                 v\n"
        "            +---------------------------------------+\n"
        "            | 1. Validate Token in student_qrs      |\n"
        "            |    - Must exist & status = 'active'   |\n"
        "            +-------------------+-------------------+\n"
        "                                |\n"
        "                                v\n"
        "            +---------------------------------------+\n"
        "            | 2. Verify Event Status                |\n"
        "            |    - Must be 'published' or 'ongoing' |\n"
        "            +-------------------+-------------------+\n"
        "                                |\n"
        "                                v\n"
        "                      (Evaluate Mode)\n"
        "                      /             \\\n"
        "        [mode == 'check_in']         [mode == 'check_out']\n"
        "                 |                            |\n"
        "                 v                            v\n"
        "     +-----------------------+    +-----------------------+\n"
        "     | Check Prior Check-in  |    | Verify Prior Check-in |\n"
        "     | If yes: ERR_ALREADY_IN|    | If no: ERR_NO_CHECKIN |\n"
        "     +-----------+-----------+    +-----------+-----------+\n"
        "                 |                            |\n"
        "                 v                            v\n"
        "     +-----------------------+    +-----------------------+\n"
        "     | Evaluate Registration |    | Record check_out_time |\n"
        "     | - Registered:         |    | Return Success        |\n"
        "     |   Late vs Present     |    +-----------------------+\n"
        "     | - Unregistered:       |\n"
        "     |   Walk-in check       |\n"
        "     +-----------+-----------+\n"
        "                 |\n"
        "                 v\n"
        "     +---------------------------------------------------+\n"
        "     | Return Student Photo, Full Name, ID, Status       |\n"
        "     | -> Organizer Conducts On-Screen Visual Check      |\n"
        "     +---------------------------------------------------+\n"
    )
    add_code_block(doc, scan_flow)

    add_section_title(doc, "15.2", "Late Grace Period Calculation")
    add_body_p(doc, "Events define a late_grace_period_minutes attribute (default 15 minutes). When a pre-registered student checks in, the backend computes the late threshold:")
    add_code_block(doc, "$lateThreshold = Carbon::parse($event->event_date->format('Y-m-d') . ' ' . $event->start_time)\n"
                       "    ->addMinutes($event->late_grace_period_minutes);\n\n"
                       "if (now()->lte($lateThreshold)) {\n"
                       "    $status = 'present';\n"
                       "} else {\n"
                       "    $status = 'late';\n"
                       "}\n")

    add_section_title(doc, "15.3", "Walk-In Attendance Processing")
    add_body_p(doc, "If an unregistered student scans their QR code at the door:")
    add_bullet_item(doc, "If walk_in_allowed = false on the event, the request is immediately rejected with HTTP 422 Unprocessable Content ('ERR_NOT_REGISTERED').", bold_prefix="• Policy Rejection: ")
    add_bullet_item(doc, "If walk_in_allowed = true, the backend atomically creates an event_registrations row with status = 'walk_in', followed by an attendances row with status = 'walk_in' and check_in_time = now().", bold_prefix="• Automatic Walk-In Admission: ")

    add_section_title(doc, "15.4", "On-Screen Visual Identity Verification")
    add_body_p(doc, "To eliminate proxy scanning where a student carries another student's phone, the API scan response payload returns the student's legal name, numeric ID, course, section, and profile_photo_path. The mobile screen immediately presents the student's official photo avatar in a verified dialog, allowing the door staff to visually confirm the attendee's physical identity before admitting them.")

    # =========================================================================
    # CHAPTER 16: PARTICIPATION VERIFICATION AND ATTENDANCE CORRECTIONS
    # =========================================================================
    add_chapter_title(doc, 16, "Participation Verification and Attendance Corrections")

    add_section_title(doc, "16.1", "Post-Event Participation Audit")
    add_body_p(doc, "Following event completion, organizers and administrators review the attendance registry via GET /api/v1/events/{id}/attendance. Discrepancies may arise—for instance, a student was marked 'absent' due to battery failure, or marked 'late' due to documented institutional transit delays.")

    add_section_title(doc, "16.2", "Attendance Correction Entity & Rules")
    add_body_p(doc, "Attendance records cannot be silently updated or overwritten. Any status modification must proceed through the correction gateway at PUT /api/v1/attendance/{id}/correct.")
    add_body_p(doc, "The operation enforces three non-negotiable rules:")
    add_bullet_item(doc, "The operator must supply a mandatory 'reason' parameter string (minimum 5, maximum 500 characters) documenting the factual justification.", bold_prefix="1. Mandatory Reason: ")
    add_bullet_item(doc, "A permanent record is created in the attendance_corrections table capturing attendance_id, corrected_by (operator user ID), original_status, new_status, and reason.", bold_prefix="2. Relational History: ")
    add_bullet_item(doc, "An immutable entry is dispatched to activity_logs capturing the operational metadata, IP address, and timestamp.", bold_prefix="3. System Audit Log: ")
