# Existing Project Inspection

> **Connected Project Context & Specs:**
> - [`context.md`](../../context.md) — High-level system overview, repository tree (`backend/` and `mobile/`), seeded roles/credentials, 13 database tables, and "Already Made" status summary.
> - [`AGENTS.md`](../../AGENTS.md) — Mandatory workspace rules, domain invariants, and verification commands.
> - [`Project_Implementation_Plan.md`](../../Project_Implementation_Plan.md) & [`Project_Plan.md`](../../Project_Plan.md) — Completed deliverables ("Already Made") vs. remaining continuation tasks.
> - [`School_Event_Attendance_SRS_v1.0.md`](../../School_Event_Attendance_SRS_v1.0.md), [`System_Architecture_and_Database_Design.md`](../../System_Architecture_and_Database_Design.md), [`REST_API_Specification.md`](../../REST_API_Specification.md), & [`openapi.yaml`](../../openapi.yaml) — Authoritative specifications.

Before modifying anything:

- Inspect the repository structure starting with [`context.md`](../../context.md) and [`AGENTS.md`](../../AGENTS.md).
- Identify the existing code, dependencies (`backend/composer.json`, `mobile/pubspec.yaml`), configuration files (`backend/phpunit.xml`, `mobile/analysis_options.yaml`), and root specification documentation.
- Identify the Flutter 3.x (`/home/thea/development/flutter/bin/flutter`), Dart 3.x, Laravel 11 / PHP 8.3+, and MySQL 8.0+ / MariaDB 13.x (plus SQLite `:memory:` for tests) versions currently in use.
- Review the existing architecture, role-based navigation (`mobile/lib/main.dart`, `AppShell`), state management, and API connections (`mobile/lib/core/constants/api_constants.dart`, `mobile/lib/core/network/api_client.dart`, `backend/routes/api.php`).
- Identify completed, incomplete, and potentially broken features by consulting [`context.md`](../../context.md), [`Project_Plan.md`](../../Project_Plan.md), and [`Project_Implementation_Plan.md`](../../Project_Implementation_Plan.md).
- Preserve all working functionality.
- Do not overwrite or restructure existing code without first explaining why the change is necessary.

If application code has not yet been created, plan its initial structure and record approved toolchain versions before generating project files.
