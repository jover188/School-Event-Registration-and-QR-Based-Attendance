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

### 2.1 Student Self-Registration
- **Method & Route:** `POST /auth/register`
- **Access:** Public (Guest)
- **Content-Type:** `multipart/form-data`
- **Request Parameters:**
  | Field | Type | Required | Description |
  |---|---|---|---|
  | `first_name` | string | Yes | First name (max 100) |
  | `middle_name` | string | No | Middle name |
  | `last_name` | string | Yes | Last name (max 100) |
  | `student_id_number` | string | Yes | Numeric format (e.g., `20260001`), unique |
  | `email` | string | Yes | School email address, unique |
  | `password` | string | Yes | Min 8 chars, 1 uppercase, 1 number, 1 special |
  | `password_confirmation` | string | Yes | Must match `password` |
  | `course` | string | Yes | Degree program (e.g., `BS Computer Science`) |
  | `year_level` | string | Yes | E.g., `3rd Year` |
  | `section` | string | Yes | Class section (e.g., `CS-3A`) |
  | `department` | string | Yes | College / Department name |
  | `contact_number` | string | Yes | Mobile phone number |
  | `profile_photo` | file | Yes | JPG/PNG image, max 2MB |

- **Response `201 Created`:**
```json
{
  "success": true,
  "message": "Registration successful. Please verify your email via the link sent to your school inbox.",
  "data": {
    "user_id": 142,
    "email": "student@school.edu",
    "status": "pending"
  }
}
```

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

### 2.3 User Login
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
      "profile_photo_url": "https://api.school-events.edu/storage/profiles/photo_142.jpg"
    }
  }
}
```
*(Note: Any prior active session on other devices is automatically invalidated server-side).*

---

### 2.4 Logout
- **Method & Route:** `POST /auth/logout`
- **Access:** Authenticated (Bearer Token)
- **Response `200 OK`:**
```json
{
  "success": true,
  "message": "Logged out successfully. Active session terminated."
}
```

---

### 2.5 Password Reset Request & Confirmation
- **`POST /auth/forgot-password`**
  - **Body:** `{ "email": "student@school.edu" }`
  - **Response `200 OK`:** Reset link sent to registered email.
- **`POST /auth/reset-password`**
  - **Body:**
```json
{
  "email": "student@school.edu",
  "token": "reset_token_string",
  "password": "NewPassword@123",
  "password_confirmation": "NewPassword@123"
}
```
  - **Response `200 OK`:** Password reset successfully.

---

### 2.6 Authenticated Profile Management
- **`GET /profile`**: Retrieves authenticated user and student profile.
- **`PUT /profile`**: Updates editable profile details (`contact_number`, `profile_photo`). Note: `student_id_number` and `email` are immutable by students.
- **`POST /profile/change-password`**: `{ "current_password": "...", "new_password": "...", "new_password_confirmation": "..." }`

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
  "message": "A new permanent QR code has been generated. Your old QR code has been revoked.",
  "data": {
    "new_qr_token": "9876543210abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    "status": "active",
    "issued_at": "2026-10-08T08:15:00Z"
  }
}
```

---

# 4. Event Management Endpoints

### 4.1 List Events
- **Method & Route:** `GET /events`
- **Access:** Authenticated (All roles)
- **Query Parameters:**
  | Param | Type | Description |
  |---|---|---|
  | `status` | string | `published`, `ongoing`, `completed`, `cancelled` (Students only see `published` & `ongoing`) |
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
        "name": "Prof. Alan Turing"
      },
      "user_registration_status": "registered"
    }
  ],
  "meta": { "current_page": 1, "last_page": 1, "total": 1 }
}
```

---

### 4.2 Create Event
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

### 4.3 Submit Event for Admin Publishing Approval
- **Method & Route:** `POST /events/{id}/submit-approval`
- **Access:** `organizer` (must own the event)
- **Response `200 OK`:** Status transitioned to `pending_approval`.

---

### 4.4 Admin Review Event (Publishing Approval)
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

### 4.5 Request Event Cancellation & Admin Review
- **`POST /events/{id}/request-cancellation`** (Organizer)
  - **Body:** `{ "reason": "Speaker unavailable due to emergency." }`
- **`POST /admin/events/{id}/review-cancellation`** (Admin)
  - **Body:** `{ "action": "approved", "remarks": "Cancellation approved." }`
  - **Side Effect:** Automatically sets event status to `cancelled`, rejects ongoing registrations, dispatches FCM cancellation push notification to all registered students.

---

# 5. Event Registration & Waiting List Endpoints

### 5.1 Register for Event
- **Method & Route:** `POST /events/{id}/register`
- **Access:** `student`
- **Response `201 Created` (Normal Registration):**
```json
{
  "success": true,
  "message": "Successfully registered for event.",
  "data": {
    "registration_id": 312,
    "event_id": 12,
    "status": "registered",
    "registered_at": "2026-10-10T09:30:00Z"
  }
}
```

- **Response `201 Created` (Capacity Reached — Placed on Waiting List):**
```json
{
  "success": true,
  "message": "Participant limit reached. You have been placed on the waiting list.",
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
  "message": "Your registration has been cancelled.",
  "data": {
    "cancelled_at": "2026-10-12T14:00:00Z"
  }
}
```
*(Side Effect: The next student on the waiting list is auto-promoted to `registered` and notified via FCM).*

---

### 5.3 List Event Attendees & Waiting List
- **Method & Route:** `GET /events/{id}/registrations`
- **Access:** `organizer`, `administrator`, `management`
- **Query Params:** `status=registered|waiting_list|cancelled|walk_in`

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
  "message": "Check-in successful.",
  "data": {
    "attendance_id": 905,
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
  "message": "Check-in recorded as LATE (exceeded 15-minute grace period).",
  "data": {
    "attendance_id": 906,
    "status": "late",
    "check_in_time": "2026-10-25T09:22:15Z",
    "student": { ... }
  }
}
```

- **Response `200 OK` (Check-In Success — Walk-In Attendee):**
```json
{
  "success": true,
  "message": "Student was not registered. Attendance recorded as WALK-IN.",
  "data": {
    "attendance_id": 907,
    "status": "walk_in",
    "check_in_time": "2026-10-25T09:12:00Z",
    "student": { ... }
  }
}
```

- **Response `200 OK` (Check-Out Success):**
```json
{
  "success": true,
  "message": "Check-out recorded successfully.",
  "data": {
    "attendance_id": 905,
    "check_out_time": "2026-10-25T16:02:10Z"
  }
}
```

- **Error Responses:**
  - `409 Conflict`: Check-in already recorded for this event.
  - `403 Forbidden`: Student not registered and walk-in attendance is disabled.
  - `422 Unprocessable`: QR code invalid or revoked.

---

### 6.2 Manual Attendance Correction
- **Method & Route:** `PUT /attendance/{id}/correct`
- **Access:** `administrator`, `organizer`
- **Request Body:**
```json
{
  "new_status": "excused", // present, absent, late, excused, walk_in
  "reason": "Student had approved medical clinic clearance for morning session."
}
```
- **Response `200 OK`:** Attendance status updated; audit trail recorded in `attendance_corrections` and `activity_logs`.

---

# 7. Reports & Export Endpoints

### 7.1 Report Data Endpoints (JSON)
| Endpoint | Access | Description |
|---|---|---|
| `GET /reports/event-attendance/{id}` | Admin, Organizer, Management | Attendance list per event (Present, Absent, Late, Walk-in) |
| `GET /reports/student-history/{student_id}` | Admin, Organizer, Management | Attendance history across all events for a student |
| `GET /reports/registration-summary/{id}` | Admin, Organizer, Management | Registration turnout and waiting list breakdown |
| `GET /reports/participation-summary` | Admin, Organizer, Management | Institutional participation and attendance percentages |
| `GET /reports/absentee/{id}` | Admin, Organizer, Management | Students registered who failed to check in |
| `GET /reports/walk-in/{id}` | Admin, Organizer, Management | Students who attended as walk-in attendees |
| `GET /reports/organizer-summary` | Admin, Management | Summary of events created and managed per organizer |

---

### 7.2 Report File Export
- **Method & Route:** `GET /reports/export`
- **Access:** `administrator`, `organizer`, `management`
- **Query Parameters:**
  | Param | Type | Required | Values |
  |---|---|---|---|
  | `report_type` | string | Yes | `event_attendance`, `student_history`, `registration_summary`, `participation_summary`, `absentee`, `walk_in`, `organizer_summary` |
  | `format` | string | Yes | `pdf`, `csv`, `xlsx` |
  | `event_id` | integer | Conditional | Required for event-specific reports |
  | `student_id` | integer | Conditional | Required for student history |
  | `date_from` | date | No | Filter range start |
  | `date_to` | date | No | Filter range end |

- **Response `200 OK`:** Returns binary stream with appropriate `Content-Type` header:
  - PDF: `application/pdf`
  - CSV: `text/csv`
  - Excel: `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
  - Header: `Content-Disposition: attachment; filename="report_event_12_attendance.pdf"`

---

# 8. Notifications & FCM Device Endpoints

### 8.1 Register Device FCM Token
- **Method & Route:** `POST /device-tokens`
- **Access:** Authenticated (All roles)
- **Request Body:**
```json
{
  "fcm_token": "dK8j99sK8-f_sK89s_3k90...",
  "platform": "android" // or "ios"
}
```

---

### 8.2 Get Notification Inbox
- **Method & Route:** `GET /notifications`
- **Access:** Authenticated (All roles)
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
  ]
}
```

---

### 8.3 Notification Preferences
- **`GET /notifications/preferences`**: Returns current preference state.
- **`PUT /notifications/preferences`**:
```json
{
  "new_event_published": true,
  "event_reminders": true,
  "event_updates": true,
  "admin_announcements": false
}
```
*(Note: Critical alerts like `event_cancellation` and `attendance_confirmed` cannot be disabled).*

---

# 9. Dashboard Endpoints

| Endpoint | Access | Content Description |
|---|---|---|
| `GET /dashboard/student` | `student` | Upcoming registered events, total attended count, active QR status, unread notification count |
| `GET /dashboard/organizer` | `organizer` | Active events managed, live attendee check-in counts, pending scan actions |
| `GET /dashboard/management` | `management` (Read-Only) | Institutional participation metrics, event attendance rates by department and month |
| `GET /dashboard/admin` | `administrator` | Events pending approval, active user count, system health, recent audit events |

---

# 10. Audit Logging Endpoints (Admin Only)

### 10.1 Query Activity Logs
- **Method & Route:** `GET /admin/logs`
- **Access:** `administrator`
- **Query Parameters:** `module=events|attendance|auth`, `user_id`, `date_from`, `date_to`, `page`
- **Response `200 OK`:** Paginated audit entries containing actor, action, IP address, user agent, and JSON delta metadata.
