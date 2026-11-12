# School Event Registration & QR-Based Attendance Management System
## Comprehensive System Flowcharts & Process Workflows

This document outlines the end-to-end architecture, role-based workflows, lifecycle state machines, and data processing logic based directly on the inspected system source code.

---

## Table of Contents

1. [High-Level System Architecture](#1-high-level-system-architecture)
2. [Authentication & Single-Session Enforcement Workflow](#2-authentication--single-session-enforcement-workflow)
3. [Event Lifecycle & Administrative Approval Governance](#3-event-lifecycle--administrative-approval-governance)
4. [Student Permanent QR Identity & Atomic Reissuance](#4-student-permanent-qr-identity--atomic-reissuance)
5. [Event Registration & Waiting List Auto-Promotion](#5-event-registration--waiting-list-auto-promotion)
6. [QR Attendance Scanning (Check-In & Check-Out) Engine](#6-qr-attendance-scanning-check-in--check-out-engine)
7. [Manual Attendance Correction & Audit Trail](#7-manual-attendance-correction--audit-trail)
8. [Institutional Reporting & Export Pipeline](#8-institutional-reporting--export-pipeline)

---

## 1. High-Level System Architecture

The platform operates as a decoupled client-server architecture. The Flutter mobile/web client communicates exclusively through JSON REST endpoints over HTTPS. Direct database access from client applications is prohibited.

```mermaid
flowchart TD
    subgraph ClientLayer["Frontend: Flutter 3.x (Android / iOS / Web / Desktop)"]
        UI_Login["Login Screen (Numeric ID / School Email)"]
        UI_Student["Student Flow (Browse, Register, View QR)"]
        UI_Organizer["Organizer Flow (Create Events, Scan QR, Live Attendance)"]
        UI_Admin["Admin Flow (Approvals, User Mgmt, QR Inspection, Audit)"]
        UI_Mgmt["Management Flow (Read-Only Dashboards & Reports)"]
        ApiClient["ApiClient (Bearer Token Auth & Session Hook)"]
    end

    subgraph ApiGateway["Backend API: Laravel 11 REST Gateway (/api/v1/*)"]
        RouteAuth["/auth/* (Public Throttle: 5 req/min)"]
        MiddlewareSession["Middleware: auth:sanctum & single.session"]
        MiddlewareRole["Middleware: role:admin, organizer, student, management"]
        Controllers["API Controllers (V1)"]
    end

    subgraph DataStore["Data & Persistence Layer"]
        MySQL[("MySQL 8.0 Relational DB (13 Domain Tables)")]
        SanctumTokens[("Personal Access Tokens")]
        Storage["Storage (Profile Photos & Report Exports)"]
    end

    UI_Login --> ApiClient
    UI_Student --> ApiClient
    UI_Organizer --> ApiClient
    UI_Admin --> ApiClient
    UI_Mgmt --> ApiClient

    ApiClient --> RouteAuth
    ApiClient --> MiddlewareSession

    MiddlewareSession --> MiddlewareRole
    MiddlewareRole --> Controllers

    Controllers --> MySQL
    Controllers --> SanctumTokens
    Controllers --> Storage
```

---

## 2. Authentication & Single-Session Enforcement Workflow

Users authenticate using either their numeric **Student ID** (e.g., `20260001`) or **Institutional Email**. When a user logs in from a new device, any existing active sessions are terminated immediately.

```mermaid
flowchart TD
    Start(["User submits login credentials"]) --> InputType{"Is login numeric or email?"}

    InputType -- "Numeric digits" --> LookupStudent["Lookup Student by student_id_number"]
    LookupStudent --> ResolveUser["Resolve associated User record"]
    InputType -- "Email string" --> LookupUser["Lookup User by email"]

    ResolveUser --> CheckCreds{"Credentials match & password correct?"}
    LookupUser --> CheckCreds

    CheckCreds -- "No" --> Ret401["Return 401 Unauthorized (ERR_INVALID_CREDENTIALS)"]
    CheckCreds -- "Yes" --> CheckStatus{"Is account status active?"}

    CheckStatus -- "inactive" --> Ret403Inactive["Return 403 Forbidden (ERR_ACCOUNT_INACTIVE)"]
    CheckStatus -- "pending" --> Ret403Pending["Return 403 Forbidden (ERR_EMAIL_UNVERIFIED)"]
    CheckStatus -- "active" --> RevokeTokens["Revoke all existing Sanctum tokens for user"]

    RevokeTokens --> GenUUID["Generate new UUID for active_session_id"]
    GenUUID --> SaveSession["Update users.active_session_id = new_uuid"]
    SaveSession --> IssueToken["Issue Sanctum Bearer token: 'session-{uuid}'"]
    IssueToken --> LogAuth["Log activity_log: user_logged_in"]
    LogAuth --> ReturnPayload["Return 200 OK (Token + User Role + Student Profile)"]

    subgraph SessionCheck["Subsequent Requests: EnforceSingleSession Middleware"]
        ReqIncoming["Incoming API request with Bearer Token"] --> ExtractSession["Extract token session ID"]
        ExtractSession --> MatchSession{"Token UUID == users.active_session_id?"}
        MatchSession -- "Match" --> AllowPass["Allow request to proceed"]
        MatchSession -- "Mismatch" --> TerminateReq["Return 401 Unauthorized (ERR_SESSION_TERMINATED)"]
        TerminateReq --> ClientModal["Mobile App displays 'Session Terminated' Modal & redirects to Login"]
    end
```

---

## 3. Event Lifecycle & Administrative Approval Governance

Organizers create events in `draft` mode. Events must be reviewed and approved by an Administrator before becoming visible for registration and attendance scanning.

```mermaid
flowchart TD
    DraftState["Status: draft (Created by Organizer)"] --> SubmitApproval["Organizer clicks 'Submit for Approval'"]
    SubmitApproval --> PendingState["Status: pending_approval"]

    PendingState --> AdminReview{"Admin Reviews Event"}
    AdminReview -- "Approve" --> PublishedState["Status: published (Open for Student Registration)"]
    AdminReview -- "Reject" --> DraftReturn["Status returned to draft (Reason noted)"]
    DraftReturn --> DraftState

    PublishedState --> EventDay{"Event Date & Time Arrives"}
    EventDay --> OngoingState["Status: ongoing (QR Check-In & Check-Out Active)"]
    OngoingState --> ConcludeEvent["Event End Time Reached"]
    ConcludeEvent --> CompletedState["Status: completed (Scanning Closed, Reports Available)"]

    subgraph CancellationWorkflow["Event Cancellation Process"]
        PublishedState -.-> OrgCancel["Organizer requests cancellation"]
        OngoingState -.-> OrgCancel
        OrgCancel --> CancelReview{"Admin approves cancellation?"}
        CancelReview -- "Approved" --> CancelledState["Status: cancelled"]
        CancelledState --> NotifyStudents["Notify all registered students via NotificationService"]
    end
```

---

## 4. Student Permanent QR Identity & Atomic Reissuance

Each student is assigned a **permanent cryptographic QR token** containing **no embedded PII**. If a student loses their physical badge or suspects their QR code is compromised, they can reissue it instantly.

```mermaid
flowchart TD
    subgraph InitialGeneration["QR Retrieval (GET /api/v1/student/qr)"]
        ReqQR["Student navigates to Permanent QR screen"] --> FetchActive["Fetch active StudentQR record"]
        FetchActive --> Exists{"Active QR exists?"}
        Exists -- "Yes" --> RenderCode["Render QR code using qr_flutter (64-char hex string)"]
        Exists -- "No" --> GenInitial["Generate bin2hex(random_bytes(32)) & status = active"]
        GenInitial --> RenderCode
    end

    subgraph AtomicReissue["QR Reissue (POST /api/v1/student/qr/reissue)"]
        ReissueReq["Student or Admin initiates QR Reissue"] --> BeginTx["Begin Database Transaction"]
        BeginTx --> RevokeOld["Update existing active tokens: status = 'revoked', revoked_at = now()"]
        RevokeOld --> GenFresh["Generate new 64-char cryptographic hex token"]
        GenFresh --> InsertNew["Insert new student_qrs row (status = 'active')"]
        InsertNew --> LogAudit["Log activity_logs: qr_token_reissued"]
        LogAudit --> CommitTx["Commit Transaction"]
        CommitTx --> ReturnNewToken["Return new QR token & update screen instantly"]
    end
```

---

## 5. Event Registration & Waiting List Auto-Promotion

Student event registrations strictly enforce capacity limits. When slots fill, students join an ordered waiting list. If a registered student cancels, the system automatically promotes the next waiting student.

```mermaid
flowchart TD
    StudentReq["Student initiates Registration (POST /events/{id}/register)"] --> CheckEventState{"Event status == 'published' & within dates?"}

    CheckEventState -- "No" --> RegError["Return 422 Unprocessable Entity"]
    CheckEventState -- "Yes" --> CheckDupe{"Student already registered or waitlisted?"}

    CheckDupe -- "Yes" --> DupeError["Return 409 Conflict (ERR_DUPLICATE_REGISTRATION)"]
    CheckDupe -- "No" --> CheckCapacity{"Is confirmed registrations >= max_capacity?"}

    CheckCapacity -- "Under Capacity" --> ConfirmedReg["Insert registration: status = 'registered'"]
    ConfirmedReg --> NotifyReg["Send Notification: 'Event Registration Confirmed'"]
    NotifyReg --> FinishReg["Return 201 Created (Confirmed)"]

    CheckCapacity -- "At Capacity" --> CalculatePos["Calculate next waiting list position (#N)"]
    CalculatePos --> WaitlistReg["Insert registration: status = 'waiting_list', position = N"]
    WaitlistReg --> NotifyWait["Send Notification: 'Placed on Waiting List (#N)'"]
    NotifyWait --> FinishWait["Return 201 Created (Waiting List)"]

    subgraph AutoPromotion["Cancellation & Auto-Promotion Flow"]
        CancelReq["Registered student cancels (DELETE /events/{id}/cancel-registration)"] --> StartCancelTx["Begin DB Transaction"]
        StartCancelTx --> MarkCancelled["Update registration: status = 'cancelled', cancelled_at = now()"]
        MarkCancelled --> FindWaitlist["Find lowest waiting_list_position for event"]
        FindWaitlist --> WaitlistExists{"Eligible waitlisted student exists?"}

        WaitlistExists -- "Yes" --> PromoteTop["Promote top student: status = 'registered', position = null"]
        PromoteTop --> DecrementOthers["Decrement remaining waiting list positions by 1"]
        DecrementOthers --> NotifyPromoted["Send Notification: 'Promoted to Confirmed Registration'"]
        NotifyPromoted --> CommitCancel["Commit DB Transaction"]

        WaitlistExists -- "No" --> CommitCancel
    end
```

---

## 6. QR Attendance Scanning (Check-In & Check-Out) Engine

The attendance scanner supports both **Check-In** and **Check-Out** modes. The scanner validates event state, verifies permanent QR tokens, calculates late arrival grace periods, handles unregistered walk-ins, and presents on-screen photo verification for staff.

```mermaid
flowchart TD
    ScanAction(["Organizer scans QR code with mobile camera"]) --> ValidateFormat{"Is token 64 hex characters?"}

    ValidateFormat -- "Invalid" --> ErrFormat["Return 422 Invalid QR Format"]
    ValidateFormat -- "Valid" --> EventCheck{"Is event status 'published' or 'ongoing'?"}

    EventCheck -- "Draft / Cancelled" --> ErrEventState["Return 422 Event not active for attendance"]
    EventCheck -- "Valid State" --> TokenLookup["Lookup token in student_qrs where status = 'active'"]

    TokenLookup --> TokenValid{"Token found & active?"}
    TokenValid -- "No (Revoked/Unknown)" --> ErrRevoked["Return 422 (ERR_QR_INVALID_OR_REVOKED)"]
    TokenValid -- "Yes" --> ResolveProfile["Load Student details & SIS profile photo"]

    ResolveProfile --> ModeBranch{"Scan Mode Selected"}

    %% Check-Out Branch
    ModeBranch -- "check_out" --> CheckInLookup{"Has an existing check-in record?"}
    CheckInLookup -- "No" --> ErrNoCheckIn["Return 422 (ERR_NO_CHECK_IN_RECORD)"]
    CheckInLookup -- "Yes" --> AlreadyOut{"check_out_time already recorded?"}
    AlreadyOut -- "Yes" --> ErrAlreadyOut["Return 409 (ERR_ALREADY_CHECKED_OUT)"]
    AlreadyOut -- "No" --> SaveOut["Set check_out_time = now()"]
    SaveOut --> LogOut["Log activity_log: attendance_check_out"]
    LogOut --> SuccessOut["Return 200 OK: Check-out recorded + Photo"]

    %% Check-In Branch
    ModeBranch -- "check_in" --> DupeCheckIn{"Already checked in?"}
    DupeCheckIn -- "Yes" --> ErrDupeIn["Return 409 (ERR_DUPLICATE_CHECK_IN) + Existing time"]
    DupeCheckIn -- "No" --> RegCheck{"Is student registered for event?"}

    RegCheck -- "Registered" --> GraceCheck{"Time > (event_start + late_grace_minutes)?"}
    GraceCheck -- "Within Grace" --> StatusPresent["attendance.status = 'present'"]
    GraceCheck -- "Beyond Grace" --> StatusLate["attendance.status = 'late'"]

    RegCheck -- "Not Registered" --> WalkInCheck{"Is event.walk_in_allowed == true?"}
    WalkInCheck -- "No" --> ErrWalkInDisabled["Return 403 (ERR_WALK_IN_NOT_ALLOWED)"]
    WalkInCheck -- "Yes" --> StatusWalkIn["Update registration = 'walk_in' & attendance.status = 'walk_in'"]

    StatusPresent --> SaveAttendance["Insert record into attendances table"]
    StatusLate --> SaveAttendance
    StatusWalkIn --> SaveAttendance

    SaveAttendance --> NotifyStudentScan["Send Notification: 'Attendance Recorded'"]
    NotifyStudentScan --> LogScanActivity["Log activity_log: attendance_check_in"]
    LogScanActivity --> DisplayVerification["Display Success Badge + Student Photo + Full Name on Scanner"]
```

---

## 7. Manual Attendance Correction & Audit Trail

Organizers and Administrators can manually adjust an attendance record (e.g., from `absent` or `late` to `excused` or `present`). Every correction requires a documented reason and writes to both `attendance_corrections` and `activity_logs`.

```mermaid
flowchart TD
    StaffInitiates(["Staff edits attendance status in Live Attendance Screen"]) --> ReasonProvided{"Is mandatory reason provided?"}

    ReasonProvided -- "Missing" --> ErrReason["Return 422 Validation Error: Reason required"]
    ReasonProvided -- "Provided" --> AuthCheck{"Is user Administrator OR Event Organizer?"}

    AuthCheck -- "Unauthorized" --> ErrAuth["Return 403 Forbidden"]
    AuthCheck -- "Authorized" --> StartCorrectionTx["Begin DB Transaction"]

    StartCorrectionTx --> CaptureOld["Capture current attendance.status as old_status"]
    CaptureOld --> ApplyNew["Update attendance.status = new_status"]
    ApplyNew --> InsertCorrection["Insert row into attendance_corrections (old_status, new_status, reason, corrected_by)"]
    InsertCorrection --> LogActivity["Insert row into activity_logs (action: 'attendance_corrected')"]
    LogActivity --> CommitCorrection["Commit DB Transaction"]
    CommitCorrection --> ReturnCorrected["Return 200 OK + Updated Record & Audit Entry"]
```

---

## 8. Institutional Reporting & Export Pipeline

The system provides 7 comprehensive institutional report types. Authorized users can filter and export data across three standard formats: **JSON** (live preview), **CSV**, **PDF**, and **Excel (`.xlsx`)**.

```mermaid
flowchart TD
    ReqReport(["User opens Reports Screen"]) --> SelectReportType{"Select Report Type"}

    SelectReportType --> R1["1. Event Attendance Report"]
    SelectReportType --> R2["2. Absentee Report"]
    SelectReportType --> R3["3. Late Arrival Report"]
    SelectReportType --> R4["4. Registration List Report"]
    SelectReportType --> R5["5. Capacity Utilization Report"]
    SelectReportType --> R6["6. Event Summary Report"]
    SelectReportType --> R7["7. Student Participation Report"]

    R1 --> ApplyFilters["Apply Filters (Event, Department, Course, Year Level, Date Range)"]
    R2 --> ApplyFilters
    R3 --> ApplyFilters
    R4 --> ApplyFilters
    R5 --> ApplyFilters
    R6 --> ApplyFilters
    R7 --> ApplyFilters

    ApplyFilters --> ChooseFormat{"Select Export Format"}

    ChooseFormat -- "JSON Preview" --> ExecQuery["Execute Eloquent Query & Aggregations"]
    ExecQuery --> RenderTable["Render Interactive Data Table in Flutter UI"]

    ChooseFormat -- "CSV Export" --> StreamCSV["Format comma-separated values stream with headers"]
    StreamCSV --> DownloadCSV["Download .csv file"]

    ChooseFormat -- "PDF Export" --> BladeView["Compile DomPDF Blade Template with School Branding"]
    BladeView --> GenPDF["Generate styled PDF document"]
    GenPDF --> DownloadPDF["Download .pdf file"]

    ChooseFormat -- "Excel Export" --> Maatwebsite["Build Maatwebsite/Laravel-Excel Export Class"]
    Maatwebsite --> GenXLSX["Generate formatted .xlsx workbook with summary styles"]
    GenXLSX --> DownloadXLSX["Download .xlsx file"]
```

---

## Summary of Key Verification & Rule Gates

| Component | Security & Business Rule | Verification Location in Source |
|---|---|---|
| **Single-Session** | Only 1 active device session; previous tokens revoked on login | [`AuthController.php`](file:///C:/Users/ThinkPad%20L14/Downloads/bahala%20nani/School-Event-Registration-and-QR-Based-Attendance/backend/app/Http/Controllers/Api/V1/AuthController.php#L70-L79), [`EnforceSingleSession.php`](file:///C:/Users/ThinkPad%20L14/Downloads/bahala%20nani/School-Event-Registration-and-QR-Based-Attendance/backend/app/Http/Middleware/EnforceSingleSession.php) |
| **Permanent QR** | 64-char random hex token with zero PII; atomic reissue | [`StudentQRController.php`](file:///C:/Users/ThinkPad%20L14/Downloads/bahala%20nani/School-Event-Registration-and-QR-Based-Attendance/backend/app/Http/Controllers/Api/V1/StudentQRController.php#L58-L90) |
| **Event Governance** | Administrator approval required before publishing or cancelling | [`EventController.php`](file:///C:/Users/ThinkPad%20L14/Downloads/bahala%20nani/School-Event-Registration-and-QR-Based-Attendance/backend/app/Http/Controllers/Api/V1/EventController.php#L200-L240) |
| **Auto-Promotion** | Transactional promotion of next waitlist student on cancellation | [`RegistrationController.php`](file:///C:/Users/ThinkPad%20L14/Downloads/bahala%20nani/School-Event-Registration-and-QR-Based-Attendance/backend/app/Http/Controllers/Api/V1/RegistrationController.php#L160-L210) |
| **Late Arrival** | Automatic detection using `event_date + start_time + late_grace_period_minutes` | [`AttendanceController.php`](file:///C:/Users/ThinkPad%20L14/Downloads/bahala%20nani/School-Event-Registration-and-QR-Based-Attendance/backend/app/Http/Controllers/Api/V1/AttendanceController.php#L173-L182) |
| **Audit Trail** | All state-changing actions logged with user, IP, and metadata | [`ActivityLog.php`](file:///C:/Users/ThinkPad%20L14/Downloads/bahala%20nani/School-Event-Registration-and-QR-Based-Attendance/backend/app/Models/ActivityLog.php), [`ActivityLog::log()`](file:///C:/Users/ThinkPad%20L14/Downloads/bahala%20nani/School-Event-Registration-and-QR-Based-Attendance/backend/app/Models/ActivityLog.php#L32-L48) |
