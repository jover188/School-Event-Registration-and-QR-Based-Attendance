# Software Requirements Specification (SRS)

## School Event Registration and QR-Based Attendance Management System

**Project Type:** Mobile Application (`Flutter 3.x (Dart 3.x) — Android 8.0+ (API 26+) / iOS 13+`)\
**Backend:** `Laravel 11 / PHP 8.3+ REST API`\
**Database:** `MySQL 8.0+`\
**Push Notifications:** Firebase Cloud Messaging (FCM)\
**Development Approach:** Agile\
**Document Status:** Approved Finalized Requirements Baseline\
**Version:** 1.1\
**Last Updated:** 2026-10-08\
**Prepared for:** Development Team / Project Group\
**Source Basis:** Final_School_Attendance.pptx, previously agreed
project decisions, and finalized requirement decisions (Section 33)

> **Revision History:**
> - **v1.0** — Initial Requirements Baseline (filename `School_Event_Attendance_SRS_v1.0.md` retained for cross-document link stability).
> - **v1.1** — Finalized Requirements Baseline incorporating all resolved architectural and business rule decisions (Section 33).

------------------------------------------------------------------------

# 1. Introduction

## 1.1 Purpose

This Software Requirements Specification (SRS) defines the functional
and non-functional requirements for the School Event Registration and
QR-Based Attendance Management System.

The document is intended to serve as the group's official requirements
baseline before development. It describes what the system must do, who
will use it, the information it will manage, the business rules that
must be followed, the expected system behavior, security requirements,
constraints, and acceptance criteria.

The original project presentation identifies the need to improve a
school process currently involving event announcements, student
registration, attendance checking, attendance recording, and report
generation. The proposed system is intended to automate these activities
and centralize event, registration, and attendance information.

> **Requirement baseline note:** The presentation originally describes
> the proposed solution as a web-based system and lists
> React/HTML/CSS/JavaScript as possible frontend technologies. For the
> development version covered by this SRS, the frontend is changed to a
> **mobile application**, while the Laravel/PHP backend, MySQL database,
> REST API approach, QR attendance, and other core project requirements
> are retained.

## 1.2 Product Scope

The system will provide a centralized mobile platform for managing
school events and student participation.

The system will support:

-   Secure user authentication
-   Role-based access
-   Student profiles
-   Event creation and management
-   Online event registration
-   Optional participant limits and waiting lists
-   Walk-in attendance support
-   Permanent student QR codes
-   QR-based event attendance (check-in and check-out)
-   Automatic late detection
-   Real-time attendance monitoring
-   Push notifications
-   Search and filtering
-   Attendance and participation reports (PDF, CSV, Excel export)
-   Dashboard information
-   Activity logging
-   System administration
-   Database management

The system will be connected to a Laravel REST API and MySQL database.
The mobile application will not connect directly to the database.

## 1.3 Background

The project presentation identifies school events, seminars, activities,
and programs as situations where student registration and attendance
monitoring are required.

The existing workflow is:

**Event Announcement → Student Registration → Attendance Checking →
Attendance Recording → Report Generation**

The existing process may use paper forms, attendance sheets,
spreadsheets, and manual checking. The identified problems include
time-consuming registration, attendance delays, difficulty organizing
participant information, lack of centralized data, delayed reports, and
possible recording errors.

## 1.4 Objectives

### General Objective

To design and develop an integrated school event registration and
QR-based attendance management system that automates and improves the
existing event registration and attendance process through modern
programming technologies.

### Specific Objectives

The system aims to:

1.  Provide a user-friendly mobile interface for Android and iOS.
2.  Implement secure user authentication with self-registration and
    school email verification.
3.  Implement role-based authorization for four user classes.
4.  Automate event registration with optional participant limits and
    waiting lists.
5.  Automate attendance recording through QR scanning with check-in and
    check-out support.
6.  Provide real-time attendance monitoring with automatic late
    detection.
7.  Support walk-in attendance tracking.
8.  Generate accurate attendance and participation reports with PDF, CSV,
    and Excel export.
9.  Implement centralized database management.
10. Integrate relevant APIs and services where applicable.
11. Provide push notifications for important event and attendance
    activities.
12. Evaluate the system based on usability and functionality.

## 1.5 Intended Audience

This document is intended for:

-   Project developers
-   Database designers
-   UI/UX designers
-   System administrators
-   Event organizers/staff
-   School management
-   Project advisers/instructors
-   Testers and evaluators

------------------------------------------------------------------------

# 2. Overall Description

## 2.1 Product Perspective

The system will operate as a mobile client connected to a centralized
backend.

### High-Level Architecture

**Mobile Application → HTTPS REST API → Laravel/PHP Backend → MySQL
Database**

Supporting services:

-   **Firebase Cloud Messaging:** push notifications
-   **QR technology:** student identification and attendance
-   **Cloud/VPS:** backend deployment
-   **Git/GitHub:** version control and team collaboration

The mobile application is responsible for user interaction and device
functions such as displaying and scanning QR codes. Business rules,
authentication, authorization, attendance validation, and database
operations are handled by the backend.

## 2.2 User Classes

### 2.2.1 Administrator

The Administrator manages:

-   User accounts
-   Roles and permissions
-   System configuration
-   System records
-   Activity logs
-   Administrative monitoring
-   QR revocation/reissue oversight
-   Event approval

### 2.2.2 Event Organizer / Staff

The Event Organizer or Staff can:

-   Create events (subject to admin approval before publishing)
-   Edit/manage events
-   View registered students
-   Open the attendance scanner
-   Scan permanent student QR codes (check-in and check-out)
-   Monitor attendance
-   Generate event attendance reports
-   Correct attendance records when authorized

### 2.2.3 Student

Students can:

-   Self-register for an account using school email verification
-   Log in using school email or student ID + password
-   View available events
-   View event details
-   Register for events
-   Join waiting lists when events are full
-   Cancel event registration before the event starts
-   View their registration status
-   Access their permanent QR code
-   Self-service QR reissue (old QR auto-revoked)
-   Present their QR code for check-in and check-out attendance
-   Receive relevant notifications
-   View appropriate attendance/event information

**Required Student Profile Fields:**

-   Full name (first, middle, last)
-   Student ID number (numeric format, e.g., 20260001)
-   School email
-   Course / Program
-   Year level
-   Section
-   Department / College
-   Contact number
-   Profile photo

### 2.2.4 School Management

School Management has **read-only access** and can:

-   Monitor event participation
-   View dashboards
-   View attendance information
-   View and generate reports and analytics (including PDF, CSV, and Excel export)
-   View event details

School Management cannot create events, scan QR codes, or modify
records.

## 2.3 Operating Environment

### Mobile Application

-   **Framework:** Flutter 3.x (Dart 3.x) — Android 8.0+ (API 26+) / iOS 13+
-   **Android:** Minimum API 26 (Android 8.0 Oreo+)
-   **iOS:** Minimum iOS 13+
-   **Distribution:** Google Play Store and Apple App Store

### Backend

-   Laravel 11 / PHP 8.3+ REST API
-   HTTPS
-   Cloud/VPS hosting

### Database

-   MySQL 8.0+

### External Services

-   Firebase Cloud Messaging for push notifications

## 2.4 Design Constraints

The system is subject to the following constraints:

1.  The system is limited to authorized users.
2.  Internet/network connectivity is required for normal online
    operation.
3.  QR attendance depends on available smartphones or scanning devices.
4.  System availability depends on school hardware and network
    infrastructure.
5.  Third-party API features depend on external services (FCM).
6.  The mobile application targets Android 8.0+ (API 26+) and iOS 13+.
7.  The system enforces a single active session per user account (specifically preventing concurrent multi-device student logins; logging in on a new device invalidates any previous session token).
8.  Events require admin approval before publishing.
9.  Event cancellation requires admin approval.

## 2.5 Assumptions

The following assumptions are implementation requirements:

1.  Each student has one authorized account, created via self-registration
    with school email verification.
2.  Each student receives one permanent QR code using a cryptographically
    random 64-character hex token.
3.  The permanent QR code identifies the student's account but does not
    contain sensitive information.
4.  A student's permanent QR can be reused for multiple school events.
5.  Attendance is always associated with a specific event.
6.  Students must be registered for an event before normal QR attendance
    can be recorded, unless walk-in attendance is applicable.
7.  Walk-in students may be scanned and flagged separately as `walk_in`.
8.  The backend is the authoritative source for attendance records.
9.  Users have network access during normal registration and attendance
    operations.
10. Event organizers have permission to scan attendance.
11. Push notifications require Firebase Cloud Messaging and an
    appropriate device/network connection.
12. The system enforces a single active session per user account (logging in on a new device invalidates any previous session token, preventing concurrent multi-device student logins).
13. After QR scan, the organizer's device displays the student's photo,
    full name, student ID, and attendance status for visual identity verification.
14. Attendance supports both check-in and check-out scans.
15. Late attendance is auto-detected based on a configurable grace period
    after event start time.

------------------------------------------------------------------------

# 3. System Scope

## 3.1 In Scope

The first version includes:

-   Authentication (self-registration with school email verification)
-   Authorization (role-based, four user classes)
-   User management
-   Student management (with profile photo)
-   Event management (with admin approval workflow)
-   Event registration (with optional participant limits)
-   Waiting list (auto-promotion when slots open)
-   Walk-in attendance tracking
-   Permanent student QR (cryptographic token)
-   QR attendance (check-in and check-out)
-   Automatic late detection (configurable grace period)
-   Attendance monitoring (real-time)
-   Identity verification on scan (photo + name display)
-   Search and filtering
-   Notifications (in-app, 30-day retention)
-   Push notifications (FCM, 8 notification types)
-   Reports (7 report types, PDF/CSV/Excel export)
-   Dashboard (per-role dashboards)
-   Activity logs
-   System configuration
-   Database management
-   Password reset (email self-service + admin fallback)
-   Single-session enforcement

## 3.2 Out of Scope for Initial Release

The following are treated as future enhancements:

-   Offline attendance synchronization
-   NFC attendance
-   Digital certificates
-   Advanced predictive analytics
-   Extensive external API integrations
-   Full cloud backup / disaster recovery automation
-   AI-assisted features (chatbot, report summarization, etc.)
-   Other features not included in the approved requirements

The project presentation lists these as possible future enhancements.
For this SRS, mobile application (Flutter cross-platform) and push
notifications have been promoted into the current implementation scope.
AI features have been deferred to a future release.

------------------------------------------------------------------------

# 4. Functional Requirements

Requirement IDs use the following prefixes aligned with the document sections:

-   **AUTH** -- Authentication and authorization (Section 4.1)
-   **USER** -- User management (Section 5)
-   **EVENT** -- Event management (Section 6)
-   **REG** -- Event registration (Section 7)
-   **QR** -- Permanent student QR identity (Section 8)
-   **ATT** -- Attendance (Section 9)
-   **NOTIF** -- Notifications (Section 11)
-   **DASH** -- Dashboard (Section 12)
-   **SEARCH** -- Search and filtering (Section 13)
-   **REPORT** -- Reports and analytics (Section 14)
-   **LOG** -- Activity logs (Section 15)
-   **ADMIN** -- System administration (Section 16)
-   **BR** -- Business rules (Section 18)
-   **SEC** -- Security requirements (Section 21)
-   **NFR** -- Non-functional requirements (Section 22)

------------------------------------------------------------------------

## 4.1 Authentication and Authorization

### AUTH-001 Login

The system shall allow all authorized users to log in using their
registered school email address and password. Users with the **Student**
role may alternatively log in using their numeric Student ID number and
password.

### AUTH-002 Credential Validation

The backend shall validate submitted credentials before creating an
authenticated session.

### AUTH-003 Invalid Login

The system shall reject invalid login credentials and display an
appropriate error message.

### AUTH-004 Secure Password Storage

Passwords shall not be stored as plain text. The backend shall use
secure password hashing.

### AUTH-005 Session Management

The system shall maintain authenticated sessions/tokens securely.

### AUTH-006 Logout

Users shall be able to log out of the application.

### AUTH-007 Role-Based Authorization

The system shall restrict functions according to the user's assigned
role. The system supports four roles: Administrator, Event
Organizer/Staff, Student, and School Management.

### AUTH-008 Unauthorized Access

The API shall reject requests from users who do not have permission to
access the requested resource.

### AUTH-009 Student Self-Registration

Students shall be able to self-register for an account. The system shall
send a verification email to the student's school email address.
The account shall not be activated until the email is verified.

### AUTH-010 Password Reset (Email Self-Service)

Users shall be able to request a password reset via their registered
school email. The system shall send a secure, time-limited reset link.

### AUTH-011 Password Reset (Admin)

Administrators shall be able to manually reset a user's password as a
fallback when email self-service is unavailable.

### AUTH-012 Single Active Session

The system shall enforce a single active session per user account
(specifically preventing concurrent multi-device student logins). When a
user logs in on a new device, any existing session token on a previous
device shall be immediately invalidated.

### AUTH-013 Email Verification

The system shall verify the student's school email address during
self-registration before granting access.

------------------------------------------------------------------------

# 5. User Management Requirements

### USER-001 Account Creation

Authorized administrators shall be able to create user accounts for
non-student roles (organizers, school management). Students create their
own accounts via self-registration (AUTH-009).

### USER-002 Account Information

The system shall store necessary user information including name, email,
role, and account status.

### USER-003 Role Assignment

Authorized administrators shall be able to assign appropriate roles
(Administrator, Event Organizer/Staff, Student, School Management).

### USER-004 Account Status

The system shall support the following canonical account statuses:
`active`, `inactive`, and `pending` (pending email verification for
self-registered students).

### USER-005 Student Profile

The system shall maintain the following required student profile fields:

-   Full name (first, middle, last)
-   Student ID number (numeric format, e.g., 20260001)
-   School email address
-   Course / Program
-   Year level
-   Section
-   Department / College
-   Contact number
-   Profile photo (used for identity verification during QR scan)

### USER-006 Account Update

Authorized users shall be able to update permitted account/profile
information. Students may update their own permitted profile fields
(such as contact number, profile photo, and academic details if
permitted), except for their immutable `student_id_number` and school
`email`.

### USER-007 Account Deactivation

Administrators shall be able to deactivate accounts according to school
policy.

------------------------------------------------------------------------

# 6. Event Management Requirements

### EVENT-001 Create Event

Authorized event organizers shall be able to create school events.
Newly created events shall be in `draft` status.

### EVENT-002 Event Information

An event shall contain the following required fields:

-   Event title
-   Description
-   Date
-   Start time
-   End time
-   Venue/location
-   Registration start date/time
-   Registration end date/time
-   Event status
-   Organizer
-   Maximum participants (optional — leave blank for unlimited)
-   Late grace period in minutes (configurable, default 15 minutes)
-   Walk-in attendance allowed (yes/no, configurable per event)

### EVENT-003 Edit Event

Authorized organizers shall be able to update event information for
events they created (their own events), and Administrators may edit any
event.

### EVENT-004 Event Status

The system shall support the following canonical event states: `draft`,
`pending_approval` (displayed as Pending Approval), `published`
(displayed as Published/Open), `ongoing`, `completed`, and `cancelled`.
QR attendance scanning shall be permitted when an event is in `published`
or `ongoing` status.

### EVENT-005 Publish Event (Admin Approval Required)

When an organizer submits an event for publishing, the event shall
enter a `pending_approval` state. An administrator must approve the
event before it transitions to `published` and becomes visible to
students. The admin may reject the event with remarks, returning it to
`draft`.

### EVENT-006 Event Cancellation (Admin Approval Required)

Event organizers may request cancellation of an event they created. The
cancellation shall require administrator approval. Once approved, the
event transitions to `cancelled` and the system shall notify all
registered students of the cancellation.

### EVENT-007 Event Details

Students shall be able to view event information for published events
available to them, including remaining participant slots when a limit
is set.

### EVENT-008 Organizer Ownership

The system shall record which organizer created or manages an event.

------------------------------------------------------------------------

# 7. Event Registration Requirements

### REG-001 View Available Events

Students shall be able to view published events available for
registration, including remaining slots if a participant limit is set.

### REG-002 View Event Details

Students shall be able to view relevant event details before
registering.

### REG-003 Register

Students shall be able to submit a registration for an available event.
If capacity is available (or unlimited), the student is registered with
status `registered`. If the event has reached its `max_participants`
limit, the student shall be automatically placed on the ordered waiting
list with status `waiting_list` (REG-011).

### REG-004 Registration Validation

The backend shall validate that the event is open for registration
(status is `published` or `ongoing` and the current time is within the
registration window). If capacity is available (or `max_participants` is
null/unlimited), the student is assigned `registered` status; if
`max_participants` has been reached, the submission is accepted onto the
ordered waiting list with `waiting_list` status (REG-011) rather than
rejected.

### REG-005 Duplicate Registration

The system shall prevent a student from holding multiple active
registrations for the same event. The database enforces a unique
`(event_id, student_id)` constraint in `event_registrations`: if a
student whose registration was previously `cancelled` re-registers, or a
student on the `waiting_list` checks in as a `walk_in` (when walk-in is
enabled), the existing registration record is updated in place (and
remaining waiting list positions are re-indexed) rather than inserting a
duplicate row.

### REG-006 Registration Record

The system shall store the relationship between the student and event,
including registration date/time.

### REG-007 Registration Status

The system shall maintain the following canonical registration statuses:
`registered`, `waiting_list`, `cancelled`, and `walk_in`.

### REG-008 Registration Confirmation

The system shall provide confirmation after successful registration (or
waiting list placement) and send a push notification.

### REG-009 Registration Cancellation

Students shall be able to cancel their own registration before the event
starts. Authorized staff may also cancel a student's registration.

### REG-010 Registration Cutoff

The system shall prevent *new* student registration submissions after
the configured `registration_end` deadline. However, automatic waiting
list promotion (REG-011, BR-017) shall continue to operate whenever a
registered student cancels prior to the event start time (BR-021).

### REG-011 Waiting List

When an event has a maximum participant limit (`max_participants`) and
that limit is reached, new registration submissions shall be placed on
an ordered waiting list (`waiting_list` status with
`waiting_list_position`). Whenever a `registered` student cancels prior
to the event start time, the next student on the waiting list (lowest
`waiting_list_position`) shall be automatically promoted to `registered`
status, remaining waiting list positions re-indexed, and the promoted
student notified via push notification.

### REG-012 Capacity Display

The system shall display the current registration count and remaining
capacity for events with participant limits.

------------------------------------------------------------------------

# 8. Permanent Student QR Requirements

## 8.1 QR Concept

The student QR code is **permanent and student-specific**.

It is not generated separately for every event.

The same permanent QR code is used whenever the student attends an
eligible school event.

The QR code encodes a **cryptographically random 64-character
hexadecimal token**. It does not contain any personal student
information.

## 8.2 Requirements

### QR-001 Permanent QR

Each student shall have one permanent QR code associated with their
student account. The QR token shall be a cryptographically random
64-character hexadecimal string.

### QR-002 QR Uniqueness

Each active student QR identifier shall be unique within the system.

### QR-003 QR Reuse

A student's permanent QR shall be reusable across multiple events.

### QR-004 QR Access

The student shall be able to access/display their permanent QR in the
mobile application.

### QR-005 QR Scanning

An authorized event organizer shall be able to scan a student's
permanent QR using the mobile application.

### QR-006 Student Identification and Verification

When an organizer scans a student's permanent QR code (`POST /api/v1/events/{id}/attendance/scan` with `mode: check_in | check_out`), the backend atomically validates the QR token, event status, registration/walk-in eligibility, and duplicate scan status, records the check-in or check-out, and immediately returns the student's **profile photo, full name, student ID, and attendance status** for on-screen visual identity verification by the organizer (who may issue an audited correction via `ATT-011` if any discrepancy is observed).

### QR-007 Event Context

The attendance scanner shall operate in the context of a selected event.

### QR-008 Registration Validation

Before recording attendance, the backend shall verify that the student
is registered for the selected event. If walk-in attendance is enabled
for the event, unregistered students (or students currently on the
waiting list) shall be processed with `walk_in` status.

### QR-009 Duplicate Attendance Prevention

The system shall prevent multiple check-in records for the same
student and event. A separate check-out scan shall be permitted.

### QR-010 Invalid QR

The system shall reject QR tokens that are invalid, inactive, revoked,
or not associated with a student account.

### QR-011 Attendance Result

After a scan, the application shall display whether attendance was
successfully recorded or rejected and provide an appropriate reason.

### QR-012 QR Self-Service Reissue

Students shall be able to reissue their own QR code from within the
mobile application. When a new QR is issued, the old QR token shall be
automatically revoked and become invalid immediately.

### QR-013 QR Security

The QR token shall be cryptographically random and shall not expose
any student personal information.

------------------------------------------------------------------------

# 9. Attendance Requirements

### ATT-001 Event Scanner

Authorized event organizers shall be able to select an event (`published`
or `ongoing`) and open its attendance scanner. The scanner supports both
`check_in` and `check_out` modes.

### ATT-002 Scan Student QR

The organizer shall be able to scan a student's permanent QR for
check-in or check-out.

### ATT-003 Identify Student

Upon scanning, the backend shall identify the student using the QR token
and return their **profile photo, full name, student ID, and attendance
status** for immediate visual verification on the organizer's device.

### ATT-004 Verify Registration

The backend shall check whether the student has a `registered` record for
the selected event. If the student is not registered (or is on the
`waiting_list` or previously `cancelled`) and walk-in attendance is
enabled for the event, the student shall be flagged as `walk_in`.

### ATT-005 Record Attendance

For an eligible student, the system shall create an attendance record
with the appropriate status.

### ATT-006 Attendance Information

An attendance record shall contain:

-   Student (`student_id`)
-   Event (`event_id`)
-   Linked Registration (`event_registration_id`)
-   Check-in date/time (`check_in_time`)
-   Check-out date/time (`check_out_time`, when applicable)
-   Attendance status (`present`, `absent`, `late`, `excused`, `walk_in`)
-   Scanner/organizer (`scanner_id`, stored for auditability)

### ATT-007 Duplicate Check

The system shall detect an existing check-in record for the
student/event combination.

### ATT-008 Duplicate Response

If check-in has already been recorded, the system shall inform the
organizer rather than creating another check-in record.

### ATT-009 Real-Time Monitoring

Authorized organizers and school management shall be able to view
updated attendance information in real time.

### ATT-010 Attendance Search

Authorized users shall be able to search/filter attendance records.

### ATT-011 Attendance Correction

Administrators and the event's owning Event Organizer/Staff shall be
able to manually correct attendance records. Every correction requires a
mandatory `reason` and shall be recorded in both the dedicated
`attendance_corrections` table and `activity_logs` with
`original_status`, `new_status`, `reason`, and `corrected_by`.

### ATT-012 Automatic Late Detection

If a registered student's check-in scan occurs after the event's start
time plus the configured late grace period (default 15 minutes), the
attendance status shall be automatically set to `late` instead of
`present`.

### ATT-013 Check-Out

The system shall support a check-out scan for each checked-in student
per event. The check-out time (`check_out_time`) shall be recorded in
the attendance record.

### ATT-014 Walk-In Attendance

When an event has walk-in attendance enabled (`walk_in_allowed = true`),
unregistered students (or students on the `waiting_list` or with a
`cancelled` registration) may have their QR scanned. To preserve the
unique `(event_id, student_id)` constraint in `event_registrations`, the
system shall create a new registration record with `walk_in` status or
update the student's existing `waiting_list`/`cancelled` record to
`walk_in` (re-indexing remaining waiting list positions if applicable),
and create a linked attendance record with `walk_in` status.

### ATT-015 Attendance Status Values

The system shall support the following canonical attendance statuses:
`present`, `absent`, `late`, `excused`, and `walk_in`.

### ATT-016 Student Attendance History

Students shall be able to view their own check-in and check-out
attendance history across events.

------------------------------------------------------------------------

# 10. Attendance Processing Flow

## 10.1 Check-In Flow

The official atomic check-in flow (`POST /api/v1/events/{id}/attendance/scan` with `mode: "check_in"`) shall be:

1.  Student logs in.
2.  Student registers for the event (or arrives as a walk-in if enabled).
3.  Student accesses their permanent QR.
4.  Student attends the event.
5.  Organizer selects the event in the scanner (`check_in` mode).
6.  Organizer scans the student's permanent QR.
7.  Mobile application sends the `qr_token`, event ID, and `mode: "check_in"` to the backend.
8.  Backend validates that the QR token exists and is `active`, and resolves the student profile.
9.  Backend verifies the event status is `published` or `ongoing`.
10. Backend checks whether a check-in record already exists for `(event_id, student_id)`.
11. Backend verifies the student's registration (if `registered`, eligible for normal check-in; if unregistered or on `waiting_list`/`cancelled` and `walk_in_allowed` is enabled, eligible as `walk_in`).
12. Backend determines attendance status: `present` or `late` (based on event start time + late grace period) for registered students, or `walk_in` for walk-in students.
13. Within a database transaction, the backend creates (or updates to `walk_in`) the `event_registrations` record if walk-in, creates the `attendances` record, and logs the action in `activity_logs`.
14. The backend returns the student's **profile photo, full name, student ID, and assigned attendance status (`present`, `late`, or `walk_in`)** to the mobile scanner.
15. The scanner displays the verification card (photo, full name, student ID, and status badge) so the organizer visually verifies the student's identity on the spot (and can invoke an audited correction via `ATT-011` if any discrepancy is found).
16. The attendance dashboard updates in real time.

## 10.2 Check-Out Flow

The official atomic check-out flow (`POST /api/v1/events/{id}/attendance/scan` with `mode: "check_out"`) shall be:

1.  Organizer switches scanner to `check_out` mode.
2.  Organizer scans the student's permanent QR.
3.  Backend validates the active QR token, identifies the student, and verifies an existing check-in record without a prior `check_out_time`.
4.  Backend records `check_out_time` on the attendance record and logs the check-out in `activity_logs`.
5.  Scanner displays the student's **profile photo, full name, student ID, and check-out confirmation** for visual identity verification by the organizer.

The backend shall be the authority for deciding whether an attendance
record is valid.

------------------------------------------------------------------------

# 11. Notification Requirements

### NOTIF-001 Push Notification Support

The system shall support push notifications through Firebase Cloud
Messaging.

### NOTIF-002 Notification Events

The system shall support the following notification types:

-   New event published
-   Registration confirmation
-   Event reminder (24 hours and 1 hour before event start)
-   Event update/changes
-   Event cancellation
-   Attendance recorded confirmation
-   Waiting list promotion (slot opened)
-   Admin announcements

### NOTIF-003 Notification Permission

The application shall request the appropriate device notification
permission where required by Android and iOS.

### NOTIF-004 Notification Registration

The system shall associate an authenticated user's device notification
token with the user's account as required.

### NOTIF-005 Notification History

The application shall provide an in-app notification history.
Notification history shall be retained for **30 days**, after which
notifications are automatically purged.

### NOTIF-006 Notification Failure

The system shall handle notification-service failures without corrupting
event, registration, or attendance records.

### NOTIF-007 Event Reminders

The system shall automatically send event reminders at two intervals:
**24 hours** and **1 hour** before the event start time, to all
registered students.

### NOTIF-008 Notification Preferences

Users may toggle optional notification types on/off in their settings.
**Critical notifications** (event cancellation, attendance recorded)
**are mandatory** and cannot be disabled.

------------------------------------------------------------------------

# 12. Dashboard Requirements

### DASH-001 Student Dashboard

The student dashboard shall display relevant information such as:

-   Available events
-   Registered events
-   Upcoming events
-   Registration status (including waiting list position)
-   Attendance history (check-in and check-out records)
-   Notifications
-   Permanent QR access

### DASH-002 Organizer Dashboard

The organizer dashboard shall provide information such as:

-   Managed events
-   Registration counts
-   Attendance counts
-   Event status
-   Attendance monitoring

### DASH-003 Management Dashboard

School Management shall have read-only access to view approved event
participation, attendance summaries, analytics, and report generation
and export (PDF, CSV, Excel).

### DASH-004 Administrator Dashboard

The Administrator shall be able to view appropriate system information
and administrative activity.

------------------------------------------------------------------------

# 13. Search and Filtering Requirements

### SEARCH-001 Event Search

Authorized users shall be able to search events.

### SEARCH-002 Event Filtering

The system shall support appropriate filters such as event status/date
where implemented.

### SEARCH-003 Student Search

Authorized staff shall be able to search student records according to
their permissions.

### SEARCH-004 Attendance Filtering

Authorized staff shall be able to filter attendance records by event,
student, date, and/or status where applicable.

------------------------------------------------------------------------

# 14. Reports and Analytics Requirements

### REPORT-001 Event Attendance Report

Authorized users shall be able to generate an attendance list for a
specific event, showing all registered and walk-in students with their
attendance status (`present`, `absent`, `late`, `excused`, `walk_in`),
check-in time, and check-out time.

### REPORT-002 Registration Report

Authorized users shall be able to view event registration information
per event, including registration status (`registered`, `waiting_list`,
`cancelled`, `walk_in`).

### REPORT-003 Participation Summary

The system shall provide an overall participation summary across all
events, including total registrations, total attendance, and attendance
rates.

### REPORT-004 Student Attendance History

Authorized users (Administrators, Event Organizers/Staff, and School
Management) shall be able to generate a report showing a specific
student's attendance history across events, while Students may view
their own attendance history via `ATT-016`.

### REPORT-005 Absentee Report

Authorized users shall be able to generate a report of students who
registered for an event but did not attend.

### REPORT-006 Walk-In Report

Authorized users shall be able to generate a report of students who
attended an event without pre-registration (walk-in attendees).

### REPORT-007 Organizer Summary

Authorized users shall be able to generate a summary of events managed
per organizer, including event count, total registrations, and total
attendance.

### REPORT-008 Report Accuracy

Reports shall be generated from authoritative database records.

### REPORT-009 Report Filtering

Authorized users shall be able to filter reports by event, date range,
student, department, year level, and attendance status.

### REPORT-010 Export

The system shall support exporting reports in the following formats:

-   **PDF** — formatted printable reports
-   **CSV** — raw data export for spreadsheet processing
-   **Excel (.xlsx)** — formatted spreadsheet export

### REPORT-011 Report Logging

Report generation does not require approval. However, all report
generation and export actions shall be recorded in the activity log.

------------------------------------------------------------------------

# 15. Activity Logging Requirements

### LOG-001 Activity Recording

The system shall record important administrative and operational
activities.

### LOG-002 Logged Information

Each activity log record in `activity_logs` shall include the canonical
fields:

-   `user_id` (acting user, nullable for system actions)
-   `action` (operation identifier, e.g., `user_logged_in`, `attendance_checked_in`)
-   `module` (affected subsystem, e.g., `auth`, `events`, `attendance`, `reports`)
-   `record_id` (affected primary key ID, nullable)
-   `metadata` (JSON object with contextual details such as old/new values or export parameters)
-   `ip_address` (client IP address, nullable)
-   `user_agent` (client user agent string, nullable)
-   `created_at` (timestamp of the action)

### LOG-003 Auditability

Activity logs shall help authorized administrators determine who
performed important actions and when.

### LOG-004 Log Protection

Normal users shall not be able to modify or delete audit records unless
specifically authorized.

------------------------------------------------------------------------

# 16. System Administration Requirements

### ADMIN-001 User Administration

Administrators shall manage authorized user accounts.

### ADMIN-002 Role Administration

Administrators shall manage roles and permissions according to the
approved access model.

### ADMIN-003 System Configuration

Authorized administrators shall manage approved system settings.

### ADMIN-004 QR Administration

Authorized administrators shall be able to view QR status and
revoke/reissue QR codes when required.

### ADMIN-005 System Monitoring

Administrators shall have access to appropriate system and activity
information.

------------------------------------------------------------------------

# 17. AI-Assisted Requirements

> **Decision:** AI-assisted features have been **cancelled** for this
> release and are deferred to a future version. This includes AI
> chatbot/assistant, AI report summarization, and AI-generated event
> descriptions. All attendance decisions, report generation, and data
> processing shall be handled by backend business rules and database
> records only.

------------------------------------------------------------------------

# 18. Business Rules

The following rules define core system behavior.

### BR-001

Only authenticated users may access protected system functions.

### BR-002

Users may only access functions permitted by their role.

### BR-003

A student may submit a registration only for events currently open for
registration (`published` or `ongoing` within the registration window).
If participant capacity is available (or unlimited), the student is
registered with `registered` status; if `max_participants` has been
reached, the student is automatically placed on the ordered waiting list
with `waiting_list` status (`REG-011`).

### BR-004

A student may not hold multiple active registrations for the same event.
The `(event_id, student_id)` pair is unique in `event_registrations`:
re-registering after a `cancelled` registration or checking in as a
`walk_in` from the `waiting_list` updates the existing registration
record in place.

### BR-005

Each student has one permanent active QR identity (cryptographic token).

### BR-006

The same student QR may be used for multiple events.

### BR-007

A QR code does not itself represent attendance.

### BR-008

Attendance belongs to a specific student-event combination.

### BR-009

When a student's permanent QR is scanned (`POST /api/v1/events/{id}/attendance/scan`),
the backend atomically validates eligibility, records the check-in or
check-out, and immediately returns the student's **profile photo, full
name, student ID, and attendance status** to the organizer's device for
on-screen visual identity verification (with audited correction
available via `ATT-011` if any discrepancy is observed).

### BR-010

The backend must validate the QR, event, student, registration, and
duplicate-attendance conditions.

### BR-011

A student receives one check-in and one check-out record per event.

### BR-012

Important administrative actions shall be recorded in the activity log.

### BR-013

Official attendance reports must be based on database records.

### BR-014

If an event is cancelled (with admin approval), new
registrations/attendance shall be blocked and registered students shall
be notified.

### BR-015

Events require administrator approval before publishing.

### BR-016

Event cancellation requires administrator approval.

### BR-017

When an event with a participant limit has a `registered` slot cancelled
prior to the event start time (`BR-021`), the next student on the
ordered waiting list (`waiting_list`) shall be automatically promoted to
`registered` status (even if the `registration_end` cutoff for new
submissions has passed).

### BR-018

Walk-in attendance is only permitted when explicitly enabled per event.

### BR-019

Late attendance is automatically determined by the system based on the
event's configured grace period after the start time.

### BR-020

The system enforces a single active session per user account
(specifically preventing concurrent multi-device student logins). A new
login invalidates any existing session token.

### BR-021

Students may cancel their own registration only before the event starts.

### BR-022

Manual attendance corrections require a mandatory `reason` and must be
recorded in both the `attendance_corrections` table and `activity_logs`
with `original_status`, `new_status`, `reason`, and `corrected_by`.

### BR-023

Notification history is retained for 30 days before automatic purging.

### BR-024

Report generation is logged but does not require approval.

------------------------------------------------------------------------

# 19. Data Requirements

## 19.1 Major Entities

The system requires the following **13 core domain tables** (plus
framework support tables `personal_access_tokens` and
`password_reset_tokens`):

1.  **Roles (`roles`)** — Fixed role definitions (`administrator`,
    `organizer`, `student`, `management`); role-based permissions are
    mapped directly to these 4 fixed roles.
2.  **Users (`users`)** — Authentication credentials, role assignment,
    account status (`pending`, `active`, `inactive`), and
    `active_session_id`.
3.  **Students (`students`)** — Student profile details including numeric
    `student_id_number`, academic info, and `profile_photo_path`.
4.  **Student QR Codes (`student_qrs`)** — Permanent 64-character hex QR
    tokens (`active` / `revoked`) with revocation history.
5.  **Events (`events`)** — Event details, schedule, registration window,
    `max_participants`, `late_grace_period_minutes`, `walk_in_allowed`,
    and lifecycle `status`.
6.  **Event Approvals (`event_approvals`)** — Administrator review
    records for event `publish` and `cancellation` requests.
7.  **Event Registrations (`event_registrations`)** — Student-event
    registration records with `status` (`registered`, `waiting_list`,
    `cancelled`, `walk_in`) and `waiting_list_position`.
8.  **Attendances (`attendances`)** — Event attendance records with
    `check_in_time`, `check_out_time`, `status` (`present`, `absent`,
    `late`, `excused`, `walk_in`), and `scanner_id`.
9.  **Attendance Corrections (`attendance_corrections`)** — Audit trail
    of manual attendance status changes (`attendance_id`, `corrected_by`,
    `original_status`, `new_status`, `reason`).
10. **Notifications (`notifications`)** — In-app notification records
    retained for 30 days.
11. **Notification Preferences (`notification_preferences`)** — Per-user
    toggle settings for optional notification types.
12. **Device Tokens (`device_tokens`)** — Registered FCM device tokens
    (`android`, `ios`) for push notifications.
13. **Activity Logs (`activity_logs`)** — Immutable system-wide audit
    log records.

For the permanent QR requirement, the QR entity (`student_qrs`) has the
following structure:

**StudentQR (`student_qrs`)** — `id`, `student_id`, `qr_token` (64-char
hex), `status` (`active`/`revoked`), `created_at`, `updated_at`,
`revoked_at`

A separate `student_qrs` entity is required because students can
self-service reissue their QR, creating a new active token and revoking
the previous one while preserving audit history.

## 19.2 Core Relationships

-   One Role can be assigned to many Users.
-   One User (with the Student role) has one Student profile.
-   One Student can own many Student QR records over time, with at most
    one `active` permanent Student QR at any time.
-   One Student can have many Event Registrations.
-   One Event can have many Event Registrations (including ordered
    `waiting_list` registrations).
-   One Event Registration can have zero or one linked Attendance record.
-   One Event can have many Attendance records.
-   One Student can have many Attendance records across events.
-   One User (Organizer/Staff or Admin) can scan many Attendance records.
-   One Attendance record can have many Attendance Correction records.
-   One User (Organizer/Staff or Admin) can perform many Attendance
    Corrections.
-   One User (Event Organizer/Staff) can organize many Events.
-   One Event can have one or more Event Approval records.
-   One User (Administrator) can review many Event Approval records.
-   One User can receive many Notifications.
-   One User has one Notification Preference record.
-   One User can register many Device Tokens.
-   One User can trigger many Activity Log records.

## 19.3 Data Integrity

The database shall enforce appropriate uniqueness and foreign-key
constraints.

Required constraints:

-   Unique user/account identifier (`users.id`) and unique school email
    (`users.email`)
-   Unique student user link (`students.user_id`) and unique numeric
    student ID number (`students.student_id_number`)
-   Globally unique `qr_token` in `student_qrs` (`student_qrs.qr_token`)
    and application-enforced single `active` QR per student
-   Unique student-event registration (`UNIQUE (event_id, student_id)`
    in `event_registrations`; re-registration after cancellation or
    walk-in promotion from waiting list updates the existing record)
-   Unique student-event attendance record (`UNIQUE (event_id, student_id)`
    in `attendances`)
-   Unique notification preference record per user
    (`notification_preferences.user_id`)
-   Unique FCM device token (`device_tokens.fcm_token`)
-   Valid foreign-key relationships across all 13 tables

------------------------------------------------------------------------

# 20. API Requirements

The mobile application shall communicate with the Laravel backend
through authenticated REST API endpoints.

## 20.1 API Principles

1.  All protected endpoints require authentication.
2.  Authorization shall be checked on the server.
3.  Input shall be validated.
4.  API responses shall use consistent status/error structures.
5.  Sensitive information shall not be unnecessarily returned.
6.  The mobile application shall not connect directly to MySQL.
7.  Attendance decisions shall be made by the backend.

## 20.2 API Groups

The exact endpoint names are specified in `REST_API_Specification.md` and
`openapi.yaml` under `/api/v1`.

### Authentication

-   Self-register (student)
-   Verify email / resend verification
-   Login (email + password for all roles, or numeric student ID + password for students)
-   Logout
-   Password reset request (email self-service)
-   Password reset confirm
-   Change password (authenticated)
-   Current user/profile view and update

### Users & Administration

-   Create user (admin — for Organizer and School Management accounts)
-   List users (admin)
-   View user details (admin)
-   Update user / account status / deactivate user (admin)
-   Manual password reset fallback (admin)
-   View system activity logs (admin)

### Events

-   List events (with search and status/date filters)
-   View event details (with remaining capacity)
-   Create event (organizer/admin)
-   Update event (owning organizer/admin)
-   Submit event for approval (owning organizer)
-   Approve/reject event publication (admin)
-   Request event cancellation (owning organizer)
-   Approve/reject event cancellation (admin)

### Registration

-   Register for event (places on waiting list if at capacity)
-   View student's own registrations and waiting list positions
-   Cancel registration (triggers automatic waiting list promotion)
-   View event registrations and waiting list (organizer/admin/management)

### QR

-   Get permanent student QR (`my-qr`)
-   Reissue QR (student self-service, auto-revokes prior QR)
-   Admin QR history inspection and revocation/reissue (`admin`)

### Attendance

-   Atomic QR scan (`POST /api/v1/events/{id}/attendance/scan` with `mode: check_in | check_out`)
-   Live event attendance summary and attendee list
-   View student's own attendance history (`GET /api/v1/my-attendances`)
-   Manual attendance record correction with mandatory reason (`ATT-011`)

### Notifications

-   Register / remove FCM notification device token
-   List in-app notifications (30-day retention)
-   Mark notification(s) as read
-   View and update notification preferences

### Dashboards

-   Student dashboard summary
-   Organizer dashboard summary
-   School Management dashboard summary
-   Administrator dashboard summary

### Reports

-   Event attendance report
-   Registration report
-   Participation summary
-   Student attendance history report
-   Absentee report
-   Walk-in report
-   Organizer summary report
-   Export any report (`PDF`, `CSV`, `Excel .xlsx`)

------------------------------------------------------------------------

# 21. Security Requirements

The project presentation identifies authentication, role-based
authorization, password encryption, input validation, API
authentication, database security, activity logging, and secure session
management as security features.

### SEC-001 Authentication

The system shall authenticate users before allowing access to protected
resources.

### SEC-002 Authorization

The backend shall enforce role-based access control.

### SEC-003 Password Security

Passwords shall be securely hashed.

### SEC-004 Input Validation

All important user input shall be validated on the server.

### SEC-005 API Security

Protected API endpoints shall require valid authentication.

### SEC-006 HTTPS

Client-server communication shall use HTTPS in production.

### SEC-007 Database Security

Database credentials and connection information shall not be exposed in
the mobile application.

### SEC-008 Secrets

API keys, database passwords, and notification-service
credentials shall not be hard-coded into the mobile application or
public source repository.

### SEC-009 QR Token Security

QR tokens shall be cryptographically random 64-character hex strings
and shall not contain personal student information.

### SEC-010 Activity Logging

Important security-sensitive and administrative actions shall be logged.

### SEC-011 Session Security

Authentication tokens/session credentials shall be handled securely.

### SEC-012 Rate Limiting

The backend should apply appropriate rate limiting to sensitive
endpoints, especially authentication and attendance-scanning endpoints.

------------------------------------------------------------------------

# 22. Non-Functional Requirements

## 22.1 Usability

### NFR-001

The application shall provide a simple and understandable mobile
interface.

### NFR-002

Common tasks such as event registration and QR attendance shall require
a reasonable number of steps.

### NFR-003

Success and error messages shall be understandable to users.

## 22.2 Performance

### NFR-004

Normal API operations should respond within an acceptable time under
expected school usage.

### NFR-005

QR scanning and attendance confirmation should provide feedback quickly
enough for practical event check-in.

The exact performance target must be finalized through testing.

## 22.3 Reliability

### NFR-006

The system shall preserve attendance and registration data when a valid
transaction is completed.

### NFR-007

A failed push notification shall not cause loss of the underlying event
or attendance record.

## 22.4 Availability

### NFR-008

The deployed backend should be available during expected school
operating/event periods.

Actual availability targets depend on the selected hosting environment.

## 22.5 Maintainability

### NFR-009

The system should use modular backend and mobile application structures.

### NFR-010

The project shall use Git/GitHub for source control and team
collaboration.

### NFR-011

Configuration values and secrets should be separated from application
source code.

## 22.6 Scalability

### NFR-012

The database and API design should support growth in users, events,
registrations, and attendance records.

## 22.7 Compatibility

### NFR-013

The application shall support Android (minimum API 26 / Android 8.0
Oreo) and iOS (minimum iOS 13) via Flutter cross-platform development.

------------------------------------------------------------------------

# 23. User Permission Matrix

  -------------------------------------------------------------------------------
  Function              Administrator   Organizer/Staff   Student        School
                                                                         Management
  --------------------- --------------- ----------------- -------------- ----------
  Login                 Yes             Yes               Yes            Yes

  Self-Register         No              No                Yes            No

  Manage Users          Yes             No                No             No

  Manage Roles          Yes             No                No             No

  View Events           Yes             Yes               Yes            Yes (RO)

  Create Events         Yes             Yes               No             No

  Edit Events           Yes             Own               No             No

  Approve/Reject Event  Yes             No                No             No

  Cancel Event Request  Yes             Own               No             No

  Approve Cancellation  Yes             No                No             No

  Register for Event    No              No                Yes            No

  Cancel Registration   Yes             Yes               Own (before    No
                                                          event)

  View Registrations    Yes             Yes               Own            Yes (RO)

  View Waiting List     Yes             Yes               Own position   Yes (RO)

  Scan Student QR       Yes             Yes               No             No

  View Attendance       Yes             Yes               Own            Yes (RO)

  Correct Attendance    Yes             Own               No             No

  Generate Reports      Yes             Yes               No             Yes (RO)

  Export Reports        Yes             Yes               No             Yes (RO)

  Manage System         Yes             No                No             No
  Settings

  View Activity Logs    Yes             No                No             No

  Receive Notifications Yes             Yes               Yes            Yes

  QR Self-Reissue       No              No                Yes            No

  Manage QR (admin)     Yes             No                No             No

  Notification          Yes             Yes               Yes            Yes
  Preferences
  -------------------------------------------------------------------------------

**(RO)** = Read-Only access. School Management cannot create, edit, or
delete any records. **(Own)** = Scoped to events created/owned by that
Event Organizer/Staff user.

------------------------------------------------------------------------

# 24. User Workflows

## 24.1 Student Workflow

**Self-Register → Verify Email → Login → View Available Events → Select
Event → View Details → Register (or Automatic Waiting List Placement if
at Capacity) → Registration Confirmed → Attend Event → Open Permanent QR
→ Present QR → Organizer Scans QR (Check-In Mode) → Backend Atomically
Validates & Records Check-In (`present` / `late` / `walk_in`) → Scanner
Displays Student Photo, Name, Student ID & Status Badge for Visual
Identity Verification → [Check-Out Scan] → Backend Records Check-Out &
Displays Visual Confirmation**

## 24.2 Organizer Workflow

**Login → Create Event → Submit for Admin Approval → [Admin Approves] →
Event Published → View Registered Students → Select Event → Open QR
Scanner (Check-In Mode) → Scan Permanent Student QR → Backend Atomically
Validates QR, Event, Registration/Walk-in & Late Status and Records
Check-In → Visually Verify Student Identity on Screen (Photo + Name +
Student ID + Status Badge; Issue Audited Correction via `ATT-011` if
Discrepancy Found) → [Switch to Check-Out Mode] → Scan for Check-Out &
Visually Verify Student Identity → Monitor Attendance → Generate Report
→ Export (PDF/CSV/Excel)**

## 24.3 Administrator Workflow

**Login → Administration Dashboard → Approve/Reject Events →
Manage Users/Roles/System Settings → Monitor Activity → Manage QR
Status → Reset Passwords → Review System Records → Review Activity
Logs**

## 24.4 School Management Workflow (Read-Only)

**Login → Dashboard → View Event Participation → View Attendance →
View Reports/Analytics → Export Reports**

------------------------------------------------------------------------

# 25. Error and Exception Handling

The system shall provide appropriate responses for common errors and
status conditions.

Examples include:

-   Invalid login credentials
-   Expired/invalid authentication
-   Unauthorized access
-   Event not found
-   Event pending approval (not yet published)
-   Event registration closed
-   Event at full capacity (automatically placed on waiting list)
-   Duplicate registration
-   Invalid QR
-   Revoked QR
-   Student not registered for event (walk-in disabled)
-   Duplicate check-in
-   Check-out without check-in
-   Cancelled event
-   Registration cancellation after event started
-   Network failure
-   Server error
-   Notification-service failure
-   Email verification expired/invalid

Error messages shall not expose sensitive system information.

------------------------------------------------------------------------

# 26. Testing Requirements

The project presentation identifies six main testing categories.

## 26.1 Functional Testing

Verify that each function works according to its requirement.

Examples:

-   Login
-   Event creation
-   Registration
-   QR scanning
-   Attendance recording
-   Notifications
-   Reports

## 26.2 Integration Testing

Verify communication between:

-   Mobile app and API
-   API and database
-   API and FCM
-   QR scanner and attendance endpoint

## 26.3 Usability Testing

Evaluate whether intended users can understand and complete important
tasks.

## 26.4 Security Testing

Test:

-   Unauthorized access
-   Role restrictions
-   Invalid tokens
-   Input validation
-   Authentication
-   Sensitive-data exposure

## 26.5 Performance Testing

Test the system under expected event usage, particularly QR scanning and
attendance recording.

## 26.6 User Acceptance Testing

Representatives of the intended user groups shall evaluate whether the
system satisfies approved requirements.

------------------------------------------------------------------------

# 27. Acceptance Criteria

The system will be considered ready for release when all approved
requirements have been implemented and verified.

Minimum acceptance criteria:

1.  Students can self-register and verify their school email address (`AUTH-009`, `AUTH-013`).
2.  Authorized users can log in securely using email + password (all roles) or numeric Student ID + password (Students), with single active session enforcement invalidating prior device tokens (`AUTH-001`, `AUTH-012`).
3.  Unauthorized users cannot access protected functions, and role permissions work strictly according to the Permission Matrix (`AUTH-007`, `AUTH-008`, Section 23).
4.  Organizers can create and manage their own events, and events require Administrator approval before publication or cancellation (`EVENT-001` to `EVENT-006`).
5.  Students can view published events, remaining capacity, and event details (`REG-001`, `REG-002`, `REG-012`).
6.  Students can register for open events; when `max_participants` is reached, new submissions are placed on the ordered waiting list and automatically promoted when a registered student cancels prior to event start (`REG-003`, `REG-004`, `REG-011`, `BR-017`).
7.  Duplicate active registrations for the same `(event_id, student_id)` are prevented (`REG-005`, `BR-004`).
8.  Each student can access one permanent 64-character hex QR code and self-service reissue a new QR token that immediately revokes the old token (`QR-001`, `QR-012`).
9.  The same active permanent student QR can be reused across multiple events (`QR-003`).
10. Organizers can scan a student's permanent QR for both `check_in` and `check_out` modes (`ATT-001`, `ATT-002`, `ATT-013`).
11. Upon scan, the backend identifies the student and returns their profile photo, full name, student ID, and attendance status for immediate visual identity verification (`QR-006`, `ATT-003`).
12. The backend validates event registration before recording attendance, or records both a `walk_in` registration and `walk_in` attendance when walk-in is enabled for the event (`QR-008`, `ATT-004`, `ATT-014`).
13. Duplicate check-in and duplicate check-out scans for the same event are prevented (`QR-009`, `ATT-007`, `ATT-008`).
14. Late check-ins after the event start time plus the configured grace period are automatically marked `late`, and all attendance records store required timestamps and scanner identity (`ATT-006`, `ATT-012`).
15. Attendance information can be monitored in real time and manually corrected with a mandatory reason logged in `attendance_corrections` and `activity_logs` (`ATT-009`, `ATT-011`, `BR-022`).
16. Authorized users (Admin, Organizer/Staff, and read-only School Management) can generate all 7 report types and export them in PDF, CSV, and Excel (`.xlsx`) formats (`REPORT-001` to `REPORT-011`).
17. Push notifications and in-app notifications (with 30-day retention, 24h/1h reminders, and user preferences) work for approved notification events (`NOTIF-001` to `NOTIF-008`).
18. Important administrative and operational activities are logged in `activity_logs` (`LOG-001` to `LOG-004`).
19. API authentication and role authorization are enforced server-side (`SEC-001` to `SEC-012`).
20. Core workflows pass functional, integration, usability, security, performance, and user acceptance testing (Section 26).

------------------------------------------------------------------------

# 28. Recommended MVP Priority

To keep the project achievable, the development team should prioritize
the following phases.

## Priority 1 --- Core System

-   Authentication (self-registration, email verification, single active session per user account)
-   User roles (Administrator, Event Organizer/Staff, Student, School Management)
-   Student profile management (numeric ID, photo upload)
-   Event management (creation, editing, admin approval workflow)
-   Event registration (capacity limits, waiting list auto-promotion)
-   Permanent student QR (64-character cryptographic token)
-   QR attendance check-in and check-out
-   Identity verification on scan (photo + name + student ID + status display)
-   Automatic late detection (configurable grace period)
-   Walk-in attendance handling

## Priority 2 --- Operations & Management

-   Dashboards (role-specific: Student, Organizer, Management, Admin)
-   Search and filtering (events, students, attendance)
-   Comprehensive reports (7 report types)
-   Report export (PDF, CSV, Excel formats)
-   Activity logging & audit trail
-   Push notifications via FCM (8 notification triggers, reminders, user preferences)
-   Self-service QR reissue with instant revocation of old token

## Priority 3 --- Future Enhancements (Deferred)

-   AI-assisted features (chatbot, automated report summaries)
-   Offline attendance synchronization
-   NFC attendance
-   Digital certificates
-   Advanced predictive analytics

------------------------------------------------------------------------

# 29. Recommended Technology Stack

The finalized technology stack for the project:

  -----------------------------------------------------------------------
  Layer                               Technology
  ----------------------------------- -----------------------------------
  Mobile App                          Flutter 3.x (Dart 3.x) — Android 8.0+ (API 26+) / iOS 13+

  Backend                             Laravel 11 / PHP 8.3+ REST API

  API                                 REST API (JSON)

  Database                            MySQL 8.0+

  Authentication                      Laravel Sanctum (token-based with
                                      single active session enforcement)

  Push Notifications                  Firebase Cloud Messaging (FCM)

  QR Generation                       Mobile / Flutter QR library (e.g., qr_flutter)

  QR Scanning                         Mobile / Flutter QR scanner library (e.g., mobile_scanner)

  Report Generation                   Laravel DomPDF (PDF), Maatwebsite Excel (CSV/Excel)

  Version Control                     Git + GitHub

  Backend Hosting                     Cloud/VPS

  API Security                        HTTPS / SSL
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 30. AI Development Tools

AI may be used by developers during development to increase productivity,
but all generated code must be reviewed and tested by the team.

### Developer Coding Assistant

**GitHub Copilot or Cursor**

Use for:

-   Boilerplate code generation
-   Debugging and troubleshooting
-   Code refactoring
-   Unit and integration test generation
-   API and model implementation assistance
-   Technical documentation

*(Note: In-app AI runtime features have been cancelled for this release;
no third-party AI APIs are integrated into the application itself.)*

------------------------------------------------------------------------

# 31. Development Methodology

The project follows an Agile Sprint development methodology across a
6-week schedule aligned with `Project_Plan.md`.

The planned lifecycle phases are:

1.  Planning & Requirements Baseline
2.  System Architecture & Database Design
3.  Backend Core & API Development
4.  Reporting, Notifications & Scheduled Automation
5.  Mobile UI Development & API Integration
6.  Testing, Evaluation & Deployment Preparation

## 6-Week Agile Sprint Schedule

| Week | Sprint | Focus Area & Key Deliverables |
|------|--------|-------------------------------|
| Week 1 | Sprint 1 | Requirements Baseline (SRS v1.1), System Architecture, 13-Table Database Design & OpenAPI 3.0 Specification |
| Week 2 | Sprint 2 | Backend Core — Laravel 11 Setup, Sanctum Single-Session Auth, User/Student Profiles, Permanent QR & Event Lifecycle |
| Week 3 | Sprint 3 | Event Registration, Waiting List Auto-Promotion, Atomic QR Check-In/Check-Out Scanner API, Dashboards & Admin APIs |
| Week 4 | Sprint 4 | 7 Report Types with PDF/CSV/Excel Export, FCM Push Notifications & Scheduled Tasks (24h/1h Reminders, 30-Day Purge) |
| Week 5 | Sprint 5 | Flutter 3.x Mobile Application — All Role Screens, QR Display/Scanner & Live REST API Integration |
| Week 6 | Sprint 6 | Comprehensive Testing (Functional, Integration, Security, Performance, UAT), Debugging & Final Presentation Prep |

------------------------------------------------------------------------

# 32. Requirements Traceability

The following table maps all 12 Specific Objectives (Section 1.4) to the
complete set of functional requirement groups (`AUTH`, `USER`, `EVENT`,
`REG`, `QR`, `ATT`, `NOTIF`, `DASH`, `SEARCH`, `REPORT`, `LOG`, `ADMIN`),
Business Rules (`BR`), Security Requirements (`SEC`), and Non-Functional
Requirements (`NFR-001` to `NFR-013`).

| # | Specific Objective | Supporting Requirements |
|---|--------------------|-------------------------|
| 1 | Provide a user-friendly mobile interface for Android and iOS | `DASH-001` to `DASH-004`, `SEARCH-001` to `SEARCH-004`, `NFR-001` to `NFR-003`, `NFR-013` |
| 2 | Implement secure user authentication with self-registration and school email verification | `AUTH-001` to `AUTH-006`, `AUTH-009` to `AUTH-013`, `USER-004`, `BR-001`, `BR-020`, `SEC-001`, `SEC-003`, `SEC-011`, `SEC-012` |
| 3 | Implement role-based authorization for four user classes | `AUTH-007`, `AUTH-008`, `USER-001` to `USER-003`, `USER-005` to `USER-007`, `ADMIN-001`, `ADMIN-002`, `BR-002`, `SEC-002`, Section 23 |
| 4 | Automate event registration with optional participant limits and waiting lists | `EVENT-001` to `EVENT-008`, `REG-001` to `REG-012`, `BR-003`, `BR-004`, `BR-014` to `BR-017`, `BR-021` |
| 5 | Automate attendance recording through QR scanning with check-in and check-out support | `QR-001` to `QR-013`, `ATT-001` to `ATT-008`, `ATT-013`, `ATT-015`, `ATT-016`, `ADMIN-004`, `BR-005` to `BR-011`, `SEC-009`, `NFR-005` |
| 6 | Provide real-time attendance monitoring with automatic late detection | `ATT-009` to `ATT-012`, `DASH-002` to `DASH-004`, `SEARCH-004`, `BR-019`, `BR-022`, `NFR-004` |
| 7 | Support walk-in attendance tracking | `EVENT-002`, `REG-007`, `QR-008`, `ATT-004`, `ATT-014`, `ATT-015`, `REPORT-006`, `BR-018` |
| 8 | Generate accurate attendance and participation reports with PDF, CSV, and Excel export | `REPORT-001` to `REPORT-011`, `DASH-003`, `BR-013`, `BR-024` |
| 9 | Implement centralized database management | `LOG-001` to `LOG-004`, `ADMIN-003`, `ADMIN-005`, `BR-012`, `SEC-004`, `SEC-007`, `SEC-010`, `NFR-006`, `NFR-012`, Section 19 |
| 10 | Integrate relevant APIs and services where applicable | `NOTIF-001`, `NOTIF-004`, `SEC-005`, `SEC-006`, `SEC-008`, `NFR-008` to `NFR-011`, Section 20 |
| 11 | Provide push notifications for important event and attendance activities | `NOTIF-001` to `NOTIF-008`, `REG-008`, `REG-011`, `EVENT-006`, `BR-014`, `BR-023`, `NFR-007` |
| 12 | Evaluate the system based on usability and functionality | `NFR-001` to `NFR-013`, Section 26 (Testing Requirements), Section 27 (Acceptance Criteria) |

------------------------------------------------------------------------

# 33. Summary of Finalized Requirement Decisions

All previously open architectural and business rule questions have been
decided as follows:

## 33.1 User Details & Authentication

-   **Student Identifier:** Numeric student ID format (e.g., 20260001).
-   **Account Creation:** Self-registration for students with school email
    verification. Administrator creates Organizer and School Management accounts.
-   **Login Credential:** All users may log in using their registered school
    email + password; users with the **Student** role may alternatively log in
    using their numeric Student ID number + password.
-   **Password Reset:** Both email self-service reset and Administrator
    manual reset fallback.
-   **Student Profile Fields:** Full name (first, middle, last), Student ID
    number, School email, Course/Program, Year level, Section, Department/College,
    Contact number, and Profile photo.
-   **Session Policy:** Enforce a single active session per user account
    (specifically preventing concurrent multi-device student logins; a new
    login automatically invalidates any prior session token).

## 33.2 Event Rules

-   **Capacity Limits:** Optional per event — organizer can set a maximum
    participant cap or leave it open/unlimited.
-   **Event Publishing:** Requires Administrator review and approval before
    becoming public and available for registration.
-   **Registration Cancellation:** Students may cancel their own registration
    freely up until the event start time.
-   **Waiting List:** Supported — when participant cap is reached, students
    join an ordered waiting list and are auto-promoted when a spot opens.
-   **Walk-In Attendance:** Configurable per event — organizers can accept
    walk-in QR scans; records are explicitly flagged with `walk_in` status.
-   **Event Cancellation:** Organizer requests cancellation; requires
    Administrator approval before notifications are dispatched.

## 33.3 Attendance Rules

-   **Status Values:** `present`, `absent`, `late`, `excused`, and `walk_in`.
-   **Late Handling:** Automatically marked `late` when a registered student's
    check-in scan occurs after event start time plus configurable grace period
    (default 15 minutes).
-   **Check-In & Check-Out:** Supports two scans per event (check-in and
    check-out timestamping).
-   **Manual Corrections:** Allowed by Administrator and the event's owning
    Event Organizer/Staff; requires a mandatory `reason` and is logged in both
    `attendance_corrections` and `activity_logs` with `original_status`,
    `new_status`, `reason`, and `corrected_by`.
-   **Scanner Identity:** Stored with each attendance record for auditability.

## 33.4 Permanent QR Rules

-   **QR Token Format:** Cryptographically random 64-character hexadecimal
    string with no embedded personal data.
-   **QR Reissue:** Student self-service in-app reissue; previous QR token
    is revoked immediately and permanently.
-   **Scan Verification:** Upon scan (`POST /api/v1/events/{id}/attendance/scan`),
    the backend atomically validates and records the check-in/check-out and
    immediately returns the student's profile photo, full name, student ID,
    and attendance status for on-screen visual verification by the organizer.

## 33.5 Notifications

-   **Triggers (8):** New event published, registration confirmation, event
    reminders, event updates, event cancellation, attendance recorded confirmation,
    waiting list promotion, and administrative announcements.
-   **Reminder Timing:** Dispatched at 24 hours and 1 hour before event start.
-   **Retention:** 30 days in-app history, then automatically purged.
-   **Preferences:** Optional notifications can be toggled; critical alerts
    (event cancellation, attendance confirmation) are mandatory.

## 33.6 Reports & Analytics

-   **Report Types (7):** Event attendance list, Student attendance history,
    Registration summary, Overall participation summary, Absentee report,
    Walk-in report, and Organizer event summary.
-   **Export Formats:** PDF, CSV, and Excel (.xlsx).
-   **Export Governance:** No prior approval required; all generation and
    export operations are logged in activity logs.

## 33.7 AI Functionality

-   **Status:** Cancelled for initial release. No external AI APIs or
    runtime AI services are integrated. Developers may use AI coding
    assistants (Copilot/Cursor) during implementation.

## 33.8 Mobile Platform & Role Permissions

-   **Mobile OS Targets:** Android (API 26 / Android 8.0+) and iOS (iOS 13+)
    using Flutter cross-platform framework.
-   **School Management Role:** Strictly Read-Only access across events,
    attendance, reports, and dashboards.

------------------------------------------------------------------------

# 34. Final Requirement Baseline

This SRS (v1.1) constitutes the approved, finalized requirements
baseline for the development of the School Event Registration and
QR-Based Attendance Management System.

Any major requirement change after this baseline requires formal change
documentation and approval.

The development team should not add major functionality simply because
it is technically possible. New features should be evaluated against:

1.  Project scope
2.  Available development time
3.  Team capability
4.  User needs
5.  Security/privacy impact
6.  Testing requirements
7.  Instructor/project requirements

------------------------------------------------------------------------

# 35. Final System Definition

The approved system can be summarized as follows:

> **The School Event Registration and QR-Based Attendance Management
> System is a mobile application that allows students to view and
> register for school events, use a permanent student QR code for event
> attendance, and receive relevant notifications. Event organizers and
> authorized school personnel can manage events, scan permanent student
> QR codes, monitor attendance, and generate reports. A Laravel REST API
> and MySQL database provide centralized and secure data management,
> while push notifications extend the system's functionality.**

The most important architectural rule is:

> **The permanent QR identifies the student; the event registration and
> attendance records identify the student's participation in a specific
> event.**

This separation allows one permanent student QR to be safely reused
across multiple events while keeping attendance event-specific.
