# Architecture and Code Organization

> **Connected Project Context & Specs:**
> - [`context.md`](../../context.md) — System overview, repository structure (`backend/` & `mobile/`), 13 domain tables, and current implementation status.
> - [`AGENTS.md`](../../AGENTS.md) — Non-negotiable domain & architectural invariants (Section 2).
> - [`System_Architecture_and_Database_Design.md`](../../System_Architecture_and_Database_Design.md) — Decoupled multi-tier architecture, sequence diagrams, state machines, and MySQL 8.0+ DDL.
> - [`REST_API_Specification.md`](../../REST_API_Specification.md) & [`openapi.yaml`](../../openapi.yaml) — Canonical `/api/v1/*` routes and payload contracts.

Design an architecture appropriate for the project's actual complexity.

Follow these principles:

- Separate UI, application logic, and data access (`mobile/lib/screens/`, `mobile/lib/models/`, `mobile/lib/core/network/api_client.dart` on the client; `backend/app/Http/Controllers/Api/V1/`, `backend/app/Services/`, `backend/app/Models/` on the server).
- Enforce the decoupled client-server boundary defined in [`context.md`](../../context.md) and [`AGENTS.md`](../../AGENTS.md): the Flutter client (`mobile/`) must communicate exclusively with the Laravel 11 REST API (`backend/routes/api.php`) over `/api/v1/*` and never connect directly to MySQL/MariaDB.
- Group related code into clearly named modules or features across the 4 fixed roles (`administrator`, `organizer`, `student`, `management`).
- Build reusable components where reuse is genuinely beneficial (e.g., `AppShell`, `AppPageScaffold`, `AppResponsivePage`, `ResponsiveGrid`, `AppButton`, `AppPressable`).
- Avoid duplicated code and unnecessary dependencies.
- Use consistent naming and file organization.
- Keep files focused on clear responsibilities.
- Make the application easy to test, debug, and extend.
- Avoid excessive abstraction or complicated architecture for simple features.
