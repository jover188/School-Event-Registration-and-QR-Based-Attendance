# Create Event Form Redesign & Audience Targeting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Attendify Create Event form into an organized 6-section layout (Information, Target Participants, Schedule, Registration, Notifications, Review & Publish) and implement robust backend-enforced audience targeting (All Students, Specific Course, Specific Year Level, Custom Combination) for event visibility, registration, and announcements.

**Architecture:** Add audience targeting columns (`category`, `cover_image_path`, `target_audience_type`, `target_courses`, `target_year_levels`, `target_sections`, `target_rules`, `send_announcement`) to the `events` table via a migration. Add student eligibility evaluator and query scopes in `Event.php`. Restrict student event listing in `EventController::index()`, detail access in `EventController::show()`, and registration in `RegistrationController::register()`. Dispatch publishing announcements only to matching students when enabled in `EventController::reviewApproval()`. Redesign `EventFormScreen` in Flutter with responsive Shadcn/AetherUI cards, multi-select targeting selectors, live summary card, and approval actions.

**Tech Stack:** Laravel 11, PHP 8.2, SQLite (tests) / MySQL 8.0, Flutter 3 (Web/Mobile), Dart 3, Shadcn/AetherUI black-and-white design system.

**Spec:** User prompt specifications for Attendify Event Form Redesign & Audience Targeting; SRS v1.1.

## Global Constraints
- Preserve Attendify's strict black-and-white design system (`#09090B`, `#FFFFFF`, `#FAFAFA`).
- Decoupled client-server architecture: all operations via `/api/v1/*` endpoints; Flutter never touches DB directly.
- Every schema change must be an immutable migration file.
- Backward compatibility: existing events with `target_audience_type = 'all'` or `null` remain accessible to all students.
- Only registered students receive event reminders (24h/1h/started/ended) — never spam unregistered students.
- Do not commit or push to GitHub.

## Review Focus
- **Case 1: Direct URL/API bypass attempt by ineligible student.** An ineligible student manually calling `GET /api/v1/events/{id}` or `POST /api/v1/events/{id}/register` must receive `403 Forbidden` (`ERR_AUDIENCE_INELIGIBLE`), not a registration confirmation.
- **Case 2: Custom multi-rule combination matching.** When targeting `BSIT - 1st Year` and `BSBA - 3rd Year`, a `BSIT 1st Year` student matches, a `BSBA 3rd Year` student matches, but `BSIT 2nd Year` and `BSBA 1st Year` students are excluded.
- **Case 3: Inactive or pending student accounts.** Students with `status != 'active'` must never receive announcements or be counted as eligible participants.
- **Case 4: Disabled announcement toggle.** If an organizer sets `send_announcement = false`, admin approval must NOT send any `new_event_published` notifications.
- **Case 5: Public/student calendar filtering.** The calendar screen must only display approved/ongoing events for which the logged-in student is eligible.

---

### Task 1: Backend Database Migration & Event Model Audience Targeting Support

**Files:**
- Create: `backend/database/migrations/2026_11_12_000000_add_audience_targeting_to_events_table.php`
- Modify: `backend/app/Models/Event.php`
- Test: `backend/tests/Unit/EventAudienceTargetingTest.php`

- [ ] **Step 1.1: Write failing unit test for Event model audience targeting logic**
  - Create `backend/tests/Unit/EventAudienceTargetingTest.php` testing `isStudentEligible()`:
    - 'all' targets any student
    - 'course' targets only matching courses
    - 'year_level' targets only matching year levels
    - 'custom' rules target specific combinations (e.g. BSIT + 1st Year)
  - Verify test fails before migration and model changes.

- [ ] **Step 1.2: Create migration for events audience targeting columns**
  - Columns:
    - `category`: string(50)->nullable()->default('General')
    - `cover_image_path`: string(255)->nullable()
    - `target_audience_type`: string(30)->default('all') // 'all', 'course', 'year_level', 'custom'
    - `target_courses`: json()->nullable()
    - `target_year_levels`: json()->nullable()
    - `target_sections`: json()->nullable()
    - `target_rules`: json()->nullable()
    - `send_announcement`: boolean()->default(true)
  - Run `php artisan migrate`.

- [ ] **Step 1.3: Update Event model fillables, casts, and helper methods**
  - Add fields to `$fillable`.
  - Add casts: `target_courses => array`, `target_year_levels => array`, `target_sections => array`, `target_rules => array`, `send_announcement => boolean`.
  - Implement `isStudentEligible(?Student $student): bool`.
  - Implement `eligibleStudentUserIds(): \Illuminate\Support\Collection`.

- [ ] **Step 1.4: Run unit tests and confirm green**
  - Run `php artisan test --filter=EventAudienceTargetingTest`.

---

### Task 2: Backend Audience Options Endpoint & Event Creation/Update Validation

**Files:**
- Modify: `backend/app/Http/Controllers/Api/V1/EventController.php`
- Modify: `backend/routes/api.php`
- Test: `backend/tests/Feature/EventAudienceOptionsAndValidationTest.php`

- [ ] **Step 2.1: Write failing test for audience-options endpoint and event creation validation**
  - Test `GET /api/v1/events/audience-options` returns distinct courses, year levels, sections, and default categories.
  - Test `POST /api/v1/events` accepts and saves `target_audience_type`, `target_courses`, `target_year_levels`, `target_rules`, `category`, and `send_announcement`.
  - Test validation fails if `target_audience_type` is invalid.

- [ ] **Step 2.2: Implement `audienceOptions` endpoint in EventController**
  - Fetch distinct non-null `course`, `year_level`, and `section` from `students` table, merged with standard institution values.
  - Return JSON response with `courses`, `year_levels`, `sections`, and `categories`.
  - Register route in `routes/api.php`.

- [ ] **Step 2.3: Update `store()` and `update()` validation in EventController**
  - Add validation rules for `category`, `cover_image_path`, `target_audience_type`, `target_courses`, `target_year_levels`, `target_sections`, `target_rules`, `send_announcement`.
  - Save attributes on create and update.

- [ ] **Step 2.4: Run tests and confirm green**
  - Run `php artisan test --filter=EventAudienceOptionsAndValidationTest`.

---

### Task 3: Backend Audience Filtering in Event Listing, Detail View, and Registration Guard

**Files:**
- Modify: `backend/app/Http/Controllers/Api/V1/EventController.php`
- Modify: `backend/app/Http/Controllers/Api/V1/RegistrationController.php`
- Test: `backend/tests/Feature/EventAudienceTargetingEnforcementTest.php`

- [ ] **Step 3.1: Write failing tests for audience targeting enforcement**
  - Test: BSIT 1st Year student sees only BSIT 1st Year and "All Students" events in `GET /api/v1/events`.
  - Test: BSIT 2nd Year student cannot see BSIT 1st Year event in `GET /api/v1/events`.
  - Test: BSBA student cannot access `GET /api/v1/events/{id}` for BSIT 1st Year event (returns 403 `ERR_AUDIENCE_INELIGIBLE`).
  - Test: BSBA student attempting `POST /api/v1/events/{id}/register` is rejected with 403 `ERR_AUDIENCE_INELIGIBLE`.
  - Test: Eligible BSIT 1st Year student can view and register normally.

- [ ] **Step 3.2: Implement audience filtering in `EventController::index()`**
  - If `$user->isStudent()`: filter events so only events where `$event->isStudentEligible($user->student)` are included in results.

- [ ] **Step 3.3: Implement audience guard in `EventController::show()`**
  - If `$user->isStudent()` and `!$event->isStudentEligible($user->student)`:
    - Return 403 JSON: `{ "success": false, "error_code": "ERR_AUDIENCE_INELIGIBLE", "message": "You are not eligible to view or register for this event based on audience criteria." }`.

- [ ] **Step 3.4: Implement audience guard in `RegistrationController::register()`**
  - Before checking capacity or dates: check `if (!$event->isStudentEligible($student))`.
  - Return 403 JSON: `{ "success": false, "error_code": "ERR_AUDIENCE_INELIGIBLE", "message": "You are not eligible to register for this event based on audience criteria." }`.

- [ ] **Step 3.5: Run tests and confirm green**
  - Run `php artisan test --filter=EventAudienceTargetingEnforcementTest`.

---

### Task 4: Backend Targeted Event Publishing Announcement Notifications

**Files:**
- Modify: `backend/app/Http/Controllers/Api/V1/EventController.php` (reviewApproval)
- Test: `backend/tests/Feature/EventAudienceNotificationTest.php`

- [ ] **Step 4.1: Write failing test for audience-targeted publishing announcements**
  - Test: When Admin approves an event with `target_audience_type = 'custom'` (BSIT 1st Year) and `send_announcement = true`:
    - BSIT 1st Year student receives `new_event_published` notification.
    - BSIT 2nd Year student does NOT receive notification.
    - BSBA student does NOT receive notification.
  - Test: When Admin approves an event with `send_announcement = false`:
    - Zero notifications are dispatched.
  - Test: Scheduled event reminders still only go to registered students.

- [ ] **Step 4.2: Update `reviewApproval()` in EventController**
  - Replace the unqualified `User::where('role_id', 3)` query with `$event->eligibleStudentUserIds()`.
  - Only dispatch notifications if `$event->send_announcement` is true.

- [ ] **Step 4.3: Run tests and confirm green**
  - Run `php artisan test --filter=EventAudienceNotificationTest`.

---

### Task 5: Mobile EventModel & API Constants Update

**Files:**
- Modify: `mobile/lib/core/constants/api_constants.dart`
- Modify: `mobile/lib/models/event_model.dart`
- Test: `mobile/test/models/event_model_test.dart`

- [ ] **Step 5.1: Write failing test for EventModel serialization with audience targeting**
  - Test JSON deserialization and serialization of `category`, `coverImagePath`, `targetAudienceType`, `targetCourses`, `targetYearLevels`, `targetSections`, `targetRules`, `sendAnnouncement`.

- [ ] **Step 5.2: Add API constant for audience options**
  - Add `static const String eventAudienceOptions = '/events/audience-options';` in `mobile/lib/core/constants/api_constants.dart`.

- [ ] **Step 5.3: Update EventModel with new fields**
  - Add fields, constructor parameters, default values, and JSON deserialization/serialization.

- [ ] **Step 5.4: Run test and confirm green**
  - Run `flutter test test/models/event_model_test.dart`.

---

### Task 6: Mobile Create Event Form Redesign (Sections A - F)

**Files:**
- Modify: `mobile/lib/screens/organizer/event_form_screen.dart`
- Test: `mobile/test/screens/event_form_redesign_test.dart`

- [ ] **Step 6.1: Write widget test for redesigned Create Event form sections**
  - Test that all 6 sections are present:
    - Section A: Event Information (Title, Description, Category, Venue)
    - Section B: Target Participants (Audience Selector: All Students, Course, Year Level, Custom Combination)
    - Section C: Event Schedule (Event Date, Start Time, End Time)
    - Section D: Registration Period (Registration Start/End, Max Capacity, Walk-in, Grace Period)
    - Section E: Notification Settings (Announcement Toggle)
    - Section F: Review and Publish (Live summary card, Submit for Approval, Save as Draft)

- [ ] **Step 6.2: Implement audience options fetching in `_EventFormScreenState`**
  - Call `GET /api/v1/events/audience-options` on init.
  - Fallback to standard defaults if offline/unreachable.

- [ ] **Step 6.3: Implement Section A (Event Information)**
  - Event Title, Event Description, Event Category (Dropdown), Event Venue, Cover Image URL / Path.

- [ ] **Step 6.4: Implement Section B (Target Participants / Audience Selection)**
  - Segmented option picker: All Students, Specific Course, Specific Year Level, Custom Combination.
  - Multi-select chips for courses (e.g. BSIT, BSCS, BSBA, etc.).
  - Multi-select chips for year levels (1st Year, 2nd Year, 3rd Year, 4th Year).
  - Custom combination builder (allows pairing course + year level).
  - Live summary preview pill showing selected audience.

- [ ] **Step 6.5: Implement Section C (Event Schedule) & Section D (Registration Window)**
  - Event date, start/end time pickers.
  - Registration start/end pickers, capacity, walk-in switch, grace period.

- [ ] **Step 6.6: Implement Section E (Notification Settings)**
  - Switch/checkbox for "Send event announcement notification when published".
  - Informational caption explaining audience-based delivery and registered-only reminders.

- [ ] **Step 6.7: Implement Section F (Review & Publish / Summary Card)**
  - Live preview summary card summarizing Title, Category, Schedule, Venue, Target Audience summary, Capacity, and Notification status.
  - Actions: "Submit for Approval" (primary) and "Save as Draft" (secondary).

- [ ] **Step 6.8: Run widget tests and confirm green**
  - Run `flutter test test/screens/event_form_redesign_test.dart`.

---

### Task 7: Mobile Event Detail Screen Audience & Category Badges

**Files:**
- Modify: `mobile/lib/screens/student/event_detail_screen.dart`
- Modify: `mobile/lib/core/widgets/event_card.dart`
- Test: `mobile/test/screens/event_detail_audience_badge_test.dart`

- [ ] **Step 7.1: Write widget test verifying category and audience badge rendering**
  - Test event card and detail screen render Category (e.g. `[Workshop]`) and Audience Badge (e.g. `[BSIT · 1st Year]` or `[All Students]`).

- [ ] **Step 7.2: Update EventCard and EventDetailScreen to display category and audience**
  - Render concise black-and-white pills for Category and Target Audience.

- [ ] **Step 7.3: Run tests and confirm green**
  - Run `flutter test test/screens/event_detail_audience_badge_test.dart`.

---

### Task 8: End-to-End Verification & Full Regression Testing

**Files:**
- Execute verification commands across backend and frontend.

- [ ] **Step 8.1: Run all backend tests**
  - Run `cd backend && php artisan test`.
  - Must pass 100% of tests (including all 64 existing + new tests).

- [ ] **Step 8.2: Run Flutter analyze and widget tests**
  - Run `cd mobile && flutter analyze`.
  - Run `cd mobile && flutter test`.

- [ ] **Step 8.3: Verify all 8 prompt scenarios**
  1. Organizer creates a BSIT 1st Year event.
  2. BSIT 1st Year students can see the event.
  3. BSIT 2nd Year students cannot see the event.
  4. Other programs cannot see the event.
  5. Only the selected audience receives the announcement.
  6. Registered students receive event reminders.
  7. All Students targeting works correctly.
  8. Existing event creation and registration still work.
