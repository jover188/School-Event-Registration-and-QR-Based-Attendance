import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pressable.dart';
import 'account_input.dart';
import '../admin/admin_dashboard_screen.dart';
import '../management/management_dashboard_screen.dart';
import '../organizer/organizer_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
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
    if (_isLoading) return;
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

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final overlayStyle =
        ThemeData.estimateBrightnessForColor(d.authPage) == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;
    final fieldDecoration = ShadDecoration(
      color: d.authLight,
      border: ShadBorder.all(
        color: d.authDark.withValues(alpha: 0.08),
        width: 1,
        radius: BorderRadius.circular(d.authFieldRadius),
      ),
      focusedBorder: ShadBorder.all(
        color: d.authDark,
        width: 1.5,
        radius: BorderRadius.circular(d.authFieldRadius),
      ),
      errorBorder: ShadBorder.all(
        color: d.destructive,
        width: 1.5,
        radius: BorderRadius.circular(d.authFieldRadius),
      ),
      errorPadding: EdgeInsets.only(
        left: d.md + (d.xs / 2),
        top: d.xs + 2,
      ),
      errorStyle: d.supporting.copyWith(
        color: d.destructive,
        fontWeight: FontWeight.w600,
      ),
      shadows: [
        BoxShadow(
          color: d.authDark.withValues(alpha: 0.05),
          offset: const Offset(0, 2),
          blurRadius: 10,
        ),
      ],
      disableSecondaryBorder: true,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: d.authPage,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final leftInset = math.max(d.md, viewPadding.left);
            final rightInset = math.max(d.md, viewPadding.right);
            final topInset = d.md + viewPadding.top;
            final bottomInset = d.md + viewPadding.bottom;
            final surfaceWidth = math.max(
              0.0,
              math.min(
                d.authSurfaceMaxWidth,
                constraints.maxWidth - leftInset - rightInset,
              ),
            );
            final isNarrowCard = surfaceWidth <= 400;
            final isVeryNarrowCard = surfaceWidth < 320;
            final headerHeight = surfaceWidth * d.authHeaderAspectRatio;
            final availableHeight = math.max(
              0.0,
              constraints.maxHeight - topInset - bottomInset,
            );
            final surfaceRadius = BorderRadius.circular(d.authSurfaceRadius);

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                leftInset,
                topInset,
                rightInset,
                bottomInset,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: availableHeight,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: d.authSurfaceMaxWidth),
                    child: FocusTraversalGroup(
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _autovalidateMode,
                          child: Container(
                            key: const ValueKey<String>('login-surface'),
                            width: surfaceWidth,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: d.authSurface,
                              borderRadius: surfaceRadius,
                              boxShadow: [
                                BoxShadow(
                                  color: d.authDark.withValues(alpha: 0.18),
                                  offset: const Offset(0, 24),
                                  blurRadius: 60,
                                ),
                              ],
                            ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                key: const ValueKey<String>('login-header'),
                                height: headerHeight,
                                child: CustomPaint(
                                  painter: AttendifyHeaderPainter(
                                    color: d.authDark,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      isNarrowCard ? d.lg : d.xl,
                                      isVeryNarrowCard
                                          ? d.md
                                          : isNarrowCard
                                              ? d.lg + d.xs
                                              : d.xl + d.xs,
                                      isNarrowCard ? d.lg : d.xl,
                                      0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/images/logo_icon.svg',
                                          key: const ValueKey<String>(
                                            'attendify-login-logo',
                                          ),
                                          width: d.authLogoSize,
                                          height: d.authLogoSize,
                                          fit: BoxFit.contain,
                                          alignment: Alignment.centerLeft,
                                          colorFilter: ColorFilter.mode(
                                            d.authLight,
                                            BlendMode.srcIn,
                                          ),
                                          placeholderBuilder: (_) =>
                                              Image.asset(
                                            'assets/images/logo_mark.png',
                                            width: d.authLogoSize,
                                            height: d.authLogoSize,
                                            color: d.authLight,
                                          ),
                                          semanticsLabel: 'Attendify',
                                        ),
                                        SizedBox(height: d.sm),
                                        Text(
                                          'Attendify',
                                          key: const ValueKey<String>(
                                            'attendify-brand-name',
                                          ),
                                          style: d.authBrand.copyWith(
                                            color: d.authLight,
                                          ),
                                        ),
                                        SizedBox(height: d.xs),
                                        Text(
                                          'Welcome back! Log in to continue.',
                                          style: d.body.copyWith(
                                            color: d.authLight
                                                .withValues(alpha: 0.62),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  isNarrowCard ? d.lg : d.xl,
                                  d.sm,
                                  isNarrowCard ? d.lg : d.xl,
                                  d.xl + d.sm,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Login',
                                      key: const ValueKey<String>(
                                        'login-title',
                                      ),
                                      style: d.authTitle.copyWith(
                                        color: d.authDark,
                                        fontSize: isNarrowCard ? 30 : 34,
                                      ),
                                    ),
                                    SizedBox(height: d.lg - (d.xs / 2)),
                                    if (_errorMessage != null) ...[
                                      Semantics(
                                        liveRegion: true,
                                        child: Container(
                                          padding: EdgeInsets.all(d.gap),
                                          decoration: BoxDecoration(
                                            color: d.dangerBackground,
                                            borderRadius: BorderRadius.circular(
                                              d.radiusControl,
                                            ),
                                            border: Border.all(
                                              color: d.destructive,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                LucideIcons.alertCircle,
                                                size: 18,
                                                color: d.destructive,
                                              ),
                                              SizedBox(width: d.sm),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage!,
                                                  style: d.supporting.copyWith(
                                                    color: d.destructive,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: d.md),
                                    ],
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: d.md + (d.xs / 2),
                                      ),
                                      child: Text(
                                        'ID or email',
                                        style: d.body.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: d.authDark,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: d.sm),
                                    AccountInput(
                                      key: const ValueKey<String>(
                                        'login-identifier-field',
                                      ),
                                      controller: _loginController,
                                      focusNode: _loginFocus,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.username,
                                      ],
                                      showLeadingDivider: false,
                                      fieldDecoration: fieldDecoration,
                                      fieldPadding: EdgeInsets.symmetric(
                                        horizontal: d.md + (d.xs / 2),
                                        vertical: (d.authFieldHeight - 26) / 2,
                                      ),
                                      textStyle: d.authInputText.copyWith(
                                        color: d.authDark,
                                      ),
                                      cursorColor: d.authDark,
                                      selectionColor: d.authDarkSelection,
                                      placeholderStyle:
                                          d.authInputText.copyWith(
                                        color:
                                            d.authDark.withValues(alpha: 0.48),
                                      ),
                                      constraints: BoxConstraints(
                                        minHeight: d.authFieldHeight,
                                      ),
                                      onFieldSubmitted: (_) =>
                                          _passwordFocus.requestFocus(),
                                      decoration: const InputDecoration(
                                        hintText: 'you@school.edu.ph',
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Please enter your student ID or email';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(
                                      height: d.md + (d.xs / 2),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: d.md + (d.xs / 2),
                                      ),
                                      child: Text(
                                        'Password',
                                        style: d.body.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: d.authDark,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: d.sm),
                                    Stack(
                                      children: [
                                        AccountInput(
                                          key: const ValueKey<String>(
                                            'login-password-field',
                                          ),
                                          controller: _passwordController,
                                          focusNode: _passwordFocus,
                                          obscureText: _obscurePassword,
                                          keyboardType:
                                              TextInputType.visiblePassword,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          showLeadingDivider: false,
                                          fieldDecoration: fieldDecoration,
                                          fieldPadding: EdgeInsets.only(
                                            left: d.md + (d.xs / 2),
                                            right: d.minimumTarget + d.sm,
                                            top: (d.authFieldHeight - 26) / 2,
                                            bottom:
                                                (d.authFieldHeight - 26) / 2,
                                          ),
                                          textStyle: d.authInputText.copyWith(
                                            color: d.authDark,
                                          ),
                                          cursorColor: d.authDark,
                                          selectionColor: d.authDarkSelection,
                                          placeholderStyle:
                                              d.authInputText.copyWith(
                                            color: d.authDark.withValues(
                                              alpha: 0.48,
                                            ),
                                          ),
                                          constraints: BoxConstraints(
                                            minHeight: d.authFieldHeight,
                                          ),
                                          onFieldSubmitted: (_) =>
                                              _handleLogin(),
                                          decoration: const InputDecoration(
                                            hintText: 'Enter your password',
                                          ),
                                          validator: (val) {
                                            if (val == null || val.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            return null;
                                          },
                                        ),
                                        Positioned(
                                          top: (d.authFieldHeight -
                                                  d.minimumTarget) /
                                              2,
                                          right: d.xs,
                                          child: Tooltip(
                                            message: _obscurePassword
                                                ? 'Show password'
                                                : 'Hide password',
                                            child: AppPressable(
                                              key: const ValueKey<String>(
                                                'password-visibility-toggle',
                                              ),
                                              semanticLabel: _obscurePassword
                                                  ? 'Show password'
                                                  : 'Hide password',
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                              child: SizedBox.square(
                                                dimension: d.minimumTarget,
                                                child: Icon(
                                                  _obscurePassword
                                                      ? LucideIcons.eyeOff
                                                      : LucideIcons.eye,
                                                  size: 20,
                                                  color: d.authDark.withValues(
                                                    alpha: 0.62,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: d.xl,
                                    ),
                                    SizedBox(
                                      height: d.authButtonHeight,
                                      child: AppButton(
                                        key: const ValueKey<String>(
                                          'login-submit-button',
                                        ),
                                        onPressed:
                                            _isLoading ? null : _handleLogin,
                                        isLoading: _isLoading,
                                        pill: true,
                                        backgroundColor: d.authDark,
                                        foregroundColor: d.authLight,
                                        borderColor: d.authDark,
                                        labelStyle: d.authButtonLabel,
                                        label: 'Login',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        ),
      ),
    );
  }
}

class AttendifyHeaderPainter extends CustomPainter {
  const AttendifyHeaderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
    ..moveTo(-2, -2)                // start 2px outside the top-left corner
    ..lineTo(w + 2, -2)             // go 2px past the right edge along the top
    ..lineTo(w + 2, h * (46 / 270)) // go down the right side, still 2px outside
    ..cubicTo(
      w * (372 / 420), h * (168 / 270), // same curve as before
      w * (258 / 420), h * (262 / 270),
      w * (150 / 420), h * (252 / 270),
    )
    ..cubicTo(
      w * (80 / 420), h * (246 / 270),  // same second curve
      w * (28 / 420), h * (206 / 270),
      -2, h * (168 / 270),              // end 2px outside the left edge
    )
    ..close();      

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant AttendifyHeaderPainter oldDelegate) =>
      oldDelegate.color != color;
}

