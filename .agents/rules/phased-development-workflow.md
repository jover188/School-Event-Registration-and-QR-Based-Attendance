# Phased Development Workflow

> **Connected Project Context & Specs:**
> - [`context.md`](../../context.md) — Current implementation status ("Already Made") across backend and mobile subsystems.
> - [`Project_Plan.md`](../../Project_Plan.md) — 6-Week Agile Sprint Plan (Sprints 1–6) and milestone status tracker.
> - [`Project_Implementation_Plan.md`](../../Project_Implementation_Plan.md) — Detailed task-by-task implementation plan, completed deliverables, and continuation tasks.
> - [`AGENTS.md`](../../AGENTS.md) — Multi-agent & skill workflow guidelines (Section 5) and documentation synchronization rules (Section 1).
> - [`School_Event_Attendance_SRS_v1.0.md`](../../School_Event_Attendance_SRS_v1.0.md) — Approved requirements baseline (v1.1).

Work in small, manageable phases aligned with [`Project_Plan.md`](../../Project_Plan.md) and [`Project_Implementation_Plan.md`](../../Project_Implementation_Plan.md).

For each phase:

1. Identify the requirements covered in [`School_Event_Attendance_SRS_v1.0.md`](../../School_Event_Attendance_SRS_v1.0.md) and [`Project_Implementation_Plan.md`](../../Project_Implementation_Plan.md).
2. Explain the proposed implementation.
3. List the files likely to be created or modified across `backend/`, `mobile/`, and root specification docs.
4. Identify dependencies and risks.
5. Implement only the approved scope.
6. Add or update relevant tests (`backend/tests/Feature/` and `mobile/test/`).
7. Run applicable checks (`php artisan test`, `/home/thea/development/flutter/bin/flutter analyze`, `/home/thea/development/flutter/bin/flutter test`).
8. Summarize completed work, update [`context.md`](../../context.md) / [`Project_Plan.md`](../../Project_Plan.md) / [`Project_Implementation_Plan.md`](../../Project_Implementation_Plan.md) when deliverables change, and report any remaining issues.

Avoid modifying unrelated features.

Do not proceed to another major phase without reviewing the previous phase's results.
