# REST API Specification

## School Event Registration and QR-Based Attendance Management System
**API Version:** 1.0.0  
**Base URL:** `https://api.school-events.edu/api/v1`  
**Protocol:** HTTPS / TLS 1.3  
**Content-Type:** `application/json` (or `multipart/form-data` for file uploads)  
**Authentication:** HTTP Bearer Token (Laravel Sanctum)  
**Associated SRS Version:** 1.1 Finalized Baseline  
**Date:** 2026-10-08  

---

# 1. Global API Standards

## 1.1 HTTP Status Codes
| Code | Meaning | Description |
|---|---|---|
| `200 OK` | Success | Request succeeded; response payload contains requested data. |
| `201 Created` | Resource Created | Entity successfully created (e.g., registration, user, event). |
| `400 Bad Request` | Client Error | Malformed request syntax or invalid parameter format. |
| `401 Unauthorized` | Unauthenticated | Missing, expired, revoked, or invalidated Sanctum bearer token. |
| `403 Forbidden` | Access Denied | Authenticated user lacks permission (role restriction). |
| `404 Not Found` | Resource Missing | Requested URL or resource record ID does not exist. |
| `409 Conflict` | Business Rule Conflict | E.g., Duplicate check-in, duplicate registration, event at capacity. |
| `422 Unprocessable` | Validation Error | Form/JSON body failed Laravel validation rules. |
| `429 Too Many Requests` | Rate Limited | Throttled (e.g., max 5 login attempts per min; max 60 scans/min). |
| `500 Server Error` | Internal Failure | Unexpected exception on server. |

## 1.2 Standard Response Wrapper
Every JSON response conforms to a consistent structure.

### Success Response
```json
{
  "success": true,
  "message": "Operation completed successfully.",
  "data": { ... },
  "meta": {
    "timestamp": "2026-10-08T08:00:00Z"
  }
}
```

### Paginated List Response
```json
{
  "success": true,
  "data": [ ... ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 72
  },
  "links": {
    "first": "https://api.school-events.edu/api/v1/events?page=1",
    "last": "https://api.school-events.edu/api/v1/events?page=5",
    "prev": null,
    "next": "https://api.school-events.edu/api/v1/events?page=2"
  }
}
```

### Error Response
```json
{
  "success": false,
  "error_code": "ERR_VALIDATION_FAILED",
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The school email has already been taken."],
    "student_id_number": ["The student ID number must be numeric."]
  }
}
```

---

# 2. Authentication & Profile Endpoints

> **Note on Account Provisioning:** Student and staff accounts are pre-provisioned and synchronized from the institution's central student database via institutional seeders or database synchronization middleware. Public open self-registration is disabled (`POST /auth/register` omitted).

### 2.1 User Login
- **Method & Route:** `POST /auth/login`
- **Access:** Public
- **Throttle:** 5 requests per minute
- **Request Body:**
```json
{
  "login": "20260001",
  "password": "Password@123"
}
```
*(Note: `login` accepts either the student's numeric ID or school email).*
- **Response `200 OK`:**
```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "token": "14|vB9lKmK2sX8j8H9Z3Qh0u0yD7Eeq0xZk0H1up8Z1F1M",
    "user": {
      "id": 142,
      "email": "student@school.edu",
      "role": "student",
      "status": "active"
    },
    "student_profile": {
      "id": 88,
      "student_id_number": "20260001",
      "full_name": "Juan Dela Cruz",
      "course": "BS Computer Science",
      "year_level": "3rd Year",
      "section": "CS-3A",
      "department": "College of Computer Studies",
      "contact_number": "09171234567",
      "profile_photo_url": "https://api.school-events.edu/storage/profiles/photo_142.jpg"
    }
  }
}
```
*(Note: Any prior active session on other devices is automatically invalidated server-side).*

---

### 2.2 Verify Email
- **Method & Route:** `POST /auth/verify-email`
- **Access:** Public
- **Request Body:**
```json
{
  "email": "student@school.edu",
  "token": "49bf8a892f39d2c49901a..."
}
```
- **Response `200 OK`:**
```json
{
  "success": true,
  "message": "Email verified successfully. You may now log in.",
  "data": {
    "status": "active"
  }
}
```

---

### 2.3 Logout
- **Method & Route:** `POST /auth/logout`
- **Access:** Authenticated (Bearer Token)
- **Response `200 OK`:**
```json
{
  "success": true,
  "message": "Logged out successfully. Device session terminated."
}
```

---

### 2.4 Authenticated Profile Management
- **`GET /profile`**
  - **Access:** Authenticated (All roles)
  - **Description:** Retrieves authenticated user details, student profile (if student), and notification preferences.
- **`PUT /profile`** (and **`POST /profile`** for `multipart/form-data` photo upload)
  - **Access:** Authenticated (All roles)
  - **Description:** Updates editable student profile details: `first_name`, `middle_name`, `last_name`, `course`, `year_level`, `section`, `department`, `contact_number`, `profile_photo` (JPG/PNG, max 2MB).
  - **Note:** `student_id_number` and `email` are immutable by students. Self-service forgot-password endpoints are omitted because student and staff accounts are integrated with the school SIS (and provisioned via database seeders for demo environments).
- **`POST /profile/change-password`**
  - **Access:** Authenticated (All roles)
  - **Body:** Accepts `current_password` and `new_password` + `new_password_confirmation` (or `password` + `password_confirmation`):
```json
{
  "current_password": "OldPassword@123",
  "new_password": "NewPassword@123",
  "new_password_confirmation": "NewPassword@123"
}
```
  - **Response `200 OK`:** Password updated successfully.

---

# 3. Permanent Student QR Endpoints

### 3.1 Get Permanent Student QR
- **Method & Route:** `GET /student/qr`
- **Access:** Authenticated (`student` role only)
- **Description:** Returns the active 64-character hexadecimal QR token.
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "student_id_number": "20260001",
    "full_name": "Juan Dela Cruz",
    "qr_token": "a1f8c3d9e2b4056789abcdef0123456789abcdef0123456789abcdef01234567",
    "status": "active",
    "issued_at": "2026-09-01T10:00:00Z"
  }
}
```

---

### 3.2 Self-Service QR Reissue
- **Method & Route:** `POST /student/qr/reissue`
- **Access:** Authenticated (`student` role only)
- **Description:** Instantly revokes current QR token and issues a fresh 64-character token.
- **Response `200 OK`:**
```json
{
  "success": true,
  "message": "A new permanent QR code has been generated. Your previous QR code has been revoked.",
  "data": {
    "student_id_number": "20260001",
    "full_name": "Juan Dela Cruz",
    "new_qr_token": "9876543210abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    "status": "active",
    "issued_at": "2026-10-08T08:15:00Z"
  }
}
```

---

### 3.3 Admin Inspect Student QR History
- **Method & Route:** `GET /admin/students/{id}/qr`
- **Access:** Authenticated (`administrator` role only)
- **Description:** Inspects a student's active QR token and complete history of active and revoked QR tokens.
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": {
    "student_id": 88,
    "student_id_number": "20260001",
    "full_name": "Juan Dela Cruz",
    "active_qr": {
      "id": 15,
      "qr_token": "9876543210abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
      "status": "active",
      "created_at": "2026-10-08T08:15:00Z"
    },
    "qr_history": [
      {
        "id": 15,
        "qr_token": "9876543210abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
        "status": "active",
        "revoked_at": null,
        "created_at": "2026-10-08T08:15:00Z"
      },
      {
        "id": 1,
        "qr_token": "a1f8c3d9e2b4056789abcdef0123456789abcdef0123456789abcdef01234567",
        "status": "revoked",
        "revoked_at": "2026-10-08T08:15:00Z",
        "created_at": "2026-09-01T10:00:00Z"
      }
    ]
  }
}
```

---

### 3.4 Admin Force-Reissue Student QR Code
- **Method & Route:** `POST /admin/students/{id}/qr/reissue`
- **Access:** Authenticated (`administrator` role only)
- **Description:** Atomically revokes a student's active QR token (`status = 'revoked'`, `revoked_at = now()`) and generates a fresh 64-character permanent QR token.
- **Response `200 OK`:** Returns the newly issued QR token details.

---

# 4. Event Management Endpoints

### 4.1 List Events
- **Method & Route:** `GET /events`
- **Access:** Authenticated (All roles)
- **Query Parameters:**
  | Param | Type | Description |
  |---|---|---|
  | `status` | string | `draft`, `pending_approval`, `published`, `ongoing`, `completed`, `cancelled` (Students only see `published` & `ongoing`) |
  | `date_from` | date | Format: `YYYY-MM-DD` |
  | `date_to` | date | Format: `YYYY-MM-DD` |
  | `search` | string | Matches `title` or `venue` |
  | `page` | integer | Page number (default: 1) |
  | `per_page` | integer | Items per page (default: 15) |

- **Response `200 OK`:**
```json
{
  "success": true,
  "data": [
    {
      "id": 12,
      "title": "Annual Tech Symposium 2026",
      "description": "Exploration of emerging computing technologies.",
      "venue": "University Auditorium",
      "event_date": "2026-10-25",
      "start_time": "09:00:00",
      "end_time": "16:00:00",
      "registration_start": "2026-10-10T00:00:00Z",
      "registration_end": "2026-10-23T23:59:59Z",
      "max_participants": 200,
      "current_registered_count": 145,
      "remaining_slots": 55,
      "late_grace_period_minutes": 15,
      "walk_in_allowed": true,
      "status": "published",
      "organizer": {
        "id": 5,
        "email": "organizer@school.edu"
      },
      "user_registration_status": "registered"
    }
  ],
  "meta": { "current_page": 1, "last_page": 1, "per_page": 15, "total": 1 }
}
```

---

### 4.2 Get Single Event Detail
- **Method & Route:** `GET /events/{id}`
- **Access:** Authenticated (All roles)
- **Description:** Returns single event details including organizer info, approval records, capacity (`current_registered_count`, `remaining_slots`), and the authenticated student's registration status (`user_registration_status`, `user_waiting_position`).
- **Response `200 OK`:** Returns event detail object in `data`.

---

### 4.3 Create Event
- **Method & Route:** `POST /events`
- **Access:** `organizer`, `administrator`
- **Request Body:**
```json
{
  "title": "Annual Tech Symposium 2026",
  "description": "Exploration of emerging computing technologies.",
  "venue": "University Auditorium",
  "event_date": "2026-10-25",
  "start_time": "09:00:00",
  "end_time": "16:00:00",
  "registration_start": "2026-10-10 00:00:00",
  "registration_end": "2026-10-23 23:59:59",
  "max_participants": 200,
  "late_grace_period_minutes": 15,
  "walk_in_allowed": true
}
```
- **Response `201 Created`:** Created in `draft` status.

---

### 4.4 Update Event
- **Method & Route:** `PUT /events/{id}`
- **Access:** `organizer` (must own the event), `administrator`
- **Request Body:** Any subset of editable event fields (`title`, `description`, `venue`, `event_date`, `start_time`, `end_time`, `registration_start`, `registration_end`, `max_participants`, `late_grace_period_minutes`, `walk_in_allowed`).
- **Response `200 OK`:** Event updated successfully.

---

### 4.5 Submit Event for Admin Publishing Approval
- **Method & Route:** `POST /events/{id}/submit-approval`
- **Access:** `organizer` (must own the event), `administrator`
- **Response `200 OK`:** Status transitioned to `pending_approval`.

---

### 4.6 Admin Review Event (Publishing Approval)
- **Method & Route:** `POST /admin/events/{id}/review`
- **Access:** `administrator`
- **Request Body:**
```json
{
  "action": "approved", // or "rejected"
  "remarks": "Event approved for student registrations."
}
```
- **Response `200 OK`:** Status transitioned to `published` (or reverted to `draft` if rejected).

---

### 4.7 Request Event Cancellation & Admin Review
- **`POST /events/{id}/request-cancellation`** (`organizer`, `administrator`)
  - **Body:** `{ "reason": "Speaker unavailable due to emergency." }`
  - **Response `200 OK`:** Cancellation request recorded and awaiting administrator approval.
- **`POST /admin/events/{id}/review-cancellation`** (`administrator`)
  - **Body:** `{ "action": "approved", "remarks": "Cancellation approved." }`
  - **Side Effect:** Automatically sets event status to `cancelled`, rejects ongoing registrations, and dispatches cancellation notifications to all registered students.

---

# 5. Event Registration & Waiting List Endpoints

### 5.1 Register for Event
- **Method & Route:** `POST /events/{id}/register`
- **Access:** `student`
- **Response `201 Created` (Normal Registration):**
```json
{
  "success": true,
  "message": "Registration successful. Present your permanent QR code at the venue check-in.",
  "data": {
    "registration_id": 312,
    "event_id": 12,
    "status": "registered",
    "waiting_list_position": null,
    "registered_at": "2026-10-10T09:30:00Z"
  }
}
```

- **Response `201 Created` (Capacity Reached — Placed on Waiting List):**
```json
{
  "success": true,
  "message": "Event capacity reached. You are at position #4 on the waiting list.",
  "data": {
    "registration_id": 313,
    "event_id": 12,
    "status": "waiting_list",
    "waiting_list_position": 4,
    "registered_at": "2026-10-10T10:00:00Z"
  }
}
```

---

### 5.2 Cancel Registration (Student)
- **Method & Route:** `DELETE /events/{id}/cancel-registration`
- **Access:** `student`
- **Condition:** Allowed only before event start time.
- **Response `200 OK`:**
```json
{
  "success": true,
  "message": "Registration cancelled successfully."
}
```
*(Side Effect: The next student on the waiting list is auto-promoted to `registered` and notified).*

---

### 5.3 View Own Registrations (Student)
- **Method & Route:** `GET /student/registrations`
- **Access:** `student`
- **Query Params:** `page`, `per_page`
- **Description:** Retrieves a paginated list of the authenticated student's event registrations, including waiting list positions, event details, and attendance records.
- **Response `200 OK`:** Paginated list of registrations.

---

### 5.4 List Event Attendees & Waiting List
- **Method & Route:** `GET /events/{id}/registrations`
- **Access:** `organizer`, `administrator`, `management`
- **Query Params:** `status=registered|waiting_list|cancelled|walk_in`, `page`, `per_page`
- **Response `200 OK`:** Paginated list of event registrations with student and attendance details.

---

### 5.5 Staff / Admin Cancel Student Registration
- **Method & Route:** `DELETE /events/{id}/registrations/{registrationId}`
- **Access:** `organizer` (must own event), `administrator`
- **Description:** Cancels a student's event registration or waiting list entry. If the student held an active `registered` slot, the lowest `waiting_list_position` candidate is atomically promoted to `registered` and remaining waiting list positions are decremented.
- **Response `200 OK`:** Registration cancelled and waiting list updated.

---

# 6. QR Attendance & Scanner Endpoints

### 6.1 Scan Student QR
- **Method & Route:** `POST /events/{id}/attendance/scan`
- **Access:** `organizer`, `administrator`
- **Throttle:** 60 scans per minute per organizer
- **Request Body:**
```json
{
  "qr_token": "a1f8c3d9e2b4056789abcdef0123456789abcdef0123456789abcdef01234567",
  "mode": "check_in" // or "check_out"
}
```

- **Response `200 OK` (Check-In Success — Present):**
```json
{
  "success": true,
  "message": "Check-in recorded as PRESENT for Juan Dela Cruz.",
  "data": {
    "attendance_id": 905,
    "mode": "check_in",
    "status": "present",
    "check_in_time": "2026-10-25T09:05:22Z",
    "check_out_time": null,
    "student": {
      "id": 88,
      "student_id_number": "20260001",
      "full_name": "Juan Dela Cruz",
      "course": "BS Computer Science",
      "year_level": "3rd Year",
      "section": "CS-3A",
      "department": "College of Computer Studies",
      "profile_photo_url": "https://api.school-events.edu/storage/profiles/photo_142.jpg"
    }
  }
}
```

- **Response `200 OK` (Check-In Success — Automatically Flagged Late):**
```json
{
  "success": true,
  "message": "Check-in recorded as LATE for Juan Dela Cruz. (Exceeded 15-minute grace period).",
  "data": {
    "attendance_id": 906,
    "mode": "check_in",
    "status": "late",
    "check_in_time": "2026-10-25T09:22:15Z",
    "check_out_time": null,
    "student": { ... }
  }
}
```

- **Response `200 OK` (Check-In Success — Walk-In Attendee):**
```json
{
  "success": true,
  "message": "Check-in recorded as WALK_IN for Juan Dela Cruz. (Walk-in attendee).",
  "data": {
    "attendance_id": 907,
    "mode": "check_in",
    "status": "walk_in",
    "check_in_time": "2026-10-25T09:12:00Z",
    "check_out_time": null,
    "student": { ... }
  }
}
```

- **Response `200 OK` (Check-Out Success):**
```json
{
  "success": true,
  "message": "Check-out successfully recorded for Juan Dela Cruz.",
  "data": {
    "attendance_id": 905,
    "mode": "check_out",
    "check_in_time": "2026-10-25T09:05:22Z",
    "check_out_time": "2026-10-25T16:02:10Z",
    "student": { ... }
  }
}
```

- **Error Responses:**
  - `409 Conflict`: Check-in or check-out already recorded for this event.
  - `403 Forbidden`: Student not registered and walk-in attendance is disabled.
  - `422 Unprocessable`: QR code invalid/revoked, event not active, or no check-in record on check-out.

---

### 6.2 Live Event Attendance List & Summary
- **Method & Route:** `GET /events/{id}/attendance`
- **Access:** `organizer`, `administrator`, `management`
- **Query Params:** `status=present|late|walk_in|excused|absent`, `search` (student name or ID), `page`, `per_page`
- **Description:** Returns a paginated list of attendance records for the event along with real-time summary counts (`total_checked_in`, `present`, `late`, `walk_in`, `excused`).
- **Response `200 OK`:**
```json
{
  "success": true,
  "data": [ ... ],
  "summary": {
    "total_checked_in": 120,
    "present": 105,
    "late": 10,
    "walk_in": 4,
    "excused": 1
  },
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "total": 120
  }
}
```

---

### 6.3 Manual Attendance Correction
- **Method & Route:** `PUT /attendance/{id}/correct`
- **Access:** `organizer`, `administrator`
- **Request Body:**
```json
{
  "new_status": "excused", // present, absent, late, excused, walk_in
  "reason": "Student had approved medical clinic clearance for morning session."
}
```
- **Response `200 OK`:** Attendance status updated; audit trail recorded in `attendance_corrections` and `activity_logs`.

---

### 6.4 Manual Mark Student Attendance (Organizer / Admin)
- **Method & Route:** `POST /events/{id}/attendance/mark`
- **Access:** `organizer` (must own event), `administrator`
- **Description:** Manually creates or updates an attendance record for a student (including marking a registered non-attending student as `absent` or `excused`) with a mandatory audit `reason`.
- **Request Body:**
```json
{
  "student_id": 88,
  "status": "excused",
  "reason": "Approved medical clearance submitted to organizer."
}
```
- **Response `200 OK`:** Attendance record created/updated and logged in `attendance_corrections` and `activity_logs`.

---

### 6.5 Student Personal Attendance History
- **Method & Route:** `GET /student/attendance-history`
- **Access:** `student`
- **Query Params:** `page`, `per_page`
- **Description:** Returns a paginated list of the authenticated student's attendance history across all events.
- **Response `200 OK`:** Paginated attendance records with associated event details.

---

# 7. Reports & Export Endpoints

### 7.1 Report Data Endpoints (JSON)
| Endpoint | Access | Description |
|---|---|---|
| `GET /reports/event-attendance/{id}` | `administrator`, `organizer`, `management` | Attendance list per event (Present, Absent, Late, Walk-in, Excused) with optional `status`, `department`, `year_level` filters |
| `GET /reports/student-history/{student_id}` | `administrator`, `organizer`, `management` | Attendance history across all events for a student with optional `date_from`, `date_to`, `status` filters |
| `GET /reports/registration-summary/{id}` | `administrator`, `organizer`, `management` | Registration turnout and waiting list breakdown with optional `department`, `year_level` filters |
| `GET /reports/participation-summary` | `administrator`, `organizer`, `management` | Institutional participation and attendance percentages with optional `date_from`, `date_to`, `department`, `year_level` filters |
| `GET /reports/absentee/{id}` | `administrator`, `organizer`, `management` | Students registered who failed to check in with optional `department`, `year_level` filters |
| `GET /reports/walk-in/{id}` | `administrator`, `organizer`, `management` | Students who attended as walk-in attendees with optional `department`, `year_level` filters |
| `GET /reports/organizer-summary` | `administrator`, `organizer`, `management` | Summary of events created and managed per organizer with optional `date_from`, `date_to` filters |

---

### 7.2 Report File Export
- **Method & Route:** `GET /reports/export`
- **Access:** `administrator`, `organizer`, `management`
- **Query Parameters:**
  | Param | Type | Required | Values |
  |---|---|---|---|
  | `report_type` | string | Yes | `event_attendance`, `student_history`, `registration_summary`, `participation_summary`, `absentee`, `walk_in`, `organizer_summary` |
  | `format` | string | Yes | `pdf`, `csv`, `xlsx` |
  | `event_id` | integer | Conditional | Required for event-specific reports (`event_attendance`, `registration_summary`, `absentee`, `walk_in`) |
  | `student_id` | integer | Conditional | Required for `student_history` |
  | `date_from` | date | No | Filter range start (`YYYY-MM-DD`) |
  | `date_to` | date | No | Filter range end (`YYYY-MM-DD`) |

- **Response `200 OK`:** Returns binary stream with appropriate `Content-Type` header:
  - PDF: `application/pdf`
  - CSV: `text/csv`
  - Excel: `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
  - Header: `Content-Disposition: attachment; filename="report_event_12_attendance.pdf"`

---

# 8. Notifications & FCM Device Endpoints

### 8.1 Register & Remove Device FCM Token
- **`POST /device-tokens`**
  - **Access:** Authenticated (All roles)
  - **Request Body:**
```json
{
  "fcm_token": "dK8j99sK8-f_sK89s_3k90...",
  "platform": "android" // or "ios"
}
```
  - **Response `200 OK`:** Device token registered for push notifications.
- **`DELETE /device-tokens`**
  - **Access:** Authenticated (All roles)
  - **Request Body:**
```json
{
  "fcm_token": "dK8j99sK8-f_sK89s_3k90..."
}
```
  - **Response `200 OK`:** Device token removed.

---

### 8.2 Notification Inbox & Read Status
- **`GET /notifications`**
  - **Access:** Authenticated (All roles)
  - **Query Params:** `page`, `per_page`
  - **Response `200 OK`:**
```json
{
  "success": true,
  "data": [
    {
      "id": 412,
      "title": "Event Starting in 1 Hour",
      "message": "Annual Tech Symposium 2026 starts at 09:00 AM at University Auditorium.",
      "notification_type": "event_reminder",
      "is_read": false,
      "payload": { "event_id": 12 },
      "created_at": "2026-10-25T08:00:00Z"
    }
  ],
  "unread_count": 1,
  "meta": { "current_page": 1, "last_page": 1, "total": 1 }
}
```
- **`PATCH /notifications/{id}/read`**
  - **Access:** Authenticated (All roles)
  - **Response `200 OK`:** Marks the specified notification as read.
- **`POST /notifications/mark-all-read`**
  - **Access:** Authenticated (All roles)
  - **Response `200 OK`:** Marks all unread notifications for the authenticated user as read.

---

### 8.3 Notification Preferences
- **`GET /notifications/preferences`**
  - **Access:** Authenticated (All roles)
  - **Response `200 OK`:** Returns current notification preference state.
- **`PUT /notifications/preferences`**
  - **Access:** Authenticated (All roles)
  - **Request Body (all 6 boolean fields are optional):**
```json
{
  "new_event_published": true,
  "registration_confirmed": true,
  "event_reminders": true,
  "event_updates": true,
  "waiting_list_promoted": true,
  "admin_announcements": false
}
```
*(Note: Critical alerts like `event_cancellation` and `attendance_recorded` cannot be disabled).*

---

# 9. Dashboard Endpoints

| Endpoint | Access | Content Description |
|---|---|---|
| `GET /dashboard/student` | `student` | Upcoming registered events, total registered/attended counts, active QR token, unread notification count |
| `GET /dashboard/organizer` | `organizer`, `administrator` | Summary of organized events (`total_events`, `published_events`, `ongoing_events`, `draft_events`) and recent events with registration/attendance counts |
| `GET /dashboard/management` | `management`, `organizer`, `administrator` | Read-only institutional participation metrics, overall turnout rate, attendance breakdown by status, department distribution, and recent events |
| `GET /dashboard/admin` | `administrator` | Events pending approval, total user/student/organizer counts, active permanent QR count, and recent system activity logs |

---

# 10. Administration & Audit Logging Endpoints (Admin Only)

### 10.1 List Users
- **Method & Route:** `GET /admin/users`
- **Access:** `administrator`
- **Query Parameters:**
  | Param | Type | Description |
  |---|---|---|
  | `role` | string | Filter by role slug (`administrator`, `organizer`, `student`, `management`) |
  | `status` | string | Filter by status (`active`, `inactive`, `pending`) |
  | `search` | string | Search by email, student name, or student ID number |
  | `page` | integer | Page number |
  | `per_page` | integer | Items per page (default: 20) |
- **Response `200 OK`:** Paginated list of users with role and student profile relationships.

---

### 10.2 Create Non-Student Staff Account
- **Method & Route:** `POST /admin/users`
- **Access:** `administrator`
- **Description:** Creates an `organizer`, `management`, or `administrator` account.
- **Request Body:**
```json
{
  "email": "organizer2@school.edu",
  "password": "Password@123",
  "role_id": 2
}
```
*(Note: `role_id` values: `1` = `administrator`, `2` = `organizer`, `4` = `management`).*
- **Response `201 Created`:** Newly created user account with role details.

---

### 10.3 Activate / Deactivate User Account
- **Method & Route:** `PATCH /admin/users/{id}/status`
- **Access:** `administrator`
- **Description:** Toggles or updates a user's account status between `active` and `inactive`. Deactivating an account immediately revokes all active Sanctum tokens for that user.
- **Response `200 OK`:**
```json
{
  "success": true,
  "message": "User status updated to inactive.",
  "data": {
    "status": "inactive"
  }
}
```

---

### 10.4 Admin Manual Password Reset
- **Method & Route:** `POST /admin/users/{id}/reset-password`
- **Access:** `administrator`
- **Description:** Administrative password reset fallback; sets a new password and terminates all prior sessions for the user.
- **Request Body:**
```json
{
  "password": "NewTempPassword@123"
}
```
- **Response `200 OK`:** Password reset confirmation.

---

### 10.5 Query System Activity Logs
- **Method & Route:** `GET /admin/logs`
- **Access:** `administrator`
- **Query Parameters:** `module` (`events`, `attendance`, `auth`, `registration`, `qr`, `reports`, `admin`), `action`, `user_id`, `date_from`, `date_to`, `page`, `per_page`
- **Response `200 OK`:** Paginated audit entries containing actor, action, module, target ID, IP address, user agent, and JSON delta metadata.

---

### 10.6 Broadcast Administrative Announcement
- **Method & Route:** `POST /admin/announcements`
- **Access:** `administrator`
- **Description:** Dispatches an announcement notification (`admin_announcement`) to all active users or a targeted role, respecting each recipient's `admin_announcements` notification preference.
- **Request Body:**
```json
{
  "title": "Campus Network Maintenance",
  "message": "The registration portal will undergo scheduled maintenance tonight from 11:00 PM to 12:00 AM.",
  "target_role": "all"
}
```
- **Response `200 OK`:** Returns `sent_count` of delivered notifications.

