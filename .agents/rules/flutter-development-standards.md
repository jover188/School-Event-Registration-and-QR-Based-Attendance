# Flutter Development Standards

> **Connected Project Context & Specs:**
> - [`context.md`](../../context.md) — Mobile application architecture (`mobile/`), **AetherUI** design tokens (`AppDesignTokens.light` & `AppDesignTokens.dark`), adaptive `AppShell` breakpoints (`<600`, `600–1023`, `1024+`), and all 20 role-based screens.
> - [`AGENTS.md`](../../AGENTS.md) — Mobile conventions (Section 4): Flutter binary path (`/home/thea/development/flutter/bin/flutter`), `ApiConstants`, `ApiClient`, and required `flutter analyze` / `flutter test` verification.
> - [`Project_Implementation_Plan.md`](../../Project_Implementation_Plan.md) — Mobile screen specifications and responsive UI implementation details.
> - [`.agents/rules/ui-ux-rules.md`](./ui-ux-rules.md) — UI/UX and accessibility standards.

Follow Flutter and Dart best practices.

- Prefer Flutter's built-in widgets and the project's established `shadcn_ui` (`ShadApp.custom`) + **AetherUI** primitives when they satisfy the requirements.
- Use the project's **AetherUI** design system (`mobile/lib/core/theme/app_theme.dart`, `AppDesignTokens.light` & `AppDesignTokens.dark`, `NoSplash.splashFactory`) rather than unstyled default Material chrome.
- Reuse and extend the project's shared UI elements (`AppButton`, `AppPressable`, `AppShell`, `AppPageScaffold`, `AppResponsivePage`, `ResponsiveGrid`, `ResponsiveCardSliver`, `ResponsiveQrFrame`).
- Centralize colors, typography (`'Inter'`), icons (`LucideIcons`), spacing, and status badge colors in `mobile/lib/core/theme/app_theme.dart`, and centralize API endpoint paths in `mobile/lib/core/constants/api_constants.dart`.
- Route all HTTP requests through `ApiClient()` (`mobile/lib/core/network/api_client.dart`) so Bearer tokens and 401 single-session termination callbacks are consistently handled.
- Support the screen sizes (`320px` at `2x` text scale through `1440px` desktop), orientations, accessibility settings, and operating systems (`Android`, `iOS`, `Linux Desktop`, `Web`) defined in [`context.md`](../../context.md).
- Handle loading, empty, success, and error states.
- Prevent layout overflow and unnecessary widget rebuilding.
- Follow Dart null-safety requirements.
- Dispose of controllers and other resources when necessary.
- Use asynchronous operations correctly to avoid freezing the interface.

Choose state management and navigation solutions only after evaluating the project's requirements.
