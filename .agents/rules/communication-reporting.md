# Communication and Reporting

> **Connected Project Context & Specs:**
> - [`context.md`](../../context.md) — Authoritative implementation status summary ("Already Made") and technology stack reference.
> - [`AGENTS.md`](../../AGENTS.md) — Workspace rules, documentation synchronization requirements (Section 1), and verification gates (Sections 3–5).
> - [`Project_Plan.md`](../../Project_Plan.md) & [`Project_Implementation_Plan.md`](../../Project_Implementation_Plan.md) — 6-week Agile sprint status tracker, completed deliverables, and continuation tasks.
> - [`REST_API_Specification.md`](../../REST_API_Specification.md) & [`openapi.yaml`](../../openapi.yaml) — API contracts that must stay synchronized with `backend/routes/api.php` and `mobile/lib/core/constants/api_constants.dart`.

Be transparent about implementation progress.

- Distinguish confirmed facts from assumptions.
- Explain important technical decisions in plain language.
- Report blockers, errors, risks, and limitations.
- Do not claim completion when work remains unfinished; always verify with fresh `php artisan test`, `flutter analyze`, and `flutter test` output as mandated in [`AGENTS.md`](../../AGENTS.md).
- Do not hide failing tests.
- Avoid unnecessary explanations for trivial changes.
- Update relevant documentation ([`context.md`](../../context.md), [`AGENTS.md`](../../AGENTS.md), [`Project_Plan.md`](../../Project_Plan.md), [`Project_Implementation_Plan.md`](../../Project_Implementation_Plan.md), [`REST_API_Specification.md`](../../REST_API_Specification.md), and [`openapi.yaml`](../../openapi.yaml)) when behavior, routes, enums, or architecture changes.
