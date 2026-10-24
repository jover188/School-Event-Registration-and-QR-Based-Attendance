# UI/UX Rules

> **Connected Project Context & Specs:**
> - [`context.md`](../../context.md) — Complete inventory of the 20 implemented screens across all 4 roles (`student`, `organizer`, `management`, `administrator`) and the **AetherUI** design token specification (`mobile/lib/core/theme/app_theme.dart`).
> - [`AGENTS.md`](../../AGENTS.md) — Role-based access boundaries (including strictly Read-Only `management` role with zero mutation controls) and mobile conventions.
> - [`School_Event_Attendance_SRS_v1.0.md`](../../School_Event_Attendance_SRS_v1.0.md) — User interface and role workflow requirements ( including visual identity verification during QR scanning).
> - [`.agents/rules/flutter-development-standards.md`](./flutter-development-standards.md) — Flutter implementation standards and responsive layout primitives.

Before implementing screens:

- Identify every screen required by [`School_Event_Attendance_SRS_v1.0.md`](../../School_Event_Attendance_SRS_v1.0.md) and [`context.md`](../../context.md) (Auth, Common, Student, Organizer, Management Read-Only, and Admin screens).
- Document navigation paths and user interactions across the adaptive `AppShell` (`<600` slide-over drawer + bottom nav, `600–1023` navigation rail, `1024+` sticky sidebar + top header).
- Adhere to the project's **AetherUI** visual design system (`AppDesignTokens.light` & `AppDesignTokens.dark`, `'Inter'` typography, `LucideIcons`, `#14B8A6` Teal success, `#F59E0B` Amber warning, `#EF4444` Red destructive, `8px` radius, `NoSplash.splashFactory`).
- Use clear labels, readable text, and appropriate spacing.
- Provide useful validation and error messages.
- Support accessibility, including readable contrast, `2x` text scaling down to `320px` width without overflow, and practical touch-target sizes (`48x48`).
- Consider keyboard behavior, scrolling, and smaller screens.
- Reuse existing designs and components (`AppPageScaffold`, `AppResponsivePage`, `ResponsiveGrid`, `ResponsiveCardSliver`, `ResponsiveQrFrame`, `AppButton`, `AppPressable`) where appropriate.

Do not invent unnecessary screens or redesign approved interfaces without authorization.
