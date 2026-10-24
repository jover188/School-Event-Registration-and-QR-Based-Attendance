# Dependencies and External Packages

> **Connected Project Context & Specs:**
> - [`context.md`](../../context.md) — Technology stack & approved packages (`Laravel 11 / PHP 8.3+`, `Sanctum 4.x`, `barryvdh/laravel-dompdf`, `maatwebsite/excel`, `Flutter 3.x / Dart 3.x`, `shadcn_ui`, `lucide_icons_flutter`, `qr_flutter`, `mobile_scanner`, `flutter_secure_storage`, `http`, `image_picker`, `cached_network_image`).
> - [`AGENTS.md`](../../AGENTS.md) — Invariant #9 (no external LLM/AI runtime SDKs) and backend/mobile conventions (`backend/composer.json`, `mobile/pubspec.yaml`).
> - [`School_Event_Attendance_SRS_v1.0.md`](../../School_Event_Attendance_SRS_v1.0.md) — Approved technology constraints and out-of-scope boundaries (Sections 17 & 33.7).

Before installing any package:

- Explain why the package is needed.
- Check compatibility with the current Flutter 3.x, Dart 3.x, Laravel 11 / PHP 8.3+, MySQL 8.0+ / MariaDB 13.x, SQLite (`:memory:` test database), and other affected platform versions documented in [`context.md`](../../context.md).
- Review its maintenance status and relevant security concerns.
- Prefer existing or built-in solutions when suitable.
- Avoid multiple libraries that solve the same problem.
- Do not add external AI/LLM runtime SDKs (strictly out of scope per [`AGENTS.md`](../../AGENTS.md) and [`School_Event_Attendance_SRS_v1.0.md`](../../School_Event_Attendance_SRS_v1.0.md)).
- Do not upgrade unrelated dependencies without justification.
