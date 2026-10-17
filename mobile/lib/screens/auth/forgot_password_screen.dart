import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_header.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final int initialTabIndex;

  const ForgotPasswordScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTabIndex.clamp(0, 1),
  );

  // Step 1 & Step 2 Password Reset State
  final GlobalKey<FormState> _requestFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _resetFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _tokenFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  AutovalidateMode _requestAutovalidate = AutovalidateMode.disabled;
  AutovalidateMode _resetAutovalidate = AutovalidateMode.disabled;
  bool _hasRequestedToken = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isResetLoading = false;
  String? _devResetToken;
  String? _resetErrorMessage;
  String? _resetSuccessMessage;

  // Email Verification State
  final GlobalKey<FormState> _verifyFormKey = GlobalKey<FormState>();
  final TextEditingController _verifyEmailController = TextEditingController();
  final TextEditingController _verifyCodeController = TextEditingController();
  final FocusNode _verifyEmailFocus = FocusNode();
  final FocusNode _verifyCodeFocus = FocusNode();
  AutovalidateMode _verifyAutovalidate = AutovalidateMode.disabled;
  bool _isVerifyLoading = false;
  String? _verifyErrorMessage;
  String? _verifySuccessMessage;

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _tokenFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _verifyEmailController.dispose();
    _verifyCodeController.dispose();
    _verifyEmailFocus.dispose();
    _verifyCodeFocus.dispose();
    super.dispose();
  }

  Future<void> _requestResetToken() async {
    if (!_requestFormKey.currentState!.validate()) {
      setState(() {
        _requestAutovalidate = AutovalidateMode.onUserInteraction;
      });
      _emailFocus.requestFocus();
      return;
    }

    setState(() {
      _isResetLoading = true;
      _resetErrorMessage = null;
      _resetSuccessMessage = null;
    });

    final response = await ApiClient().post(ApiConstants.forgotPassword, {
      'email': _emailController.text.trim(),
    });

    if (!mounted) return;

    setState(() {
      _isResetLoading = false;
    });

    if (response.success) {
      String? token;
      if (response.data is Map<String, dynamic>) {
        token = response.data['reset_token']?.toString();
      }
      setState(() {
        _hasRequestedToken = true;
        _devResetToken = token;
        if (token != null && token.isNotEmpty) {
          _tokenController.text = token;
        }
        _resetSuccessMessage = response.message ??
            'Password reset token generated and sent to your school email.';
      });
      _tokenFocus.requestFocus();
    } else {
      setState(() {
        _resetErrorMessage = response.message ??
            'Could not generate reset token. Check the email address.';
      });
    }
  }

  Future<void> _submitPasswordReset() async {
    if (!_resetFormKey.currentState!.validate()) {
      setState(() {
        _resetAutovalidate = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _resetErrorMessage = 'Passwords do not match.';
      });
      _confirmPasswordFocus.requestFocus();
      return;
    }

    setState(() {
      _isResetLoading = true;
      _resetErrorMessage = null;
      _resetSuccessMessage = null;
    });

    final response = await ApiClient().post(ApiConstants.resetPassword, {
      'email': _emailController.text.trim(),
      'token': _tokenController.text.trim(),
      'password': _newPasswordController.text,
      'password_confirmation': _confirmPasswordController.text,
    });

    if (!mounted) return;

    setState(() {
      _isResetLoading = false;
    });

    if (response.success) {
      TextInput.finishAutofillContext(shouldSave: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(
            response.message ??
                'Password has been reset successfully. You may now log in.',
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _resetErrorMessage =
            response.message ?? 'Invalid or expired password reset token.';
      });
    }
  }

  Future<void> _submitEmailVerification() async {
    if (!_verifyFormKey.currentState!.validate()) {
      setState(() {
        _verifyAutovalidate = AutovalidateMode.onUserInteraction;
      });
      _verifyEmailFocus.requestFocus();
      return;
    }

    setState(() {
      _isVerifyLoading = true;
      _verifyErrorMessage = null;
      _verifySuccessMessage = null;
    });

    final response = await ApiClient().post(ApiConstants.verifyEmail, {
      'email': _verifyEmailController.text.trim(),
      if (_verifyCodeController.text.trim().isNotEmpty)
        'code': _verifyCodeController.text.trim(),
    });

    if (!mounted) return;

    setState(() {
      _isVerifyLoading = false;
    });

    if (response.success) {
      setState(() {
        _verifySuccessMessage = response.message ??
            'Email verified successfully. Your account is now active.';
      });
    } else {
      setState(() {
        _verifyErrorMessage =
            response.message ?? 'Could not verify email address.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Recovery & Verification'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.lock_reset_outlined),
              text: 'Reset Password',
            ),
            Tab(
              icon: Icon(Icons.mark_email_read_outlined),
              text: 'Verify Email',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Password Reset Flow
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(
                    title: 'Step 1: Request Reset Code',
                    subtitle:
                        'Enter your school email address to receive a 6-digit password reset token.',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (_resetErrorMessage != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm + 4),
                        decoration: BoxDecoration(
                          color: AppColors.absent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.absent),
                        ),
                        child: Text(
                          _resetErrorMessage!,
                          style: AppTypography.bodyMuted.copyWith(
                            color: AppColors.absent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  if (_resetSuccessMessage != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm + 4),
                        decoration: BoxDecoration(
                          color: AppColors.present.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.present),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _resetSuccessMessage!,
                              style: AppTypography.bodyMuted.copyWith(
                                color: AppColors.present,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_devResetToken != null &&
                                _devResetToken!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Development Reset Code: $_devResetToken (Auto-filled below)',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  FocusTraversalGroup(
                    child: AutofillGroup(
                      child: Form(
                        key: _requestFormKey,
                        autovalidateMode: _requestAutovalidate,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              key: const ValueKey<String>(
                                'forgot-password-email',
                              ),
                              controller: _emailController,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.send,
                              autofillHints: const [AutofillHints.email],
                              onFieldSubmitted: (_) => _requestResetToken(),
                              decoration: const InputDecoration(
                                labelText: 'School Email Address *',
                                hintText: 'student@school.edu',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (val) {
                                if (val == null ||
                                    val.trim().isEmpty ||
                                    !val.contains('@')) {
                                  return 'Please enter a valid school email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton.icon(
                              key: const ValueKey<String>(
                                'request-reset-token-button',
                              ),
                              onPressed:
                                  _isResetLoading ? null : _requestResetToken,
                              icon: const Icon(Icons.send_outlined),
                              label: Text(
                                _hasRequestedToken
                                    ? 'Resend Reset Code'
                                    : 'Send Reset Code',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Divider(height: AppSpacing.xl),

                  const SectionHeader(
                    title: 'Step 2: Set New Password',
                    subtitle:
                        'Enter the 6-digit reset token and choose a new password.',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  FocusTraversalGroup(
                    child: AutofillGroup(
                      child: Form(
                        key: _resetFormKey,
                        autovalidateMode: _resetAutovalidate,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              key: const ValueKey<String>(
                                'reset-password-token',
                              ),
                              controller: _tokenController,
                              focusNode: _tokenFocus,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              onFieldSubmitted: (_) =>
                                  _newPasswordFocus.requestFocus(),
                              decoration: const InputDecoration(
                                labelText: '6-Digit Reset Token *',
                                hintText: 'e.g. 123456',
                                prefixIcon: Icon(Icons.pin_outlined),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter the reset token';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              key: const ValueKey<String>(
                                'reset-new-password',
                              ),
                              controller: _newPasswordController,
                              focusNode: _newPasswordFocus,
                              obscureText: _obscureNewPassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              onFieldSubmitted: (_) =>
                                  _confirmPasswordFocus.requestFocus(),
                              decoration: InputDecoration(
                                labelText:
                                    'New Password (min. 8 chars, mixed case, number) *',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscureNewPassword
                                      ? 'Show new password'
                                      : 'Hide new password',
                                  icon: Icon(
                                    _obscureNewPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureNewPassword =
                                          !_obscureNewPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              key: const ValueKey<String>(
                                'reset-confirm-password',
                              ),
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocus,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              onFieldSubmitted: (_) => _submitPasswordReset(),
                              decoration: InputDecoration(
                                labelText: 'Confirm New Password *',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscureConfirmPassword
                                      ? 'Show confirm password'
                                      : 'Hide confirm password',
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please confirm your new password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ElevatedButton(
                              key: const ValueKey<String>(
                                'submit-password-reset-button',
                              ),
                              onPressed: _isResetLoading
                                  ? null
                                  : _submitPasswordReset,
                              child: _isResetLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Reset Password'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab 2: Email Verification Flow
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FocusTraversalGroup(
                child: AutofillGroup(
                  child: Form(
                    key: _verifyFormKey,
                    autovalidateMode: _verifyAutovalidate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader(
                          title: 'Verify School Email Address',
                          subtitle:
                              'Activate a pending student account by confirming your institutional email address.',
                        ),
                        const SizedBox(height: AppSpacing.md),

                        if (_verifyErrorMessage != null) ...[
                          Semantics(
                            liveRegion: true,
                            child: Container(
                              padding:
                                  const EdgeInsets.all(AppSpacing.sm + 4),
                              decoration: BoxDecoration(
                                color: AppColors.absent.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                border: Border.all(color: AppColors.absent),
                              ),
                              child: Text(
                                _verifyErrorMessage!,
                                style: AppTypography.bodyMuted.copyWith(
                                  color: AppColors.absent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        if (_verifySuccessMessage != null) ...[
                          Semantics(
                            liveRegion: true,
                            child: Container(
                              padding:
                                  const EdgeInsets.all(AppSpacing.sm + 4),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.present.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                border: Border.all(color: AppColors.present),
                              ),
                              child: Text(
                                _verifySuccessMessage!,
                                style: AppTypography.bodyMuted.copyWith(
                                  color: AppColors.present,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        TextFormField(
                          key: const ValueKey<String>('verify-email-input'),
                          controller: _verifyEmailController,
                          focusNode: _verifyEmailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          onFieldSubmitted: (_) =>
                              _verifyCodeFocus.requestFocus(),
                          decoration: const InputDecoration(
                            labelText: 'School Email Address *',
                            hintText: 'student@school.edu',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (val) {
                            if (val == null ||
                                val.trim().isEmpty ||
                                !val.contains('@')) {
                              return 'Please enter a valid school email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          key: const ValueKey<String>('verify-code-input'),
                          controller: _verifyCodeController,
                          focusNode: _verifyCodeFocus,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          onFieldSubmitted: (_) => _submitEmailVerification(),
                          decoration: const InputDecoration(
                            labelText: 'Verification Code (Optional)',
                            hintText: 'Enter code if provided in email',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          key: const ValueKey<String>(
                            'submit-verify-email-button',
                          ),
                          onPressed: _isVerifyLoading
                              ? null
                              : _submitEmailVerification,
                          icon: const Icon(Icons.check_circle_outline),
                          label: _isVerifyLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Verify Email & Activate Account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
