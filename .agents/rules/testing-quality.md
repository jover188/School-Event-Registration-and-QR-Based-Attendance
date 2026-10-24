# Testing and Quality

> **Connected Project Context & Specs:**
> - [`context.md`](../../context.md) — Test suite overview: 44 Laravel feature/unit tests on in-memory SQLite (`backend/tests/Feature/`) and 54 Flutter unit/widget tests (`mobile/test/`).
> - [`AGENTS.md`](../../AGENTS.md) — Testing safety rules (Section 3: keep `DB_CONNECTION=sqlite` and `DB_DATABASE=:memory:` in `backend/phpunit.xml` so `php artisan test` never mutates or wipes the local MySQL/MariaDB `school_event_attendance` database) and mobile verification commands (Section 4).
> - [`School_Event_Attendance_SRS_v1.0.md`](../../School_Event_Attendance_SRS_v1.0.md) — Functional, security, and acceptance criteria baseline.
> - [`REST_API_Specification.md`](../../REST_API_Specification.md) & [`openapi.yaml`](../../openapi.yaml) — Expected HTTP status codes (`200`, `201`, `400`, `401`, `403`, `404`, `409`, `422`, `429`) and response envelopes.

Every implemented feature must be verified against its approved SRS requirements in [`School_Event_Attendance_SRS_v1.0.md`](../../School_Event_Attendance_SRS_v1.0.md).

- Create unit and feature tests for important backend logic (`backend/tests/Feature/`) and model/service behavior.
- Create widget and unit tests for important Flutter UI and client behavior (`mobile/test/`).
- Create integration tests for critical user workflows when practical (registration, waiting list auto-promotion, QR check-in/out, late detection, attendance correction, RBAC enforcement, single-session invalidation).
- Test valid, invalid, empty, duplicate, and unexpected inputs.
- Test loading, network failure, and recovery behavior.
- Run formatting, static analysis, and relevant tests before claiming completion:
  - Backend (`backend/`): `php artisan test` (using SQLite `:memory:` per `backend/phpunit.xml`).
  - Mobile (`mobile/`): `/home/thea/development/flutter/bin/flutter analyze` and `/home/thea/development/flutter/bin/flutter test`.
- Fix errors introduced by the implementation.
- Clearly report any tests that could not be executed.
