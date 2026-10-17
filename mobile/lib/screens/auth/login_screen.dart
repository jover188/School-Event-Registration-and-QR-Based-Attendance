import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../management/management_dashboard_screen.dart';
import '../organizer/organizer_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onForgotPassword;

  const LoginScreen({
    super.key,
    this.onForgotPassword,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _loginFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _loginFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      if (_loginController.text.trim().isEmpty) {
        _loginFocus.requestFocus();
      } else {
        _passwordFocus.requestFocus();
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiClient().post(ApiConstants.login, {
      'login': _loginController.text.trim(),
      'password': _passwordController.text,
    });

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.success && response.data != null) {
      TextInput.finishAutofillContext(shouldSave: true);

      final token = response.data['token']?.toString() ?? '';
      final role = response.data['user']?['role']?.toString() ?? 'student';

      await ApiClient().saveToken(token, role);

      if (!mounted) return;

      final Widget targetScreen = switch (role) {
        'student' => const StudentDashboardScreen(),
        'organizer' => const OrganizerDashboardScreen(),
        'management' => const ManagementDashboardScreen(),
        'administrator' => const AdminDashboardScreen(),
        _ => const StudentDashboardScreen(),
      };

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      );
    } else {
      setState(() {
        _errorMessage =
            response.message ?? 'Login failed. Please check your credentials.';
      });
    }
  }

  void _handleForgotPasswordTap() {
    if (widget.onForgotPassword != null) {
      widget.onForgotPassword!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: FocusTraversalGroup(
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidateMode,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 72,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'School Event Attendance',
                        textAlign: TextAlign.center,
                        style: AppTypography.headline,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'QR-Based Attendance & Event System',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMuted,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_errorMessage != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm + 4),
                            decoration: BoxDecoration(
                              color: AppColors.absent.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.absent),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodyMuted.copyWith(
                                color: AppColors.absent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      TextFormField(
                        key: const ValueKey<String>('login-identifier-field'),
                        controller: _loginController,
                        focusNode: _loginFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        decoration: const InputDecoration(
                          labelText: 'Student ID or School Email',
                          hintText: 'e.g. 20260001 or student@school.edu',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your student ID or email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        key: const ValueKey<String>('login-password-field'),
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              _isLoading ? null : _handleForgotPasswordTap,
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ElevatedButton(
                        key: const ValueKey<String>('login-submit-button'),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Log In'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have a student account? ",
                            style: AppTypography.bodyMuted,
                          ),
                          Semantics(
                            button: true,
                            label: 'Register Here',
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: AppSpacing.xs,
                                ),
                                child: Text(
                                  'Register Here',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
