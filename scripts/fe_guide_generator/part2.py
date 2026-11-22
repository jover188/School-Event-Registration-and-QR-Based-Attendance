"""
part2.py - Chapters 6 to 8 for Attendify Frontend Developer Guide.
Covers:
- Chapter 6: Complete Screen Documentation (Catalog of all 21 actual screens)
- Chapter 7: UI Components and Reusable Widgets (AppButton, AppShell, EventCard, etc.)
- Chapter 8: UI/UX Design System (AetherUI, Tokens, Light & Dark Theme, Typography)
"""

from .styles import (
    add_chapter_title, add_section_title, add_subsection_title,
    add_body_p, add_bullet_item, add_callout, add_styled_table, add_code_block
)

def add_part2(doc):
    # -------------------------------------------------------------
    # CHAPTER 6: COMPLETE SCREEN DOCUMENTATION
    # -------------------------------------------------------------
    add_chapter_title(doc, "6", "Complete Screen Inventory & Technical Documentation")

    add_section_title(doc, "6.1", "Screen Inventory Architecture Overview")
    add_body_p(doc, "Attendify contains 21 production screens organized across feature namespaces (`auth/`, `student/`, `organizer/`, `admin/`, `management/`, and `common/`). Each screen is engineered as a responsive presentation unit adhering to AetherUI design tokens, standard loading/empty/error states, and role-based permissions.", bold_prefix="Architecture Overview: ")

    screens_data = [
        {
            "num": "6.2.1",
            "name": "LoginScreen",
            "path": "mobile/lib/screens/auth/login_screen.dart",
            "purpose": "Provide institutional authentication using either numeric Student ID or official school email with password.",
            "roles": "All Unauthenticated Users (Students, Organizers, Administrators, School Management).",
            "widgets": "AppPageScaffold, AccountInput, ShadInput (Password), AppButton, AppToast, Logo Mark Image.",
            "interactions": "Account string entry, password show/hide toggle, form submission, validation error dismiss.",
            "data": "Account identifier, password, remember session state.",
            "api": "POST /api/v1/auth/login",
            "state": "StatefulWidget with _isLoading, _errorMessage, _isPasswordVisible booleans.",
            "destinations": "Directs to appropriate dashboard (Student, Organizer, Admin, Management) upon HTTP 200.",
            "states": "Loading spinner on button during request; inline error banner on 401/422 credentials failure."
        },
        {
            "num": "6.2.2",
            "name": "StudentDashboardScreen",
            "path": "mobile/lib/screens/student/student_dashboard_screen.dart",
            "purpose": "Serve as the primary home hub for students, displaying attendance metrics, upcoming events, and quick permanent QR code access.",
            "roles": "Student (Role ID 3).",
            "widgets": "AppShell, StatMetricCard (Present, Late, Absences), EventCard list, FloatingActionButton / QR Banner, SectionHeader.",
            "interactions": "Pull-to-refresh, tapping event cards to open details, tapping QR action button to view permanent QR badge.",
            "data": "Student attendance counters, active event feed, personal registration status.",
            "api": "GET /api/v1/dashboard/student, GET /api/v1/events",
            "state": "StatefulWidget managing dashboard metrics, event lists, and refresh streams.",
            "destinations": "EventDetailScreen, PermanentQrScreen, MyRegistrationsScreen, CalendarScreen.",
            "states": "AppSpinner on initial load; EmptyStateView if no upcoming events; ErrorStateView on network drop."
        },
        {
            "num": "6.2.3",
            "name": "PermanentQrScreen",
            "path": "mobile/lib/screens/student/permanent_qr_screen.dart",
            "purpose": "Display the student's high-contrast, permanent 64-character cryptographic QR identity badge and allow on-demand token reissue.",
            "roles": "Student (Role ID 3).",
            "widgets": "AppPageScaffold, QrImageView (qr_flutter), StatusBadge, AppButton (Reissue), Confirmation Dialog, Privacy Shield Badge.",
            "interactions": "Brightness override, tap 'Reissue QR Code' to revoke previous tokens and generate a fresh token.",
            "data": "Permanent QR cryptographic token string (64 hex characters), token issuance date, student name, student ID number.",
            "api": "GET /api/v1/student/qr, POST /api/v1/student/qr/reissue",
            "state": "StatefulWidget tracking token load state and reissue confirmation dialogs.",
            "destinations": "Returns to StudentDashboardScreen or profile.",
            "states": "Centered AppSpinner during cryptographic retrieval; error message with retry button on failure."
        },
        {
            "num": "6.2.4",
            "name": "EventDetailScreen",
            "path": "mobile/lib/screens/student/event_detail_screen.dart",
            "purpose": "Present comprehensive event details, audience targeting tags, room capacity meters, registration actions, and waiting list position.",
            "roles": "All Roles (Student registers/cancels; Organizer/Admin views metadata).",
            "widgets": "AppPageScaffold, StatusBadge, LinearProgressIndicator (Capacity), AppButton (Register / Cancel / Join Waiting List).",
            "interactions": "Register for event, cancel active registration, join waiting list, refresh event capacity.",
            "data": "Event title, venue, start/end time, description, capacity, registered count, waiting list position, target colleges/years.",
            "api": "GET /api/v1/events/{id}, POST /api/v1/events/{id}/register, POST /api/v1/events/{id}/cancel-registration",
            "state": "StatefulWidget managing event payload, registration mutation states, and confirmation sheets.",
            "destinations": "MyRegistrationsScreen, LiveAttendanceScreen (for staff).",
            "states": "Skeleton loader during fetch; capacity warning banner when event reaches 100% capacity."
        },
        {
            "num": "6.2.5",
            "name": "MyRegistrationsScreen",
            "path": "mobile/lib/screens/student/my_registrations_screen.dart",
            "purpose": "Display all events for which the student has registered, distinguishing confirmed seats from waiting list positions.",
            "roles": "Student (Role ID 3).",
            "widgets": "AppShell, TabBar (Upcoming vs Past), EventCard, StatusBadge (Registered vs Waiting List), Cancellation Action Sheet.",
            "interactions": "Filter by registration status, tap event to view details, cancel registration to free seat for peers.",
            "data": "List of registration records, event timestamps, venues, queue position numbers.",
            "api": "GET /api/v1/student/registrations, POST /api/v1/events/{id}/cancel-registration",
            "state": "StatefulWidget maintaining registration collections and tab state.",
            "destinations": "EventDetailScreen.",
            "states": "AppSpinner on load; EmptyStateView ('You have not registered for any events yet'); ErrorStateView on failure."
        },
        {
            "num": "6.2.6",
            "name": "MyAttendanceHistoryScreen",
            "path": "mobile/lib/screens/student/my_attendance_history_screen.dart",
            "purpose": "Provide students with a verified ledger of their institutional event attendance for co-curricular clearance and transcript audits.",
            "roles": "Student (Role ID 3).",
            "widgets": "AppShell, StatusBadge (Present, Late, Excused, Walk-In), Date Grouping Headers, Metric Summary Ribbon.",
            "interactions": "Filter by semester, search event title, tap attendance card to view check-in timestamp and verification details.",
            "data": "Attendance records, check-in/out timestamps, arrival status (present, late, excused), event title, organizer department.",
            "api": "GET /api/v1/student/attendance-history",
            "state": "StatefulWidget managing historical event records and semester filters.",
            "destinations": "EventDetailScreen.",
            "states": "AppSpinner on load; EmptyStateView ('No attendance records found'); ErrorStateView on network error."
        },
        {
            "num": "6.2.7",
            "name": "OrganizerDashboardScreen",
            "path": "mobile/lib/screens/organizer/organizer_dashboard_screen.dart",
            "purpose": "Serve as the event management hub for staff, displaying active events, check-in quick actions, and attendance statistics.",
            "roles": "Organizer (Role ID 2), Administrator (Role ID 1).",
            "widgets": "AppShell, StatMetricCard (Total Events, Live Attendance, Pending Approvals), EventCard list with action buttons.",
            "interactions": "Tap 'Create Event', tap 'Scan Attendance', tap event card to manage registrations or review live roster.",
            "data": "Event status counts, managed events list, venue occupancy metrics.",
            "api": "GET /api/v1/dashboard/organizer, GET /api/v1/events",
            "state": "StatefulWidget tracking event lists, metrics, and filter chips.",
            "destinations": "EventFormScreen, QrScannerScreen, LiveAttendanceScreen, EventRegistrationsScreen, ReportsScreen.",
            "states": "Shimmer loading indicators; EmptyStateView if no events managed; ErrorStateView on failure."
        },
        {
            "num": "6.2.8",
            "name": "EventFormScreen",
            "path": "mobile/lib/screens/organizer/event_form_screen.dart",
            "purpose": "Enable organizers to create new campus events or edit draft events, configuring venue, capacity, grace periods, and targeting.",
            "roles": "Organizer (Role ID 2), Administrator (Role ID 1).",
            "widgets": "AppPageScaffold, ShadInput (Title, Venue, Capacity), DateTimePicker, DropdownSelect (Audience), AppButton (Save / Submit).",
            "interactions": "Form input entry, date/time pickers, multi-select targeting criteria, submit for administrative approval.",
            "data": "Event title, description, venue, event date, start/end time, late grace minutes, capacity, target departments, target year levels.",
            "api": "GET /api/v1/events/audience-options, POST /api/v1/events, PUT /api/v1/events/{id}, POST /api/v1/events/{id}/submit-approval",
            "state": "StatefulWidget managing form controllers, audience options, and submission states.",
            "destinations": "Returns to OrganizerDashboardScreen or EventDetailScreen.",
            "states": "Inline validation errors on empty fields; loading spinner on submit button; success toast on save."
        },
        {
            "num": "6.2.9",
            "name": "QrScannerScreen",
            "path": "mobile/lib/screens/organizer/qr_scanner_screen.dart",
            "purpose": "Drive the device hardware camera to scan student permanent QR badges, evaluate late grace periods, and record sub-second attendance.",
            "roles": "Organizer (Role ID 2), Administrator (Role ID 1).",
            "widgets": "MobileScanner view, ScannerOverlay, Torch Toggle Button, Switch Camera Button, ScanResultContent modal sheet.",
            "interactions": "Continuous barcode scanning, toggle flashlight, switch between front/back camera, manual Student ID entry dialog.",
            "data": "Event ID, scan mode (Check-In vs Check-Out), QR token string, scanned student details, arrival status.",
            "api": "POST /api/v1/events/{id}/attendance/scan",
            "state": "StatefulWidget tracking scanner controller lifecycle, debounce locks, and active modal sheets.",
            "destinations": "Pops modal sheet upon successful scan, returns to LiveAttendanceScreen.",
            "states": "Camera permission request screen; visual scanning viewfinder; haptic feedback and audible chime on successful scan."
        },
        {
            "num": "6.2.10",
            "name": "LiveAttendanceScreen",
            "path": "mobile/lib/screens/organizer/live_attendance_screen.dart",
            "purpose": "Display real-time venue check-in stream, attendee counts, late arrivals, and allow manual attendance corrections with mandatory reasons.",
            "roles": "Organizer (Role ID 2), Administrator (Role ID 1).",
            "widgets": "AppShell, StatMetricCard (Present, Late, Walk-In, Unregistered), Attendee DataTable / ListView, StatusBadge, Correction Dialog.",
            "interactions": "Search attendee by name/ID, filter by status, tap student to initiate manual attendance correction with reason text.",
            "data": "Event title, total attendees, check-in timestamps, arrival statuses, correction audit logs.",
            "api": "GET /api/v1/events/{id}/attendance, PUT /api/v1/attendance/{id}/correct",
            "state": "StatefulWidget managing attendee collections, search query filter, and periodic refresh.",
            "destinations": "QrScannerScreen, EventRegistrationsScreen, ReportsScreen.",
            "states": "AppSpinner on initial load; EmptyStateView if 0 attendees checked in; ErrorStateView on network drop."
        },
        {
            "num": "6.2.11",
            "name": "EventRegistrationsScreen",
            "path": "mobile/lib/screens/organizer/event_registrations_screen.dart",
            "purpose": "Review the complete list of registered students and waiting list queue positions for a specific event.",
            "roles": "Organizer (Role ID 2), Administrator (Role ID 1).",
            "widgets": "AppShell, TabBar (Registered vs Waiting List), DataTable / Card list, Search Input, Manual Cancellation Action.",
            "interactions": "Search student name or ID, view queue positions, cancel student registration on behalf of organizer.",
            "data": "Student name, email, student ID number, registration timestamp, waiting list position number.",
            "api": "GET /api/v1/events/{id}/registrations, DELETE /api/v1/events/{id}/registrations/{regId}",
            "state": "StatefulWidget managing tab index, registration collections, and cancellation dialogs.",
            "destinations": "Returns to OrganizerDashboardScreen.",
            "states": "AppSpinner on load; EmptyStateView if no registrants; confirmation dialog on cancellation."
        },
        {
            "num": "6.2.12",
            "name": "AdminDashboardScreen",
            "path": "mobile/lib/screens/admin/admin_dashboard_screen.dart",
            "purpose": "Provide central administrators with campus-wide analytics, pending event approvals, and quick navigation to governance tools.",
            "roles": "Administrator (Role ID 1).",
            "widgets": "AppShell, StatMetricCard (Total Users, Active Events, Pending Approvals, Total Check-Ins), Pending Approval Review Cards.",
            "interactions": "Review pending event proposal, approve or reject event, view user management, view audit logs.",
            "data": "Global system counts, pending event approval queue, recent system activity log summaries.",
            "api": "GET /api/v1/dashboard/admin, POST /api/v1/admin/events/{id}/review",
            "state": "StatefulWidget managing global metrics, approval queues, and review dialogs.",
            "destinations": "UserManagementScreen, ActivityLogsScreen, StudentQrInspectScreen, ReportsScreen, EventDetailScreen.",
            "states": "AppSpinner on load; EmptyStateView if no pending approvals; ErrorStateView on failure."
        },
        {
            "num": "6.2.13",
            "name": "UserManagementScreen",
            "path": "mobile/lib/screens/admin/user_management_screen.dart",
            "purpose": "Allow administrators to search campus users, toggle account active/suspended status, and trigger administrative password resets.",
            "roles": "Administrator (Role ID 1).",
            "widgets": "AppShell, SearchBar, Role Filter Chips, User DataTable / ListCards, StatusBadge (Active / Suspended), Action Menus.",
            "interactions": "Search by email or Student ID, filter by role, toggle user status, reset password with temporary credential dialog.",
            "data": "User ID, full name, email, student ID number, role, account status, created date.",
            "api": "GET /api/v1/admin/users, PUT /api/v1/admin/users/{id}/status, POST /api/v1/admin/users/{id}/reset-password",
            "state": "StatefulWidget managing user collections, search debounce, and action sheets.",
            "destinations": "StudentQrInspectScreen.",
            "states": "Shimmer rows on search; confirmation dialogs on status toggle; success toast on password reset."
        },
        {
            "num": "6.2.14",
            "name": "ActivityLogsScreen",
            "path": "mobile/lib/screens/admin/activity_logs_screen.dart",
            "purpose": "Display the immutable forensic audit trail of all state mutations, administrative reviews, and attendance corrections.",
            "roles": "Administrator (Role ID 1).",
            "widgets": "AppShell, FilterDropdown (Action, Module), LogEntryCard, JSON Diff Viewer Dialog, Pagination Controls.",
            "interactions": "Filter by module (auth, events, attendance, users), tap log card to inspect before/after JSON diffs.",
            "data": "Log ID, actor name, role, IP address, user agent, action string, module name, before/after JSON snapshots, timestamp.",
            "api": "GET /api/v1/admin/logs",
            "state": "StatefulWidget managing log stream, page index, and filter selections.",
            "destinations": "Returns to AdminDashboardScreen.",
            "states": "AppSpinner on load; EmptyStateView if no logs match filter; modal viewer for detailed metadata."
        },
        {
            "num": "6.2.15",
            "name": "StudentQrInspectScreen",
            "path": "mobile/lib/screens/admin/student_qr_inspect_screen.dart",
            "purpose": "Allow administrators to inspect any enrolled student's active QR token, view issuance history, and manually reissue tokens.",
            "roles": "Administrator (Role ID 1).",
            "widgets": "AppPageScaffold, SearchBar, QrImageView (qr_flutter), StatusBadge, AppButton (Force Reissue), History List.",
            "interactions": "Search student, inspect active token, trigger atomic token revocation and reissue inside a database transaction.",
            "data": "Student academic info, active QR token string, issuance date, previous revoked tokens list.",
            "api": "GET /api/v1/admin/students/{id}/qr, POST /api/v1/admin/students/{id}/qr/reissue",
            "state": "StatefulWidget tracking student search query, selected student QR data, and mutation state.",
            "destinations": "UserManagementScreen.",
            "states": "AppSpinner on load; EmptyStateView if student not found; confirmation dialog on reissue."
        },
        {
            "num": "6.2.16",
            "name": "ManagementDashboardScreen",
            "path": "mobile/lib/screens/management/management_dashboard_screen.dart",
            "purpose": "Provide institutional deans and executives with strictly read-only participation analytics, trends, and compliance summaries.",
            "roles": "School Management (Role ID 4), Administrator (Role ID 1).",
            "widgets": "AppShell, StatMetricCard (Campus Attendance Rate, Active Events, College Participation), Analytics Charts, Summary Tables.",
            "interactions": "Filter by academic term, select college department, tap report summary to open export tools.",
            "data": "Aggregate campus attendance percentages, college participation breakdown, monthly event frequency.",
            "api": "GET /api/v1/dashboard/management, GET /api/v1/reports/participation-summary",
            "state": "StatefulWidget managing executive analytics payloads and semester filter state.",
            "destinations": "ReportsScreen, CalendarScreen.",
            "states": "Skeleton loaders for analytics charts; EmptyStateView if no events held during term."
        },
        {
            "num": "6.2.17",
            "name": "CalendarScreen",
            "path": "mobile/lib/screens/common/calendar_screen.dart",
            "purpose": "Provide interactive monthly and weekly calendar scheduling with event dot markers and day-specific event lists.",
            "roles": "All Roles (Student, Organizer, Admin, Management).",
            "widgets": "AppShell, TableCalendar, StatusBadge, EventCard list, Month/Week Format Toggle, Date Filter Chips.",
            "interactions": "Tap calendar date to filter events, swipe between months, toggle month/week view, tap event card to view details.",
            "data": "Calendar event markers, event start/end times, venues, titles, registration eligibility.",
            "api": "GET /api/v1/events (with month/year query parameters)",
            "state": "StatefulWidget managing selectedDay, focusedDay, calendarFormat, and daily event collections.",
            "destinations": "EventDetailScreen, EventFormScreen (for organizers).",
            "states": "Event dot indicators on calendar days; EmptyStateView ('No events scheduled for this day')."
        },
        {
            "num": "6.2.18",
            "name": "NotificationsScreen",
            "path": "mobile/lib/screens/common/notifications_screen.dart",
            "purpose": "Provide an in-app notification inbox displaying real-time alerts, event reminders, cancellations, and broadcast notices.",
            "roles": "All Roles (Student, Organizer, Admin, Management).",
            "widgets": "AppShell, NotificationTile list, Unread Indicator Dot, AppButton (Mark All as Read), Filter Chips (All vs Unread).",
            "interactions": "Tap notification to mark as read and navigate to event details, swipe to dismiss, tap 'Mark All as Read'.",
            "data": "Notification ID, title, message body, notification type, read status, creation timestamp, attached event ID.",
            "api": "GET /api/v1/notifications, PUT /api/v1/notifications/{id}/read, POST /api/v1/notifications/mark-all-read",
            "state": "StatefulWidget connected to RealtimeNotificationService stream and unreadCount notifier.",
            "destinations": "EventDetailScreen, NotificationPreferencesScreen.",
            "states": "AppSpinner on load; EmptyStateView ('Your inbox is empty'); immediate visual update when notifications arrive."
        },
        {
            "num": "6.2.19",
            "name": "NotificationPreferencesScreen",
            "path": "mobile/lib/screens/common/notification_preferences_screen.dart",
            "purpose": "Allow users to customize notification preferences across event updates, reminders, and marketing announcements.",
            "roles": "All Roles (Student, Organizer, Admin, Management).",
            "widgets": "AppPageScaffold, SwitchListTile (Event Updates, Reminders, Announcements), Locked Switch (Critical Alerts), AppButton.",
            "interactions": "Toggle notification categories, save preferences. Critical alerts (cancellations) are permanently locked on.",
            "data": "User notification preferences JSON object.",
            "api": "GET /api/v1/notifications/preferences, PUT /api/v1/notifications/preferences",
            "state": "StatefulWidget managing toggle boolean states and save status.",
            "destinations": "Returns to NotificationsScreen or ProfileScreen.",
            "states": "Loading spinner on initial load; disabled switch with lock icon on critical cancellation alerts."
        },
        {
            "num": "6.2.20",
            "name": "ProfileScreen",
            "path": "mobile/lib/screens/common/profile_screen.dart",
            "purpose": "Display user academic information, Appearance/Theme Selector (Light, Dark, System Default), password change, and logout.",
            "roles": "All Roles (Student, Organizer, Admin, Management).",
            "widgets": "AppPageScaffold, UserAvatar, Academic Attributes Card, Appearance & Theme Card (3 Options), Password Form, Logout Button.",
            "interactions": "Select Light / Dark / System Default theme, update password, initiate session logout.",
            "data": "Full name, email, student ID number, college/course, year level, account status, active theme mode.",
            "api": "GET /api/v1/profile, PUT /api/v1/profile/change-password, POST /api/v1/auth/logout",
            "state": "StatefulWidget observing AppThemeController and managing profile data fetch.",
            "destinations": "NotificationPreferencesScreen, LoginScreen (upon logout).",
            "states": "AppSpinner on load; immediate UI re-render upon theme mode selection; success toast on password change."
        },
        {
            "num": "6.2.21",
            "name": "ReportsScreen",
            "path": "mobile/lib/screens/common/reports_screen.dart",
            "purpose": "Generate and export 7 institutional report types in CSV, Microsoft Excel (XLSX), and Adobe PDF formats.",
            "roles": "Organizer (own events), Administrator (all events), School Management (read-only export).",
            "widgets": "AppShell, ReportTypeSelector, DateRangePicker, EventDropdown, FormatSelector (CSV, XLSX, PDF), AppButton (Download).",
            "interactions": "Select report type, choose date range or specific event, select export format, tap 'Download Report'.",
            "data": "Report metadata, generated binary download streams, filter criteria.",
            "api": "GET /api/v1/reports/*, POST /api/v1/reports/export",
            "state": "StatefulWidget managing report parameters, file downloader utility, and download progress.",
            "destinations": "OrganizerDashboardScreen, AdminDashboardScreen, ManagementDashboardScreen.",
            "states": "LinearProgressIndicator during file compilation; platform-specific download handler (browser blob on web, storage on Android)."
        }
    ]

    for sc in screens_data:
        add_subsection_title(doc, sc["num"], f"{sc['name']} (`{sc['path']}`)")
        add_body_p(doc, sc["purpose"], bold_prefix="Purpose & Function: ")
        add_body_p(doc, sc["roles"], bold_prefix="Accessible User Roles: ")
        add_body_p(doc, sc["widgets"], bold_prefix="Core UI Components: ")
        add_body_p(doc, sc["interactions"], bold_prefix="User Interactions: ")
        add_body_p(doc, sc["data"], bold_prefix="Data Displayed: ")
        add_body_p(doc, sc["api"], bold_prefix="REST API Endpoints: ")
        add_body_p(doc, sc["state"], bold_prefix="State Management Model: ")
        add_body_p(doc, sc["destinations"], bold_prefix="Navigation Destinations: ")
        add_body_p(doc, sc["states"], bold_prefix="Loading / Empty / Error States: ")

    # -------------------------------------------------------------
    # CHAPTER 7: UI COMPONENTS AND REUSABLE WIDGETS
    # -------------------------------------------------------------
    add_chapter_title(doc, "7", "UI Components & Reusable Widgets Library")

    add_section_title(doc, "7.1", "Core Widget Catalog")
    add_body_p(doc, "Attendify eliminates UI duplication by maintaining a centralized library of reusable widgets in `mobile/lib/core/widgets/`. Every component is styled against `AppDesignTokens` and adapts automatically to Light Mode and Dark Mode:", bold_prefix="Design Standards: ")

    widgets_data = [
        ["AppPageScaffold", "core/widgets/app_page_scaffold.dart", "Top-level page scaffold providing consistent app bar, title, theme toggle, and SafeArea wrapping."],
        ["AppShell", "core/widgets/app_shell.dart", "Responsive shell switching between bottom nav (<600px), nav rail (600-1024px), and sidebar (>1024px)."],
        ["AppButton", "core/widgets/app_button.dart", "Primary, secondary, outline, and destructive action buttons with built-in loading spinners."],
        ["AppPressable", "core/widgets/app_pressable.dart", "House pressable widget replacing standard ink ripples with subtle opacity and scale animation."],
        ["AppSpinner", "core/widgets/app_spinner.dart", "Theme-aware circular loading indicator adhering to AetherUI monochrome colors."],
        ["AppToast", "core/widgets/app_toast.dart", "Lightweight toast notification utility providing success, error, and informational banners."],
        ["EventCard", "core/widgets/event_card.dart", "Standardized card displaying event title, date, venue, capacity progress bar, and status badge."],
        ["StatMetricCard", "core/widgets/stat_metric_card.dart", "Executive metric card displaying numeric values, trend indicators, and semantic status icons."],
        ["StatusBadge", "core/widgets/status_badge.dart", "Semantic colored badge for statuses: Present, Late, Excused, Walk-In, Registered, Waiting List."],
        ["SectionHeader", "core/widgets/section_header.dart", "Structured section title with optional subtitle and right-aligned action link."],
        ["EmptyStateView", "core/widgets/empty_state_view.dart", "Consistent empty placeholder with vector icon, descriptive title, and optional action button."],
        ["ErrorStateView", "core/widgets/error_state_view.dart", "Standardized network and system error view with failure message and retry button."],
        ["ThemeToggleIconButton", "core/widgets/theme_toggle_button.dart", "Action bar icon button displaying sun/moon icon and toggling between Light and Dark mode."],
        ["ScanResultContent", "screens/organizer/widgets/scan_result_content.dart", "Modal bottom sheet rendering scanned student details, arrival status, and audio chime trigger."]
    ]
    add_styled_table(doc, ["Widget Name", "Source Path", "Functional Purpose & Visual Role"], widgets_data, col_widths=[1.5, 2.0, 3.0])

    add_section_title(doc, "7.2", "Reusable Component Code Usage Examples")
    add_body_p(doc, "The following code snippets illustrate standard component instantiation in Attendify:")

    add_body_p(doc, "Example 1: Instantiating a Primary AppButton with Loading State:", bold_prefix="AppButton Usage: ")
    add_code_block(doc,
"""AppButton(
  label: 'Register for Event',
  isLoading: _isSubmitting,
  onPressed: _isSubmitting ? null : _handleRegistration,
  variant: AppButtonVariant.primary,
)""")

    add_body_p(doc, "Example 2: Rendering a Semantic StatusBadge for Attendance Records:", bold_prefix="StatusBadge Usage: ")
    add_code_block(doc,
"""StatusBadge(
  status: attendance.status, // 'present', 'late', 'excused', 'walk_in'
  size: StatusBadgeSize.medium,
)""")

    # -------------------------------------------------------------
    # CHAPTER 8: UI/UX DESIGN SYSTEM
    # -------------------------------------------------------------
    add_chapter_title(doc, "8", "AetherUI Design System & Dual-Theme Architecture")

    add_section_title(doc, "8.1", "Visual Identity & Palette Discipline")
    add_body_p(doc, "Attendify adheres to the bespoke **AetherUI** design language—an executive, black-and-white minimalist visual identity characterized by high-contrast typography, subtle neutral surfaces, crisp borders, and zero garish gradient saturation. Semantic status colors (success green, warning amber, destructive red) are used strictly for data attribution and badges.", bold_prefix="Design Identity: ")

    add_section_title(doc, "8.2", "Light Mode vs. Dark Mode Token Matrix")
    add_body_p(doc, "Theme tokens are defined in `mobile/lib/core/theme/app_tokens.dart` and accessed via `context.design`. The table below outlines the color tokens across Light and Dark themes:")

    palette_headers = ["Token Property", "Light Mode (`:root`)", "Dark Mode (`.dark`)", "Visual Purpose"]
    palette_rows = [
        ["background", "#FAFAFA (Near White)", "#09090B (Zinc Black)", "Primary screen canvas background"],
        ["foreground", "#09090B (Deep Charcoal)", "#FFFFFF (Pure White)", "Primary body typography and headings"],
        ["card", "#FFFFFF (Pure White)", "#121214 (Charcoal Card)", "Card surfaces, dialogs, and popovers"],
        ["cardForeground", "#09090B (Deep Charcoal)", "#FFFFFF (Pure White)", "Typography inside cards and containers"],
        ["primary", "#18181B (Zinc 900)", "#FFFFFF (Pure White)", "Primary action buttons, brand accents"],
        ["primaryForeground", "#FAFAFA (Near White)", "#27272A (Zinc 800)", "Text inside primary action buttons"],
        ["secondary", "#F4F4F5 (Zinc 100)", "#27272A (Zinc 800)", "Secondary button fills, pill filters"],
        ["muted", "#F4F4F5 (Zinc 100)", "#27272A (Zinc 800)", "Muted card backgrounds and input fills"],
        ["mutedForeground", "#52525B (Zinc 600)", "#A1A1AA (Zinc 400)", "Subtitles, timestamps, placeholder text"],
        ["border", "#E4E4E7 (Zinc 200)", "#27272A (Zinc 800)", "Hairline borders on cards, inputs, dividers"],
        ["sidebar", "#F4F4F5 (Zinc 100)", "#09090B (Zinc Black)", "Persistent navigation drawer / sidebar fill"],
        ["sidebarBorder", "#E4E4E7 (Zinc 200)", "#27272A (Zinc 800)", "Vertical boundary separating sidebar from body"]
    ]
    add_styled_table(doc, palette_headers, palette_rows, col_widths=[1.5, 1.6, 1.6, 1.8])

    add_section_title(doc, "8.3", "Typography Scale & Spacing Standards")
    add_body_p(doc, "Typography utilizes the clean, geometric 'Inter' font family with strict hierarchy:")
    add_bullet_item(doc, "28pt Bold / Semi-Bold. Used for major screen titles on mobile and desktop headers.", bold_prefix="Display / H1: ")
    add_bullet_item(doc, "20pt Semi-Bold. Used for modal headers and major dashboard section titles.", bold_prefix="H2: ")
    add_bullet_item(doc, "16pt Semi-Bold. Used for card titles, event titles, and dialog headers.", bold_prefix="Card Title: ")
    add_bullet_item(doc, "14pt Regular (1.4 line-height). Used for primary body copy and form inputs.", bold_prefix="Body: ")
    add_bullet_item(doc, "12pt Regular / Medium. Used for metadata, venue labels, timestamps, and status badges.", bold_prefix="Caption / Badge: ")
    add_bullet_item(doc, "Grid based on 4px units: xs (4px), sm (8px), md (16px), lg (24px), xl (32px), xxl (48px).", bold_prefix="Spacing Scale: ")
    add_bullet_item(doc, "radiusSm (4px), radiusMd (8px), radiusLg (12px), radiusFull (9999px).", bold_prefix="Border Radii: ")
