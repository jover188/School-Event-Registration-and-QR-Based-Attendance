# Data, Backend, and Security

> **Connected Project Context & Specs:**
> - [`context.md`](../../context.md) — 13 domain database tables (Section 5), 4 RBAC roles (Section 4), permanent student QR identity rule, and Sanctum single-session auth.
> - [`AGENTS.md`](../../AGENTS.md) — Non-negotiable domain invariants (Section 2) and Laravel backend conventions (Section 3).
> - [`System_Architecture_and_Database_Design.md`](../../System_Architecture_and_Database_Design.md) — ER diagram, state machines, sequence diagrams, and MySQL 8.0+ DDL.
> - [`REST_API_Specification.md`](../../REST_API_Specification.md) & [`openapi.yaml`](../../openapi.yaml) — Standard JSON response envelopes, error codes, and `/api/v1/*` endpoint specifications.
> - [`School_Event_Attendance_SRS_v1.0.md`](../../School_Event_Attendance_SRS_v1.0.md) — Security requirements (`SEC-*`), QR rules (`QR-*`), and business rules.

Analyze the system's data requirements before implementing database or API functionality.

- Identify required data entities and relationships across the 13 domain tables defined in [`context.md`](../../context.md) and [`System_Architecture_and_Database_Design.md`](../../System_Architecture_and_Database_Design.md).
- Document expected API requests and responses in [`REST_API_Specification.md`](../../REST_API_Specification.md) and [`openapi.yaml`](../../openapi.yaml) using the standard `{ "success": true|false, ... }` JSON envelope.
- Use suitable validation on both the client and server.
- Enforce authentication (`auth:sanctum` + `single.session` via `EnforceSingleSession`) and role-based authorization (`CheckRole` for `administrator`, `organizer`, `student`, and strictly read-only `management`) on the trusted Laravel backend.
- Do not rely on hidden buttons or client-side restrictions for security.
- Never hardcode passwords, tokens, or private API keys.
- Use secure handling for sensitive local data (`FlutterSecureStorage` in `mobile/lib/core/network/api_client.dart`).
- Avoid unnecessary collection or exposure of personal information; permanent student QR tokens (`student_qrs.qr_token`) must be 64-character cryptographic hex strings (`bin2hex(random_bytes(32))`) with zero embedded PII.
- Handle connection failures, timeouts, and invalid responses (including 401 single-session termination callbacks).
- Define how duplicate submissions and repeated requests will be handled (unique `[event_id, student_id]` constraints on `event_registrations` and `attendances`, atomic `DB::transaction()` operations, and `ActivityLog::log(...)` audit trails).
- Consider offline behavior only when required by the approved SRS ([`School_Event_Attendance_SRS_v1.0.md`](../../School_Event_Attendance_SRS_v1.0.md)).
