"""
part5.py - Chapters 19 to 22 + Glossary for Attendify Frontend Developer Guide.
Covers:
- Chapter 19: Coding Standards and Development Guidelines
- Chapter 20: Frontend Development Workflow
- Chapter 21: Known Issues and Pending Frontend Work
- Chapter 22: Frontend Developer Quick Reference Cheat Sheet
- Appendix & Glossary of Frontend Engineering Terms
"""

from .styles import (
    add_chapter_title, add_section_title, add_subsection_title,
    add_body_p, add_bullet_item, add_callout, add_styled_table, add_code_block
)

def add_part5(doc):
    # -------------------------------------------------------------
    # CHAPTER 19: CODING STANDARDS AND DEVELOPMENT GUIDELINES
    # -------------------------------------------------------------
    add_chapter_title(doc, "19", "Coding Standards & Development Guidelines")

    add_section_title(doc, "19.1", "Architectural & Styling Invariants")
    add_body_p(doc, "To preserve codebase cleanliness and visual consistency as new features are added, all frontend engineers must adhere to seven mandatory conventions:", bold_prefix="Development Standards: ")

    add_bullet_item(doc, "Never use raw `Color(0xFF...)` or `Colors.black` inside widgets. Always resolve colors dynamically through `context.design` (`AppDesignTokens`), e.g., `d.background`, `d.foreground`, `d.primary`.", bold_prefix="1. Zero Hardcoded Colors: ")
    add_bullet_item(doc, "Never connect directly to MySQL or write database drivers in Dart. All operations must flow through `ApiClient` and REST endpoints.", bold_prefix="2. Zero Direct Database Calls: ")
    add_bullet_item(doc, "Do not duplicate screens for Light and Dark modes. Write single responsive widgets that consume `context.design` tokens.", bold_prefix="3. Unified Responsive Widgets: ")
    add_bullet_item(doc, "Use `PascalCase` for classes/widgets, `camelCase` for variables/methods, `lower_snake_case` for filenames, and `UPPER_SNAKE_CASE` for constants.", bold_prefix="4. Strict Naming Conventions: ")
    add_bullet_item(doc, "Keep widgets under 250 lines. Break complex forms and dashboards into small, reusable sub-widgets.", bold_prefix="5. Single Responsibility Principle: ")
    add_bullet_item(doc, "Every `TextEditingController`, `AnimationController`, or `StreamSubscription` created in `initState()` must be disposed in `dispose()`.", bold_prefix="6. Explicit Lifecycle Disposal: ")
    add_bullet_item(doc, "Do not introduce heavy third-party packages without architectural review. Leverage Flutter's built-in SDK and existing dependencies.", bold_prefix="7. Dependency Restraint: ")

    # -------------------------------------------------------------
    # CHAPTER 20: FRONTEND DEVELOPMENT WORKFLOW
    # -------------------------------------------------------------
    add_chapter_title(doc, "20", "Frontend Development Workflow")

    add_section_title(doc, "20.1", "10-Step Feature Implementation Runbook")
    add_body_p(doc, "When implementing a new screen or modifying an existing feature in Attendify, follow this structured ten-step workflow:", bold_prefix="Engineering Workflow: ")

    workflow_steps = [
        ["Step 1", "Inspect Requirements", "Review SRS v1.1 and API contract in REST_API_Specification.md to understand the exact expected behavior."],
        ["Step 2", "Inspect Existing UI", "Examine related screens in mobile/lib/screens/ to ensure the new screen matches existing layout patterns."],
        ["Step 3", "Map API Endpoints", "Verify endpoint paths in mobile/lib/core/constants/api_constants.dart; add any newly created routes."],
        ["Step 4", "Plan Minimal Edits", "Identify minimal necessary files to touch, preserving surrounding architecture and navigation."],
        ["Step 5", "Implement Presentation", "Build the screen widget using AppPageScaffold, AetherUI tokens (context.design), and shared components."],
        ["Step 6", "Wire Network & State", "Connect the UI to ApiClient, handling loading spinners, error toasts, and empty state views."],
        ["Step 7", "Test Light & Dark Modes", "Verify visual contrast in both Light Mode and Dark Mode; ensure text remains clearly readable."],
        ["Step 8", "Run Automated Tests", "Execute 'flutter test' to verify that existing test suites pass without regression."],
        ["Step 9", "Author New Tests", "Add a corresponding widget test in mobile/test/screens/ utilizing AppTestHost."],
        ["Step 10", "Document Changes", "Update context.md and technical documentation before requesting code review."]
    ]
    add_styled_table(doc, ["Step Number", "Workflow Stage", "Action Required & Best Practices"], workflow_steps, col_widths=[1.2, 1.8, 3.5])

    # -------------------------------------------------------------
    # CHAPTER 21: KNOWN ISSUES AND PENDING FRONTEND WORK
    # -------------------------------------------------------------
    add_chapter_title(doc, "21", "Known Issues & Pending Frontend Work")

    add_section_title(doc, "21.1", "Operational Limitations & Status Classification")
    add_body_p(doc, "The table below catalogs known frontend operational constraints, unverified behaviors, and roadmap items:", bold_prefix="Operational Constraints: ")

    issues_headers = ["Issue ID", "Technical Description", "Subsystem", "Current Status", "Mitigation / Resolution"]
    issues_rows = [
        ["FE-ISS-01", "Render Free-Tier Cold Start (~50s delay on first request after 15 min inactivity).", "Network", "Unverified", "Display friendly 'Connecting to secure server...' toast banner on prolonged initial requests."],
        ["FE-ISS-02", "FCM push alert delivery on strict battery-saver Android OEMs (Xiaomi MIUI, Huawei).", "Notifications", "Under Testing", "Verify high-priority FCM payload delivery on physical devices during campus field testing."],
        ["FE-ISS-03", "Offline attendance queue and local SQLite caching for venue network outages.", "Architecture", "Pending (v2.0)", "Roadmap feature: Implement local SQLite buffer with background sync upon reconnection."],
        ["FE-ISS-04", "Android sideload 'Unknown Source' installation warning dialogs on unmanaged devices.", "Deployment", "Implemented", "Provide step-by-step installation runbook; configure institutional APK signing certificate."]
    ]
    add_styled_table(doc, issues_headers, issues_rows, col_widths=[0.9, 2.2, 1.1, 1.0, 1.8])

    # -------------------------------------------------------------
    # CHAPTER 22: FRONTEND DEVELOPER QUICK REFERENCE
    # -------------------------------------------------------------
    add_chapter_title(doc, "22", "Frontend Developer Quick Reference Guide")

    add_section_title(doc, "22.1", "Essential Flutter & ADB Command Cheat Sheet")
    add_body_p(doc, "A quick-reference guide of everyday commands for the Attendify frontend developer:")

    add_code_block(doc,
"""# 1. DEPENDENCIES & CLEANUP:
flutter pub get               # Install dependencies from pubspec.yaml
flutter clean                 # Clean build cache and generated files

# 2. RUNNING LOCALLY:
flutter run -d chrome         # Launch in Google Chrome (Web)
flutter run -d android        # Launch on connected Android device/emulator
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# 3. STATIC ANALYSIS & AUTOMATED TESTING:
flutter analyze               # Run Dart static analysis linter
flutter test                  # Run all 202 unit and widget tests
flutter test test/screens/theme_integration_test.dart  # Run single test

# 4. BUILDING PRODUCTION ARTIFACTS:
flutter build apk --release   # Compile release Android APK
flutter build web --release   # Compile production Flutter Web files

# 5. ANDROID LOGCAT & USB DEBUGGING:
adb devices                   # List connected physical devices / emulators
adb reverse tcp:8000 tcp:8000 # Reverse local backend port to phone over USB
adb logcat -s flutter         # Stream Flutter application debug logs""")

    add_section_title(doc, "22.2", "Key File Paths & Entrypoint Directory")
    add_bullet_item(doc, "mobile/lib/main.dart", bold_prefix="Application Entrypoint: ")
    add_bullet_item(doc, "mobile/lib/core/network/api_client.dart", bold_prefix="Central API Client: ")
    add_bullet_item(doc, "mobile/lib/core/constants/api_constants.dart", bold_prefix="REST Endpoint Constants: ")
    add_bullet_item(doc, "mobile/lib/core/theme/theme_controller.dart", bold_prefix="Theme Mode Controller: ")
    add_bullet_item(doc, "mobile/lib/core/theme/app_tokens.dart", bold_prefix="AetherUI Design Tokens: ")
    add_bullet_item(doc, "mobile/lib/core/widgets/app_shell.dart", bold_prefix="Responsive Navigation Shell: ")
    add_bullet_item(doc, "mobile/lib/core/services/push_notification_service.dart", bold_prefix="FCM Push Notification Service: ")
    add_bullet_item(doc, "mobile/lib/core/services/realtime_notification_service.dart", bold_prefix="In-App Realtime Notification Service: ")
    add_bullet_item(doc, "mobile/test/support/app_test_host.dart", bold_prefix="Automated Widget Test Harness: ")

    # -------------------------------------------------------------
    # GLOSSARY OF FRONTEND TERMS
    # -------------------------------------------------------------
    add_chapter_title(doc, "23", "Glossary of Frontend Technical Terms")

    glossary_data = [
        ["AetherUI", "The bespoke design token and component library created for Attendify, featuring high-contrast black/white styling, WCAG AA compliance, and responsive layouts."],
        ["ApiClient", "The singleton HTTP network client in Attendify that manages headers, Bearer tokens, timeouts, single-session interception, and response envelope parsing."],
        ["AppShell", "The adaptive navigation widget in Attendify that dynamically renders a bottom navigation bar, a navigation rail, or a persistent sidebar depending on screen width."],
        ["AppThemeController", "The singleton ChangeNotifier managing theme mode selection (Light, Dark, System Default) and persisting user choice in SharedPreferences."],
        ["FCM (Firebase Cloud Messaging)", "Google's cross-platform push notification infrastructure used to deliver background event alerts and announcements to native mobile devices."],
        ["FIFO Waiting List", "First-In, First-Out queue used in event registration that automatically promotes the earliest waiting student when a registered student cancels."],
        ["MobileScanner", "The hardware camera integration plugin used by Attendify to execute sub-second QR code decoding at event entrances."],
        ["Permanent QR Token", "An opaque 64-character hexadecimal cryptographic string bound to a student's institutional identity without embedding personal information."],
        ["Sanctum Token", "Laravel's personal access token issued to authenticated clients and passed as a Bearer token in the HTTP Authorization header."],
        ["Single Active Session", "Security enforcement preventing concurrent logins by issuing a unique session UUID and revoking previous tokens upon fresh authentication."]
    ]
    add_styled_table(doc, ["Term", "Definition & Operational Context in Attendify"], glossary_data, col_widths=[1.8, 4.7])
