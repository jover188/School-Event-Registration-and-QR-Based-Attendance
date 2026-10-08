import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/management/management_dashboard_screen.dart';
import 'screens/organizer/organizer_dashboard_screen.dart';
import 'screens/student/student_dashboard_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SchoolAttendanceApp());
}

class SchoolAttendanceApp extends StatefulWidget {
  const SchoolAttendanceApp({super.key});

  @override
  State<SchoolAttendanceApp> createState() => _SchoolAttendanceAppState();
}

class _SchoolAttendanceAppState extends State<SchoolAttendanceApp> {
  @override
  void initState() {
    super.initState();

    // Global listener for single-session termination
    ApiClient().onSessionTerminated = () {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Session Terminated'),
            content: const Text(
              'Your session has been terminated because your account was logged into on another device. Please log in again if you wish to use this device.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Return to Login'),
              ),
            ],
          ),
        );
      }
    };
  }

  Future<Widget> _resolveInitialScreen() async {
    final token = await ApiClient().getToken();
    final role = await ApiClient().getUserRole();

    if (token == null || role == null) {
      return const LoginScreen();
    }

    switch (role) {
      case 'student':
        return const StudentDashboardScreen();
      case 'organizer':
        return const OrganizerDashboardScreen();
      case 'management':
        return const ManagementDashboardScreen();
      case 'administrator':
        return const AdminDashboardScreen();
      default:
        return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Event Attendance',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      home: FutureBuilder<Widget>(
        future: _resolveInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            );
          }
          return snapshot.data ?? const LoginScreen();
        },
      ),
    );
  }
}
