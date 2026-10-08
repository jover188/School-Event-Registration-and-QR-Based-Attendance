# School Event Registration & QR-Based Attendance Management System
## 6-Week Project Plan

> **Project Title:** School Event Registration and QR-Based Attendance Management System  
> **Duration:** 6 Weeks  
> **Team Size:** Individual / Small Team  
> **Stack:** Laravel 11 (Backend API) · Flutter (Mobile) · MySQL 8 (Production) · SQLite (Testing)

---

## Sprint Overview

| Week | Sprint | Focus Area | Status |
|------|--------|------------|--------|
| 1 | Sprint 1 | Requirements, Architecture & Database Design | ✅ Done |
| 2 | Sprint 2 | Backend Core — Auth, QR, Events, Migrations | ✅ Done |
| 3 | Sprint 3 | Registration, Attendance & Scanner API | ✅ Done |
| 4 | Sprint 4 | Reports, Notifications & Scheduled Tasks | 🔄 In Progress |
| 5 | Sprint 5 | Flutter Mobile UI — All Screens & Integration | 🔄 Scaffolded |
| 6 | Sprint 6 | Testing, Debugging & Presentation Prep | ⬜ Upcoming |

---

## Week 1 — Sprint 1: Requirements, Architecture & Database Design ✅

**Goal:** Establish the full project foundation before writing a single line of application code.

### Deliverables
- [x] Software Requirements Specification (SRS v1.1) — `School_Event_Attendance_SRS_v1.0.md`
- [x] System Architecture Document — `System_Architecture_and_Database_Design.md`
  - Entity-Relationship Diagram (ER)
  - State Machine Diagrams (event lifecycle, registration lifecycle)
  - Sequence Diagrams (login flow, QR scan flow)
  - Full MySQL DDL with FK constraints
- [x] REST API Specification — `REST_API_Specification.md`
- [x] OpenAPI 3.0 Machine-Readable Spec — `openapi.yaml` (importable into Postman)
- [x] Git repository initialized with root `.gitignore`

### Milestones
| # | Milestone | Done |
|---|-----------|------|
| 1.1 | SRS approved and baselined | ✅ |
| 1.2 | 13-table ER diagram finalized | ✅ |
| 1.3 | OpenAPI spec complete (49 routes) | ✅ |
| 1.4 | Git repo initialized | ✅ |

---

## Week 2 — Sprint 2: Backend Core — Auth, QR, Events ✅

**Goal:** Scaffold and fully implement the Laravel 11 backend with authentication, permanent QR management, and event lifecycle management.

### Deliverables
- [x] Laravel 11.57 scaffolded in `backend/` via `composer create-project`
- [x] Laravel Sanctum 4.3.3 installed (`php artisan install:api`)
- [x] 13 custom migration files (roles → users → students → QRs → events → approvals → registrations → attendances → corrections → notifications → preferences → device tokens → activity logs)
- [x] 13 Eloquent Models with full relationships and business logic helpers
- [x] `AuthController` — register, login (student ID or email), logout, profile, change password
- [x] `StudentQRController` — get active QR, self-reissue, admin inspect history
- [x] `EventController` — CRUD, submit for approval, admin review, cancellation workflow
- [x] Custom Middleware: `CheckRole` (role-based access) + `EnforceSingleSession` (one active device)
- [x] 2 Seeders: `RoleSeeder` (4 roles) + `UserSeeder` (4 demo accounts + student with permanent QR)
- [x] MySQL 8.0 production DB seeded (`school_event_attendance`)
- [x] `.env` configured for MySQL

### Seeded Test Accounts
| Role | Login | Password |
|------|-------|----------|
| Administrator | `admin@school.edu` | `Admin@12345` |
| Organizer | `organizer@school.edu` | `Organizer@12345` |
| Management | `management@school.edu` | `Management@12345` |
| Student | `20260001` or `student@school.edu` | `Student@12345` |

### Milestones
| # | Milestone | Done |
|---|-----------|------|
| 2.1 | Laravel scaffolded and key:generate complete | ✅ |
| 2.2 | All 13 migrations run on MySQL without errors | ✅ |
| 2.3 | Auth endpoints working (login, logout, profile) | ✅ |
| 2.4 | QR reissue atomically revokes old token | ✅ |
| 2.5 | Single-session enforcement middleware active | ✅ |

---

## Week 3 — Sprint 3: Registration, Attendance & Scanner API ✅

**Goal:** Implement the core event registration and QR attendance scanning workflows, including waiting list auto-promotion and late detection.

### Deliverables
- [x] `RegistrationController` — register (with waiting list), cancel (with auto-promotion), list endpoints
- [x] `AttendanceController` — QR scan check-in (late detection, walk-in support, photo response), check-out, live monitor, correction endpoint, student history
- [x] `NotificationController` — inbox, mark read, preferences, device token registration
- [x] `DashboardController` — role-specific dashboard summaries (student, organizer, management, admin)
- [x] `AdminController` — user management, staff creation, activity log viewer
- [x] `ReportController` — 7 report types as JSON + CSV streaming export
- [x] All 49 API routes defined in `routes/api.php`
- [x] Feature test suite: **5 domain workflow tests, all passing** (42 assertions, 3.32s)
  - ✅ Student can login with numeric student ID
  - ✅ Single active session enforcement
  - ✅ Student can fetch and reissue permanent QR
  - ✅ Full attendance check-in and check-out workflow
  - ✅ Waiting list auto-promotion on cancellation

### Key Architecture Decisions Implemented
| Feature | Implementation |
|---------|----------------|
| Late detection | `Carbon::parse(event_date + start_time)->addMinutes(grace_period)` vs `now()` |
| Waiting list promotion | Wrapped in `DB::transaction()`, lowest `waiting_list_position` promoted first |
| Walk-in | Creates `walk_in` EventRegistration + `walk_in` Attendance if `walk_in_allowed = true` |
| QR token | `bin2hex(random_bytes(32))` = 64-char hex, stored in `student_qrs` table |
| Single session | Login deletes all prior Sanctum tokens, creates `"session-{$uuid}"` token |

### Milestones
| # | Milestone | Done |
|---|-----------|------|
| 3.1 | Waiting list auto-promotion tested and passing | ✅ |
| 3.2 | QR scan returns student photo URL for face verification | ✅ |
| 3.3 | 7 report types returning JSON data | ✅ |
| 3.4 | All 49 routes reachable (no 404s on route list) | ✅ |
| 3.5 | Test suite: 5/5 passing on SQLite | ✅ |

---

## Week 4 — Sprint 4: Reports, Notifications & Scheduled Tasks 🔄

**Goal:** Complete the reporting subsystem with PDF/Excel export, implement push notification infrastructure, and set up automated scheduled jobs.

### Deliverables
- [ ] **PDF Report Export** — Install `barryvdh/laravel-dompdf`, create Blade report templates, update `ReportController::export()` to serve PDF
- [ ] **Excel Report Export** — Install `maatwebsite/excel`, generate `.xlsx` exports with proper column formatting
- [ ] **Scheduled Console Tasks** — Populate `routes/console.php`:
  - Event reminder job (24h before event → notify all registered students)
  - Event reminder job (1h before event → final reminder)
  - Notification purge cron (delete notifications older than 30 days)
  - Auto-close attendance windows (mark events as ended at `end_time`)
- [ ] **Push Notification Dispatch** — Integrate FCM (Firebase Cloud Messaging) for in-app push to Flutter via `device_tokens` table
- [ ] **Policy/Authorization Tests** — Role-based access tests (student cannot access admin endpoints, organizer cannot approve own event, etc.)

### Milestones
| # | Milestone | Done |
|---|-----------|------|
| 4.1 | PDF attendance report downloadable from API | ⬜ |
| 4.2 | Excel registration report downloadable from API | ⬜ |
| 4.3 | 24h and 1h reminder scheduled commands working | ⬜ |
| 4.4 | Notification purge cron running without errors | ⬜ |
| 4.5 | Authorization policy tests passing | ⬜ |

---

## Week 5 — Sprint 5: Flutter Mobile UI — All Screens & Integration 🔄

**Goal:** Complete the Flutter mobile application with all screens fully wired to the live Laravel API. Currently scaffolded; needs API integration and UI polish.

### Scaffolded (needs wiring to live API)
- [x] `main.dart` — persistent login state, single-session termination dialog
- [x] `api_client.dart` — Bearer auth, multipart upload, session callback
- [x] `login_screen.dart` / `register_screen.dart`
- [x] `student_dashboard_screen.dart` / `permanent_qr_screen.dart` / `event_detail_screen.dart`
- [x] `qr_scanner_screen.dart` (organizer)
- [x] `organizer_dashboard_screen.dart`
- [x] `management_dashboard_screen.dart`
- [x] `admin_dashboard_screen.dart`

### Remaining Flutter Work
- [ ] Wire login screen to `POST /api/v1/auth/login` → store token in `flutter_secure_storage`
- [ ] Wire student dashboard to `GET /api/v1/dashboard/student`
- [ ] Wire QR screen to `GET /api/v1/qr/my-qr` — render QR code widget with `qr_flutter`
- [ ] Wire event list + detail to `GET /api/v1/events`
- [ ] Wire event registration / cancellation buttons
- [ ] Wire QR scanner to `POST /api/v1/attendance/scan` — display student photo for face verification
- [ ] Wire check-out to `POST /api/v1/attendance/checkout`
- [ ] Wire organizer event management (create, submit for approval)
- [ ] Wire notification inbox to `GET /api/v1/notifications`
- [ ] Profile photo upload (`image_picker` → multipart `POST /api/v1/auth/profile`)
- [ ] Admin: user management screens wired to `GET/POST /api/v1/admin/users`
- [ ] Management: reports screen wired to `GET /api/v1/reports/*`
- [ ] Test on Android emulator with backend running at `10.0.2.2:8000`

### Milestones
| # | Milestone | Done |
|---|-----------|------|
| 5.1 | Login → token stored → dashboard loads from API | ⬜ |
| 5.2 | Student QR screen renders live QR from API | ⬜ |
| 5.3 | QR scanner decodes and POSTs to attendance/scan | ⬜ |
| 5.4 | Student photo displayed after successful scan | ⬜ |
| 5.5 | Event registration and cancellation flows complete | ⬜ |
| 5.6 | Notification inbox loads and marks read | ⬜ |
| 5.7 | App tested end-to-end on Android emulator | ⬜ |

---

## Week 6 — Sprint 6: Testing, Debugging & Presentation Prep ⬜

**Goal:** Achieve full test coverage, fix all discovered bugs, produce final deliverables, and rehearse the demo.

### Deliverables
- [ ] **Expanded Backend Test Suite**
  - Unit tests per controller (individual method coverage)
  - Policy/authorization tests (role enforcement on all protected routes)
  - Report generation tests (CSV, PDF, Excel output validation)
  - Edge case tests (duplicate registration attempt, expired event scan, already-checked-out)
- [ ] **Flutter Widget Tests** — Unit tests for models, API client mock tests
- [ ] **End-to-End Demo Script** — Step-by-step walkthrough of all 4 user roles
- [ ] **Final Git Tag** — `v1.0.0` release tag with clean commit history
- [ ] **README.md** — Setup guide covering:
  - Prerequisites (PHP 8.2, Composer, MySQL 8, Flutter 3.x)
  - Local dev setup steps
  - Seeded test account credentials
  - Running tests (`php artisan test`)
  - Starting the server (`php artisan serve`)
- [ ] **Presentation Slides** — System overview, architecture diagram, live demo flow, challenges & solutions
- [ ] **Dry Run Demo** — Full end-to-end demo rehearsal with XAMPP/MySQL running

### Milestones
| # | Milestone | Done |
|---|-----------|------|
| 6.1 | Backend test suite expanded to ≥ 20 test cases | ⬜ |
| 6.2 | All edge cases handled (duplicate registration, etc.) | ⬜ |
| 6.3 | README.md complete and setup guide verified | ⬜ |
| 6.4 | `v1.0.0` git tag created | ⬜ |
| 6.5 | Full demo rehearsed end-to-end without errors | ⬜ |

---

## Technical Reference

### Running the Backend
```powershell
cd 'c:\Users\domin\OneDrive\Documents\Projects\School Event Registration and QR-Based Attendance Management System\backend'
php artisan serve
# API available at: http://127.0.0.1:8000/api/v1/
```

### Running Tests
```powershell
cd 'c:\Users\domin\OneDrive\Documents\Projects\School Event Registration and QR-Based Attendance Management System\backend'
php artisan test
# Expected: 7 tests, 42 assertions — all passing
```

### Resetting the Database
```powershell
php artisan migrate:fresh --seed
# Drops all tables, re-runs migrations, re-seeds 4 demo accounts
```

### Git Commits to Date
| Commit | Description |
|--------|-------------|
| `feat:` | Complete SRS v1.1, database architecture, OpenAPI spec, and Laravel 11 backend with verified tests |
| `feat:` | Scaffold Flutter mobile application with screens, API client, models, and QR scanner |
| `chore:` | Update .env.example with MySQL database configuration template |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Flutter SDK setup delays on test device | Medium | High | Use Android emulator; test early in Week 5 |
| FCM push notification setup complexity | Medium | Medium | Fall back to in-app polling if FCM blocks progress |
| PDF generation layout issues | Low | Low | Use simple Blade table template; avoid complex CSS |
| MySQL connection issues on demo machine | Low | High | Keep SQLite fallback; document MySQL setup steps |
| Time overrun on Flutter API wiring | Medium | High | Prioritize student + organizer flows; admin is secondary |
