"""
part1.py - Chapters 1 to 5 for Attendify Frontend Developer Guide.
Covers:
- Chapter 1: Frontend Project Overview
- Chapter 2: Development Environment Setup
- Chapter 3: Frontend Architecture (with Architecture Diagram)
- Chapter 4: Complete Frontend Folder Structure
- Chapter 5: Application Navigation (with Navigation Flow Diagram)
"""

from .styles import (
    add_chapter_title, add_section_title, add_subsection_title,
    add_body_p, add_bullet_item, add_callout, add_styled_table, add_code_block
)

def add_part1(doc):
    # -------------------------------------------------------------
    # CHAPTER 1: FRONTEND PROJECT OVERVIEW
    # -------------------------------------------------------------
    add_chapter_title(doc, "1", "Frontend Project Overview")

    add_section_title(doc, "1.1", "Introduction to Attendify Frontend")
    add_body_p(doc, "The Attendify client application (`mobile/`) is a high-performance, cross-platform Flutter application engineered to provide institutional students, event organizers, school administrators, and executives with a unified, role-governed event registration and attendance experience.", bold_prefix="System Identity: ")
    add_body_p(doc, "Unlike fragmented institutional software that uses disparate systems for mobile users and desktop administrators, Attendify compiles from a single Dart codebase into both an Android Native APK (for on-the-go camera scanning and student self-service) and a responsive Flutter Web Single-Page Application (for wide-screen administrative oversight, calendar management, and multi-format report exports).", bold_prefix="Unified Cross-Platform Model: ")

    add_section_title(doc, "1.2", "Frontend Responsibilities & System Boundaries")
    add_body_p(doc, "The Attendify frontend operates under a strict Zero Client-Database Exposure policy. Its architectural responsibilities are clearly bounded:")
    add_bullet_item(doc, "Rendering 20 adaptive, role-based screens utilizing the bespoke AetherUI design system and shadcn_ui component library.", bold_prefix="1. Presentation & Interaction: ")
    add_bullet_item(doc, "Real-time input validation for institutional email addresses, numeric Student IDs, event parameters, and attendance justification notes before network dispatch.", bold_prefix="2. Client-Side Validation: ")
    add_bullet_item(doc, "Driving the physical camera via the `mobile_scanner` hardware plugin, executing sub-second barcode decoding, and triggering haptic vibration and audio confirmation chimes.", bold_prefix="3. Hardware Integration: ")
    add_bullet_item(doc, "Routing all operations through a centralized `ApiClient` network interceptor that manages Bearer tokens, active session UUIDs, 401 single-session revocation dialogs, and automated Android emulator host fallback.", bold_prefix="4. REST Communication: ")
    add_bullet_item(doc, "Maintaining active session tokens in `FlutterSecureStorage` (with SharedPreferences fallback) and persisting user interface theme modes (Light / Dark / System Default).", bold_prefix="5. State & Preference Persistence: ")

    add_section_title(doc, "1.3", "Supported Target Platforms")
    add_body_p(doc, "The Attendify frontend is built and tested against three primary deployment targets:")
    add_bullet_item(doc, "Compiled into release APKs (`app-release.apk`) supporting Android 8.0 (API level 26) through Android 14 (API level 34). Utilizes hardware camera, FCM push notifications, and vibration feedback.", bold_prefix="Android Native APK: ")
    add_bullet_item(doc, "Compiled via Flutter's web engine and served directly from the Laravel backend public distribution directory (`backend/public/`). Accessible across modern desktop and mobile browsers (Chrome, Edge, Safari, Brave).", bold_prefix="Flutter Web Portal: ")
    add_bullet_item(doc, "Fully responsive layouts scale fluidly to macOS, Windows, and Linux desktop form factors when running in wide-screen desktop browsers.", bold_prefix="Desktop Web & Intranet: ")

    add_section_title(doc, "1.4", "Frontend & Backend Relationship")
    add_body_p(doc, "The frontend application is completely decoupled from the Laravel backend. The Flutter app has zero direct database connections (no SQL drivers or direct socket connections to MySQL/MariaDB). All data mutations and state queries flow over HTTPS through the canonical `/api/v1/*` REST API. The backend acts as the sole authority for business rules, late arrival evaluation, capacity capping, waiting list queue promotion, and audit logging.", bold_prefix="Decoupled Client-Server Architecture: ")

    add_section_title(doc, "1.5", "Core Frontend Technologies")
    add_bullet_item(doc, "Cross-platform UI toolkit providing 60 FPS hardware-accelerated rendering via the Skia / Impeller graphic engines.", bold_prefix="Flutter SDK (3.x): ")
    add_bullet_item(doc, "Strongly typed, sound null-safe object-oriented language utilizing modern pattern matching and asynchronous streams.", bold_prefix="Dart SDK (3.x): ")
    add_bullet_item(doc, "Lightweight, un-opinionated UI primitives providing accessible dropdowns, dialogs, form fields, and popovers.", bold_prefix="Shadcn UI (0.57.x): ")
    add_bullet_item(doc, "High-performance camera integration for real-time barcode and QR code decoding on Android devices.", bold_prefix="Mobile Scanner (5.1.x): ")
    add_bullet_item(doc, "Vector QR code generator rendering crisp, high-contrast 64-character cryptographic tokens on student screens.", bold_prefix="QR Flutter (4.1.x): ")
    add_bullet_item(doc, "Google push notification infrastructure handling background alerts, token registration, and notification routing.", bold_prefix="Firebase Cloud Messaging: ")

    # -------------------------------------------------------------
    # CHAPTER 2: DEVELOPMENT ENVIRONMENT SETUP
    # -------------------------------------------------------------
    add_chapter_title(doc, "2", "Development Environment Setup & Toolchain")

    add_section_title(doc, "2.1", "Prerequisites & Toolchain Installation")
    add_body_p(doc, "To set up a local development workstation for Attendify frontend development, install the following foundational tools:")
    add_bullet_item(doc, "Install Flutter SDK stable channel (version 3.22.x or later). Ensure the `flutter/bin` directory is added to your system `PATH`.", bold_prefix="1. Flutter SDK: ")
    add_bullet_item(doc, "Install Android Studio (Hedgehog / Iguana or later) with Android SDK Build-Tools, Command-line Tools, and Android SDK Platform 34.", bold_prefix="2. Android Studio & SDK: ")
    add_bullet_item(doc, "Install OpenJDK 17. Ensure `JAVA_HOME` is configured in your system environment variables.", bold_prefix="3. Java Development Kit (JDK 17): ")
    add_bullet_item(doc, "Install Visual Studio Code along with the official 'Flutter' (Dart-Code.flutter) and 'Dart' (Dart-Code.dart-code) extensions.", bold_prefix="4. Code Editor: ")

    add_section_title(doc, "2.2", "Verifying the Environment")
    add_body_p(doc, "Execute the Flutter environment diagnostic tool to verify that all compilers and toolchains are correctly configured:")
    add_code_block(doc, "flutter doctor -v")
    add_body_p(doc, "Ensure the output reports green checks for Flutter, Android toolchain, Chrome (for web debugging), and your chosen IDE.")

    add_section_title(doc, "2.3", "Cloning & Installing Dependencies")
    add_body_p(doc, "Clone the Attendify repository, navigate into the `mobile/` directory, and fetch all Dart dependencies declared in `pubspec.yaml`:")
    add_code_block(doc, 
"""cd School-Event-Registration-and-QR-Based-Attendance/mobile
flutter pub get""")

    add_section_title(doc, "2.4", "Running the Application Locally")
    add_body_p(doc, "Attendify can be executed across multiple target devices during development:")
    add_bullet_item(doc, "Start a connected Android emulator or physical device via USB debugging, then launch the app pointing to your local Laravel server:", bold_prefix="Running on Android: ")
    add_code_block(doc, "flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1")
    add_bullet_item(doc, "Launch the application in Google Chrome or as a local web server for rapid web debugging:", bold_prefix="Running on Web: ")
    add_code_block(doc, "flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1")

    add_section_title(doc, "2.5", "Building Release Artifacts")
    add_body_p(doc, "To compile production-ready artifacts for release distribution:")
    add_bullet_item(doc, "Generates an optimized, signed release APK located at `build/app/outputs/flutter-apk/app-release.apk`:", bold_prefix="Compile Android APK: ")
    add_code_block(doc, "flutter build apk --release")
    add_bullet_item(doc, "Compiles the web application into minified JavaScript, HTML, and CanvasKit binaries located in `build/web/`:", bold_prefix="Compile Flutter Web: ")
    add_code_block(doc, "flutter build web --release")

    # -------------------------------------------------------------
    # CHAPTER 3: FRONTEND ARCHITECTURE
    # -------------------------------------------------------------
    add_chapter_title(doc, "3", "Frontend Architecture & System Layers")

    add_section_title(doc, "3.1", "Layered Architecture Breakdown")
    add_body_p(doc, "The Attendify frontend adheres to a strict layered architectural pattern that separates presentation widgets, layout scaffolding, state controllers, network clients, and data models:", bold_prefix="Architectural Philosophy: ")
    add_bullet_item(doc, "Houses role-specific screens (Student, Organizer, Administrator, Management) and shared screens (Calendar, Notifications, Profile, Reports).", bold_prefix="1. Presentation Layer (`screens/`): ")
    add_bullet_item(doc, "Reusable, un-opinionated UI widgets (`AppButton`, `EventCard`, `StatusBadge`, `StatMetricCard`) and responsive scaffolding (`AppShell`, `AppPageScaffold`).", bold_prefix="2. Component & Layout Layer (`core/widgets/`, `core/layout/`): ")
    add_bullet_item(doc, "Bespoke design token system (`AppTokens`, `AppPalette`, `AppTheme`) providing WCAG AA-compliant Light Mode, Dark Mode, and System Default themes.", bold_prefix="3. Design System Layer (`core/theme/`): ")
    add_bullet_item(doc, "Reactive state coordinators managing global theme mode (`AppThemeController`), real-time notification streams (`RealtimeNotificationService`), and push messaging (`PushNotificationService`).", bold_prefix="4. State & Service Layer (`core/services/`, `core/theme/`): ")
    add_bullet_item(doc, "Centralized HTTP client (`ApiClient`) managing Bearer authentication headers, token storage via `FlutterSecureStorage`, session UUID tracking, and 401 interception.", bold_prefix="5. Network & Integration Layer (`core/network/`, `core/constants/`): ")
    add_bullet_item(doc, "Strongly typed Dart data classes (`UserModel`, `EventModel`, `AttendanceModel`) with serialization logic (`fromJson`, `toJson`).", bold_prefix="6. Domain Data Model Layer (`models/`): ")

    add_section_title(doc, "3.2", "Frontend Architecture Interaction Diagram")
    add_body_p(doc, "The diagram below illustrates how client layers interact from user interface down to the backend network boundary:")

    add_code_block(doc,
"""+-------------------------------------------------------------------------+
|                         USER INTERACTION LAYER                          |
|  [Flutter Web Browser (Desktop/Mobile)]   |   [Native Android Device]   |
+-------------------------------------------------------------------------+
                                    |
                                    v
+-------------------------------------------------------------------------+
|                  APPLICATION SHELL & NAVIGATION LAYER                   |
|  - main.dart (GlobalKey<NavigatorState>, Single-Session Dialog Handler) |
|  - AppShell (Adaptive Navigation: BottomNav <600px, Sidebar >1024px)   |
|  - Header: [Logo] [Title] ---------> [Bell] [Theme Toggle] [Profile]   |
+-------------------------------------------------------------------------+
                                    |
                                    v
+-------------------------------------------------------------------------+
|                    PRESENTATION LAYER (20 SCREENS)                      |
|  - Auth: LoginScreen                                                    |
|  - Student: Dashboard, Permanent QR, Event Detail, Registrations, Hist  |
|  - Organizer: Dashboard, Event Form, Registrations, Live Attendance, QR |
|  - Admin: Dashboard, User Management, Activity Logs, QR Inspection      |
|  - Management: Management Dashboard (Strictly Read-Only Analytics)      |
|  - Common: CalendarScreen, NotificationsScreen, ProfileScreen, Reports  |
+-------------------------------------------------------------------------+
                                    |
         +--------------------------+--------------------------+
         |                                                     |
         v                                                     v
+----------------------------------+   +----------------------------------+
|   REUSABLE UI COMPONENTS LAYER   |   |   STATE & COORDINATION LAYER     |
| - AppPageScaffold, AppButton     |   | - AppThemeController (Light/Dark)|
| - EventCard, StatMetricCard      |   | - RealtimeNotificationService    |
| - StatusBadge, SectionHeader     |   | - PushNotificationService (FCM)  |
| - EmptyStateView, ErrorStateView |   | - ValueNotifiers & Streams       |
+----------------------------------+   +----------------------------------+
         |                                                     |
         +--------------------------+--------------------------+
                                    |
                                    v
+-------------------------------------------------------------------------+
|                     NETWORK & SECURITY CLIENT LAYER                     |
|  - ApiClient (Singleton HTTP Client with Timeout & Mocking Harness)     |
|  - Storage: FlutterSecureStorage (Primary) + SharedPreferences (Backup) |
|  - Single-Session Interceptor: 401 ERR_SESSION_TERMINATED Detection     |
|  - Emulator Host Auto-Probe: 127.0.0.1 -> 10.0.2.2 Fallback            |
|  - ApiConstants (Centralized REST Endpoint URI Dictionary)              |
+-------------------------------------------------------------------------+
                                    |
                                    v  HTTPS JSON REST API
+-------------------------------------------------------------------------+
|                      LARAVEL 11 REST API BACKEND                        |
|             (Render Cloud Web Service / MySQL 8.0 Database)             |
+-------------------------------------------------------------------------+""")

    # -------------------------------------------------------------
    # CHAPTER 4: COMPLETE FRONTEND FOLDER STRUCTURE
    # -------------------------------------------------------------
    add_chapter_title(doc, "4", "Complete Frontend Folder Structure")

    add_section_title(doc, "4.1", "Directory Organization & Architectural Roles")
    add_body_p(doc, "The `mobile/lib/` source tree is structured into modular namespaces to enforce clean separation of concerns and high component reusability:", bold_prefix="Folder Architecture: ")

    dir_headers = ["Directory Path", "Subsystem Role", "Reusability Scope", "Core Responsibility"]
    dir_rows = [
        ["lib/main.dart", "Entrypoint", "App-Wide", "Initializes Flutter bindings, AppThemeController, PushNotificationService, single-session listeners, and root MaterialApp."],
        ["lib/core/constants/", "Constants", "App-Wide", "Contains `api_constants.dart` defining all canonical REST API endpoint paths, base URL resolution, and environment variables."],
        ["lib/core/layout/", "Responsive Layout", "Reusable", "Contains `responsive_layout.dart` defining breakpoints: compact (<600px), medium (600-1024px), and expanded (>1024px)."],
        ["lib/core/navigation/", "Navigation", "App-Wide", "Contains `app_destination.dart` defining navigation destination model (id, label, icon, category, essential flag)."],
        ["lib/core/network/", "Networking", "App-Wide", "Contains `api_client.dart` managing HTTP requests, Bearer token injection, session termination listeners, and response envelopes."],
        ["lib/core/services/", "Services", "App-Wide", "Contains `push_notification_service.dart` (FCM) and `realtime_notification_service.dart` (polling, sound chimes, unread counts)."],
        ["lib/core/theme/", "Design System", "App-Wide", "Contains `app_tokens.dart` (AetherUI tokens), `app_theme.dart` (ThemeData), and `theme_controller.dart` (Light/Dark persistence)."],
        ["lib/core/utils/", "Utilities", "Reusable", "Platform-specific helpers: file downloaders (web vs IO), audio chime stubs, and notification sound managers."],
        ["lib/core/widgets/", "UI Primitives", "Reusable", "Shared design components: `AppButton`, `AppShell`, `EventCard`, `StatusBadge`, `StatMetricCard`, `ThemeToggleButton`."],
        ["lib/models/", "Data Models", "App-Wide", "Strongly typed domain models: `UserModel`, `EventModel`, `AttendanceModel` with JSON serialization."],
        ["lib/screens/admin/", "Admin Screens", "Feature-Specific", "Administrative features: `AdminDashboardScreen`, `UserManagementScreen`, `ActivityLogsScreen`, `StudentQrInspectScreen`."],
        ["lib/screens/auth/", "Authentication", "Feature-Specific", "Authentication views: `LoginScreen` and `AccountInput` supporting email and Student ID authentication."],
        ["lib/screens/common/", "Shared Screens", "Shared Features", "Cross-role shared views: `CalendarScreen`, `NotificationsScreen`, `NotificationPreferencesScreen`, `ProfileScreen`, `ReportsScreen`."],
        ["lib/screens/management/", "Management", "Feature-Specific", "Executive views: `ManagementDashboardScreen` providing strictly read-only participation analytics."],
        ["lib/screens/organizer/", "Organizer", "Feature-Specific", "Event staff views: `OrganizerDashboardScreen`, `EventFormScreen`, `EventRegistrationsScreen`, `LiveAttendanceScreen`, `QrScannerScreen`."],
        ["lib/screens/student/", "Student", "Feature-Specific", "Student views: `StudentDashboardScreen`, `PermanentQrScreen`, `EventDetailScreen`, `MyRegistrationsScreen`, `MyAttendanceHistoryScreen`."]
    ]
    add_styled_table(doc, dir_headers, dir_rows, col_widths=[1.5, 1.2, 1.1, 2.7])

    # -------------------------------------------------------------
    # CHAPTER 5: APPLICATION NAVIGATION
    # -------------------------------------------------------------
    add_chapter_title(doc, "5", "Application Navigation & Route Architecture")

    add_section_title(doc, "5.1", "Initial Screen Resolution & Route Protection")
    add_body_p(doc, "Attendify employs a state-driven initial route resolver (`_resolveInitialScreen()`) defined in `mobile/lib/main.dart`. Upon application boot:", bold_prefix="Resolution Lifecycle: ")
    add_bullet_item(doc, "The application checks `FlutterSecureStorage` (with SharedPreferences fallback) for an existing Bearer token and saved user role.", bold_prefix="1. Token Verification: ")
    add_bullet_item(doc, "If no token is present, or if the role cannot be verified, the user is routed directly to `LoginScreen`.", bold_prefix="2. Unauthenticated Redirect: ")
    add_bullet_item(doc, "If a valid token exists, the app initializes the `RealtimeNotificationService` and syncs the device FCM token via `PushNotificationService.syncDeviceToken()`.", bold_prefix="3. Service Initialization: ")
    add_bullet_item(doc, "The app evaluates `user.role` and renders the appropriate role dashboard: `StudentDashboardScreen` for students, `OrganizerDashboardScreen` for organizers, `AdminDashboardScreen` for administrators, and `ManagementDashboardScreen` for management.", bold_prefix="4. Role-Based Landing: ")

    add_section_title(doc, "5.2", "Adaptive Navigation Architecture via AppShell")
    add_body_p(doc, "Navigation within role workspaces is managed by `AppShell` (`mobile/lib/core/widgets/app_shell.dart`). Rather than destroying and recreating navigation chrome on every transition, `AppShell` provides an adaptive shell that responds dynamically to screen width:", bold_prefix="Responsive Scaffolding: ")
    add_bullet_item(doc, "Displays a sleek bottom navigation bar for primary destinations (up to 4 items) and a 'More' icon that slides out a modal drawer for secondary destinations and logout.", bold_prefix="Compact Viewports (<600px): ")
    add_bullet_item(doc, "Collapses the navigation drawer into a slim vertical navigation rail, preserving horizontal screen real estate.", bold_prefix="Medium Viewports (600px - 1024px): ")
    add_bullet_item(doc, "Renders a persistent, full-height navigation sidebar with categorized section headers, brand logo, user profile badge, and one-tap destination items.", bold_prefix="Expanded Viewports (>1024px): ")

    add_section_title(doc, "5.3", "Top Navigation Bar Chrome & Action Controls")
    add_body_p(doc, "Regardless of viewport size, `AppShell` renders a consistent top application bar featuring:", bold_prefix="Header Chrome: ")
    add_bullet_item(doc, "Interactive bell icon connected to `RealtimeNotificationService.unreadCount`. Displays a real-time numeric badge for unread alerts; tapping navigates to `NotificationsScreen`.", bold_prefix="1. Notification Bell: ")
    add_bullet_item(doc, "Sleek sun/moon action icon connected to `AppThemeController`. Tapping immediately switches the active theme between Light Mode and Dark Mode across the entire widget tree.", bold_prefix="2. Theme Toggle Button: ")
    add_bullet_item(doc, "User avatar badge; tapping opens the `ProfileScreen` where users can view academic attributes, change passwords, and configure theme preferences.", bold_prefix="3. Profile Icon: ")

    add_section_title(doc, "5.4", "Navigation Flow Diagram")
    add_code_block(doc,
"""+-------------------------------------------------------------------------+
|                        APP BOOT: main.dart                              |
|                _resolveInitialScreen() executes                         |
+-------------------------------------------------------------------------+
                                    |
                    +---------------+---------------+
                    |                               |
          No Token / Expired                Valid Token & Role
                    |                               |
                    v                               v
         +--------------------+         +------------------------+
         |    LoginScreen     |         |   Role Route Resolver  |
         | (Email/ID + Pass)  |         +------------------------+
         +--------------------+                     |
                    |                               +------------+
        Successful Authentication                   |            |
                    +-------------------------------+            |
                    |                                            |
                    v                                            v
    +--------------------------------+          +--------------------------------+
    |  STUDENT WORKSPACE (AppShell)  |          | ORGANIZER WORKSPACE (AppShell) |
    | - Dashboard (Upcoming, Stats)  |          | - Dashboard (Event Analytics)  |
    | - Permanent QR Badge Screen    |          | - Event Form (Create / Edit)   |
    | - Event Detail & Registration  |          | - Live QR Scanner (Camera)     |
    | - My Registrations Screen      |          | - Live Attendance Roster       |
    | - Attendance History Screen    |          | - Event Registrations List     |
    +--------------------------------+          +--------------------------------+
                    |                                            |
                    +--------------------+-----------------------+
                                         |
                                         v
    +--------------------------------+          +--------------------------------+
    |    ADMIN WORKSPACE (AppShell)  |          | MANAGEMENT WORKSPACE (AppShell)|
    | - Dashboard (Global Analytics) |          | - Executive Dashboard (RO)     |
    | - User Management (Status/PW)  |          | - College Participation Charts |
    | - Activity Logs (Audit Trail)  |          | - Read-Only Event Summaries    |
    | - Student QR Inspect & Reissue |          | - Institutional Reports Export |
    +--------------------------------+          +--------------------------------+
                                         |
                                         v  Shared Navigation Across All Roles
    +----------------------------------------------------------------------------+
    | - CalendarScreen (Interactive table_calendar with date event filtering)    |
    | - NotificationsScreen (Inbox list with unread markers & tap routing)       |
    | - ProfileScreen (Academic data, Appearance/Theme Selector, Logout)         |
    | - ReportsScreen (7 Multi-format exporters: CSV, XLSX, PDF)                 |
    +----------------------------------------------------------------------------+""")
