# Software Requirements Specification (SRS)

## School Event Registration and QR-Based Attendance Management System

**Project Type:** Mobile Application (Flutter — Android + iOS)\
**Backend:** Laravel / PHP REST API\
**Database:** MySQL\
**Push Notifications:** Firebase Cloud Messaging (FCM)\
**Development Approach:** Agile\
**Document Status:** Finalized Requirements Baseline\
**Version:** 1.1\
**Last Updated:** 2026-10-08\
**Prepared for:** Development Team / Project Group\
**Source Basis:** Final_School_Attendance.pptx, previously agreed
project decisions, and finalized requirement decisions (Section 33)

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
-   View reports and analytics
-   View event details

School Management cannot create events, scan QR codes, or modify
records.

## 2.3 Operating Environment

### Mobile Application

-   **Framework:** Flutter (Dart)
-   **Android:** Minimum API 26 (Android 8.0 Oreo)
-   **iOS:** Minimum iOS 13
-   **Distribution:** Google Play Store and Apple App Store

### Backend

-   PHP
-   Laravel
-   REST API
-   HTTPS
-   Cloud/VPS hosting

### Database

-   MySQL

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
6.  The mobile application targets Android 8.0+ and iOS 13+.
7.  Only one active session per student account is permitted at a time.
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
7.  Walk-in students may be scanned and flagged separately as 'walk-in'.
8.  The backend is the authoritative source for attendance records.
9.  Users have network access during normal registration and attendance
    operations.
10. Event organizers have permission to scan attendance.
11. Push notifications require Firebase Cloud Messaging and an
    appropriate device/network connection.
12. Only one active session per student account is permitted.
13. After QR scan, the organizer's device displays the student's photo
    and name for visual identity verification.
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

Requirement IDs use the following format:

-   **AUTH** -- Authentication and authorization
-   **USER** -- User management
-   **EVENT** -- Event management
-   **REG** -- Event registration
-   **QR** -- QR identity and attendance
-   **ATT** -- Attendance
-   **NOTIF** -- Notifications
-   **REPORT** -- Reports
-   **DASH** -- Dashboard
-   **SEARCH** -- Search and filtering
-   **LOG** -- Activity logs
-   **ADMIN** -- Administration

------------------------------------------------------------------------

## 4.1 Authentication and Authorization

### AUTH-001 Login

The system shall allow authorized users to log in using either their
school email or student ID number, combined with a password.

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

The system shall enforce a single active session per student account.
When a student logs in on a new device, any existing session on a
previous device shall be invalidated.

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

The system shall support account status: active, inactive, and
pending verification (for self-registered students).

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
information. Students may update their own profile except for student ID
number and school email.

### USER-007 Account Deactivation

Administrators shall be able to deactivate accounts according to school
policy.

------------------------------------------------------------------------

# 6. Event Management Requirements

### EVENT-001 Create Event

Authorized event organizers shall be able to create school events.
Newly created events shall be in 'draft' status.

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
events they created or are assigned to.

### EVENT-004 Event Status

The system shall support the following event states: draft,
pending approval, published/open, ongoing, completed, and cancelled.

### EVENT-005 Publish Event (Admin Approval Required)

When an organizer submits an event for publishing, the event shall
enter a 'pending approval' state. An administrator must approve the
event before it becomes visible to students. The admin may reject the
event with a reason.

### EVENT-006 Event Cancellation (Admin Approval Required)

Event organizers may request cancellation of an event. The cancellation
shall require administrator approval. Once approved, the system shall
notify all registered students of the cancellation.

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

Students shall be able to register for an available event. If the event
has reached its maximum participant limit, the student shall be placed
on a waiting list (REG-011).

### REG-004 Registration Validation

The backend shall validate that the event is open for registration
and the participant limit has not been reached before accepting a
registration.

### REG-005 Duplicate Registration

The system shall prevent a student from registering multiple times for
the same event.

### REG-006 Registration Record

The system shall store the relationship between the student and event,
including registration date/time.

### REG-007 Registration Status

The system shall maintain the following registration statuses:
registered, waiting list, cancelled, and walk-in.

### REG-008 Registration Confirmation

The system shall provide confirmation after successful registration and
send a push notification.

### REG-009 Registration Cancellation

Students shall be able to cancel their own registration before the event
starts. Authorized staff may also cancel a student's registration.

### REG-010 Registration Cutoff

The system shall prevent registration after the configured registration
deadline.

### REG-011 Waiting List

When an event has a maximum participant limit and that limit is reached,
new registrations shall be placed on a waiting list. When a registered
student cancels, the next student on the waiting list shall be
automatically promoted to 'registered' status and notified via push
notification.

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

After scanning, the backend shall identify the student associated with
the QR token. The scanner shall display the student's **profile photo
and full name** on the organizer's device for visual identity
verification before confirming attendance.

### QR-007 Event Context

The attendance scanner shall operate in the context of a selected event.

### QR-008 Registration Validation

Before recording attendance, the backend shall verify that the student
is registered for the selected event. If walk-in attendance is enabled
for the event, unregistered students shall be flagged as 'walk-in'.

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

Authorized event organizers shall be able to select an event and open
its attendance scanner. The scanner supports both check-in and
check-out modes.

### ATT-002 Scan Student QR

The organizer shall be able to scan a student's permanent QR for
check-in or check-out.

### ATT-003 Identify Student

The system shall identify the student using the QR token and display
their profile photo and full name for visual verification.

### ATT-004 Verify Registration

The backend shall check whether the student is registered for the
selected event. If the student is not registered and walk-in attendance
is enabled for the event, the student shall be flagged as 'walk-in'.

### ATT-005 Record Attendance

For an eligible student, the system shall create an attendance record
with the appropriate status.

### ATT-006 Attendance Information

An attendance record shall contain:

-   Student
-   Event
-   Check-in date/time
-   Check-out date/time (when applicable)
-   Attendance status (Present, Absent, Late, Excused, Walk-in)
-   Scanner/organizer (stored but not displayed prominently)

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

Administrators, event organizers, and designated staff shall be able to
correct attendance records. All corrections shall be recorded in the
activity log with the original value, new value, and correcting user.

### ATT-012 Automatic Late Detection

If a student's check-in scan occurs after the event's start time plus
the configured late grace period (default 15 minutes), the attendance
status shall be automatically set to 'Late' instead of 'Present'.

### ATT-013 Check-Out

The system shall support a check-out scan for each student per event.
The check-out time shall be recorded in the attendance record.

### ATT-014 Walk-In Attendance

When an event has walk-in attendance enabled, unregistered students
may have their QR scanned. The system shall automatically create a
registration record with 'walk-in' status and an attendance record
with 'Walk-in' attendance status.

### ATT-015 Attendance Status Values

The system shall support the following attendance statuses:
Present, Absent, Late, Excused, and Walk-in.

------------------------------------------------------------------------

# 10. Attendance Processing Flow

## 10.1 Check-In Flow

The official check-in flow shall be:

1.  Student logs in.
2.  Student registers for the event (or arrives as walk-in if enabled).
3.  Student accesses their permanent QR.
4.  Student attends the event.
5.  Organizer selects the event in the scanner (check-in mode).
6.  Organizer scans the student's permanent QR.
7.  Mobile application sends the QR token and event context to the
    backend.
8.  Backend identifies the student.
9.  Scanner displays student photo and name for visual identity
    verification.
10. Backend verifies the event status.
11. Backend verifies the student's registration (or flags as walk-in if
    walk-in is enabled and student is unregistered).
12. Backend checks whether check-in already exists.
13. Backend determines attendance status (Present vs. Late based on
    grace period).
14. If valid, the backend creates the attendance record.
15. The scanner displays successful attendance with the assigned status.
16. The attendance dashboard updates.

## 10.2 Check-Out Flow

1.  Organizer switches scanner to check-out mode.
2.  Organizer scans the student's permanent QR.
3.  Backend identifies the student and verifies existing check-in.
4.  Backend records the check-out time.
5.  Scanner confirms successful check-out.

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
-   Event reminder (1 day and 1 hour before event start)
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
-   Registration status
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

School Management shall be able to view approved participation and
attendance information.

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
specific event, showing all registered students with their attendance
status (Present, Absent, Late, Excused, Walk-in), check-in time, and
check-out time.

### REPORT-002 Registration Report

Authorized users shall be able to view event registration information
per event, including registration status (registered, waiting list,
cancelled, walk-in).

### REPORT-003 Participation Summary

The system shall provide an overall participation summary across all
events, including total registrations, total attendance, and attendance
rates.

### REPORT-004 Student Attendance History

Authorized users shall be able to generate a report showing a specific
student's attendance history across all events they registered for.

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

Where appropriate, an activity log should include:

-   User
-   Action
-   Affected module
-   Affected record ID
-   Date/time
-   Result/status
-   Relevant metadata

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

A student may register only for events currently open for registration
that have not reached their participant limit.

### BR-004

A student may not have multiple normal registrations for the same event.

### BR-005

Each student has one permanent active QR identity (cryptographic token).

### BR-006

The same student QR may be used for multiple events.

### BR-007

A QR code does not itself represent attendance.

### BR-008

Attendance belongs to a specific student-event combination.

### BR-009

Scanning a QR does not automatically mean attendance is valid. The
organizer must visually verify the student's identity (photo + name)
before confirming.

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

When an event with a participant limit has a registration cancelled,
the next student on the waiting list shall be automatically promoted.

### BR-018

Walk-in attendance is only permitted when explicitly enabled per event.

### BR-019

Late attendance is automatically determined by the system based on the
event's configured grace period after the start time.

### BR-020

Only one active session per student account is allowed. A new login
invalidates any existing session.

### BR-021

Students may cancel their own registration only before the event starts.

### BR-022

Attendance corrections must be logged with original value, new value,
and correcting user identity.

### BR-023

Notification history is retained for 30 days before automatic purging.

### BR-024

Report generation is logged but does not require approval.

------------------------------------------------------------------------

# 19. Data Requirements

## 19.1 Major Entities

The system requires the following major tables:

-   Users
-   Roles
-   Permissions
-   Students (with profile photo)
-   Events (with max participants, grace period, walk-in flag)
-   Event Registrations (with status: registered, waiting list,
    cancelled, walk-in)
-   Attendance (with check-in time, check-out time, status, scanner)
-   Student QR Codes
-   Notifications
-   Activity Logs
-   Event Approvals (for publish and cancellation workflows)
-   Notification Preferences

For the permanent QR requirement, the QR entity represents a
**student QR** with the following structure:

**StudentQR** — id, student_id, qr_token (64-char hex), status
(active/revoked), created_at, updated_at, revoked_at

A separate StudentQR entity is required because students can
self-service reissue their QR, creating a new token and revoking
the old one.

## 19.2 Core Relationships

-   One Role can be assigned to many Users.
-   One Student is associated with one active permanent Student QR.
-   One Student can have many Event Registrations.
-   One Event can have many Event Registrations.
-   One Event Registration can have zero or one Attendance record.
-   One Event can have many Attendance records.
-   One User/Organizer can manage many Events.
-   One Event can have one or more Event Approval records.
-   One User can generate many Activity Log records.
-   One User can receive many Notifications.
-   One Event can have a Waiting List (ordered registrations with
    'waiting list' status).

## 19.3 Data Integrity

The database shall enforce appropriate uniqueness and foreign-key
constraints.

Required constraints:

-   Unique user/account identifier
-   Unique student ID number
-   Unique school email
-   Unique active QR token
-   Unique student-event registration
-   Unique student-event check-in attendance
-   Valid foreign-key relationships

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

The exact endpoint names must be finalized during API design.

### Authentication

-   Self-register (student)
-   Verify email
-   Login (email or student ID + password)
-   Logout
-   Password reset request
-   Password reset confirm
-   Current user/profile

### Users

-   Create user (admin)
-   List users
-   View user
-   Update user/profile
-   Deactivate user

### Events

-   List events
-   View event (with remaining capacity)
-   Create event
-   Update event
-   Submit event for approval
-   Approve/reject event (admin)
-   Request event cancellation
-   Approve/reject cancellation (admin)

### Registration

-   Register for event
-   View registration(s)
-   Cancel registration
-   View waiting list position
-   View event registrations (organizer)

### QR

-   Get permanent student QR
-   Reissue QR (self-service)
-   Validate/scan QR
-   QR status management (admin)

### Attendance

-   Check-in scan
-   Check-out scan
-   View event attendance
-   View student attendance history
-   Correct attendance record

### Notifications

-   Register notification device token
-   Get notifications
-   Mark notification as read
-   Update notification preferences

### Reports

-   Event attendance report
-   Registration report
-   Participation summary
-   Student attendance history report
-   Absentee report
-   Walk-in report
-   Organizer summary report
-   Export report (PDF/CSV/Excel)

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

  Edit Events           Yes             Own/Assigned      No             No

  Approve/Reject Event  Yes             No                No             No

  Cancel Event Request  Yes             Own/Assigned      No             No

  Approve Cancellation  Yes             No                No             No

  Register for Event    No              No                Yes            No

  Cancel Registration   Yes             Yes               Own (before    No
                                                          event)

  View Registrations    Yes             Yes               Own            Yes (RO)

  View Waiting List     Yes             Yes               Own position   Yes (RO)

  Scan Student QR       Yes             Yes               No             No

  View Attendance       Yes             Yes               Own            Yes (RO)

  Correct Attendance    Yes             Own events        No             No

  Generate Reports      Yes             Yes               No             Yes (RO)

  Export Reports        Yes             Yes               No             Yes (RO)

  Manage System         Yes             No                No             No
  Settings

  View Activity Logs    Yes             Limited           No             No

  Receive Notifications Yes             Yes               Yes            Yes

  QR Self-Reissue       No              No                Yes            No

  Manage QR (admin)     Yes             No                No             No

  Notification          No              Yes               Yes            Yes
  Preferences
  -------------------------------------------------------------------------------

**(RO)** = Read-Only access. School Management cannot create, edit, or
delete any records.

------------------------------------------------------------------------

# 24. User Workflows

## 24.1 Student Workflow

**Self-Register → Verify Email → Login → View Available Events → Select
Event → View Details → Register (or Join Waiting List) → Registration
Confirmed → Attend Event → Open Permanent QR → Present QR → Organizer
Scans → Identity Verified (Photo + Name) → Backend Validates →
Check-In Recorded (Present/Late/Walk-in) → [Check-Out Scan] →
Check-Out Recorded**

## 24.2 Organizer Workflow

**Login → Create Event → Submit for Admin Approval → [Admin Approves] →
Event Published → View Registered Students → Select Event → Open QR
Scanner (Check-In Mode) → Scan Permanent Student QR → Verify Student
Identity (Photo + Name) → Backend Validates Student + Event +
Registration + Late/Walk-in Status → Record Check-In → [Switch to
Check-Out Mode] → Scan for Check-Out → Monitor Attendance → Generate
Report → Export (PDF/CSV/Excel)**

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

The system shall provide appropriate responses for common errors.

Examples include:

-   Invalid login credentials
-   Expired/invalid authentication
-   Unauthorized access
-   Event not found
-   Event pending approval (not yet published)
-   Event registration closed
-   Event at full capacity
-   Duplicate registration
-   Invalid QR
-   Revoked QR
-   Student not registered for event (walk-in disabled)
-   Duplicate check-in
-   Check-out without check-in
-   Cancelled event
-   Waiting list full
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

The system will be considered ready for the initial release when the
approved requirements have been implemented and tested.

Minimum acceptance criteria:

1.  Authorized users can log in securely.
2.  Unauthorized users cannot access protected functions.
3.  Role permissions work correctly.
4.  Organizers can create and manage events.
5.  Students can view eligible events.
6.  Students can register for available events.
7.  Duplicate registration is prevented.
8.  Each student can access one permanent QR.
9.  The same student QR can be used across multiple events.
10. Organizers can scan the permanent student QR.
11. The backend identifies the correct student.
12. The backend validates event registration before attendance.
13. Duplicate attendance is prevented.
14. Successful attendance is stored with the required information.
15. Attendance information can be monitored.
16. Approved users can generate attendance reports.
17. Push notifications work for approved notification events.
18. Important administrative activities are logged.
19. API authentication and role authorization are enforced server-side.
20. Core workflows pass functional, integration, usability, security,
    performance, and user acceptance testing.

------------------------------------------------------------------------

# 28. Recommended MVP Priority

To keep the project achievable, the development team should prioritize
the following phases.

## Priority 1 --- Core System

-   Authentication (self-registration, email verification, single-session)
-   User roles (Administrator, Organizer, Student, School Management)
-   Student profile management (numeric ID, photo upload)
-   Event management (creation, editing, admin approval workflow)
-   Event registration (capacity limits, waiting list auto-promotion)
-   Permanent student QR (64-character cryptographic token)
-   QR attendance check-in and check-out
-   Identity verification on scan (photo + name display)
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
  Mobile App                          Flutter + Dart (Android 8.0+ / iOS 13+)

  Backend                             Laravel + PHP

  API                                 REST API (JSON)

  Database                            MySQL

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

The project will follow an Agile development approach.

The planned phases are:

1.  Planning
2.  Requirements Gathering
3.  System Design
4.  Development
5.  Testing
6.  Deployment
7.  Evaluation
8.  Maintenance

## Proposed 8-Week Schedule

  Week         Activity
  ------------ ---------------------------
  Week 1       Requirements and Planning
  Week 2       System Design
  Weeks 3--5   Development
  Week 6       Integration
  Week 7       Testing
  Week 8       Deployment and Evaluation

------------------------------------------------------------------------

# 32. Requirements Traceability

The following maps the project's objectives to major system
requirements.

  Objective                            Supporting Requirements
  ------------------------------------ ---------------------------------------
  User-friendly interface              NFR-001 to NFR-003, DASH requirements
  Secure authentication                AUTH, SEC
  Automated registration               REG
  Automated attendance                 QR, ATT
  Real-time monitoring                 ATT-009, DASH
  Accurate reports                     REPORT
  Database management                  Data Requirements
  Relevant APIs/services               API, NOTIF
  Usability/functionality evaluation   Testing Requirements

------------------------------------------------------------------------

# 33. Summary of Finalized Requirement Decisions

All previously open architectural and business rule questions have been
decided as follows:

## 33.1 User Details & Authentication

-   **Student Identifier:** Numeric student ID format (e.g., 20260001).
-   **Account Creation:** Self-registration for students with school email
    verification. Administrator creates Organizer and School Management accounts.
-   **Login Credential:** Either School Email OR Student ID number + Password.
-   **Password Reset:** Both email self-service reset and Administrator
    manual reset fallback.
-   **Student Profile Fields:** Full name (first, middle, last), Student ID
    number, School email, Course/Program, Year level, Section, Department/College,
    Contact number, and Profile photo.
-   **Session Policy:** Enforce single active session per student account
    (new login automatically terminates any prior session).

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
    walk-in QR scans; records are explicitly flagged with 'Walk-in' status.
-   **Event Cancellation:** Organizer requests cancellation; requires
    Administrator approval before notifications are dispatched.

## 33.3 Attendance Rules

-   **Status Values:** Present, Absent, Late, Excused, and Walk-in.
-   **Late Handling:** Automatically marked 'Late' when check-in scan occurs
    after event start time plus configurable grace period (default 15 minutes).
-   **Check-In & Check-Out:** Supports two scans per event (check-in and
    check-out timestamping).
-   **Manual Corrections:** Allowed by Administrator, assigned Organizer,
    and designated staff; all corrections require audit logging.
-   **Scanner Identity:** Stored with each attendance record for auditability.

## 33.4 Permanent QR Rules

-   **QR Token Format:** Cryptographically random 64-character hexadecimal
    string with no embedded personal data.
-   **QR Reissue:** Student self-service in-app reissue; previous QR token
    is revoked immediately and permanently.
-   **Scan Verification:** Scanner UI displays student profile photo and full
    name upon scan for visual verification by organizer.

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

Once the project group and instructor approve this SRS, it should become
the baseline for development.

Any major change after approval should be documented as a requirements
change.

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
