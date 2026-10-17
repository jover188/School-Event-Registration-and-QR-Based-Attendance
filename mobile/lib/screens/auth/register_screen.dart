import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _middleName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _studentIdNumber = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final TextEditingController _course = TextEditingController();
  final TextEditingController _yearLevel =
      TextEditingController(text: '1st Year');
  final TextEditingController _section = TextEditingController();
  final TextEditingController _department = TextEditingController();
  final TextEditingController _contactNumber = TextEditingController();

  static const List<String> _yearLevels = <String>[
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
  ];

  String _selectedYearLevel = '1st Year';
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _pickedPhoto;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _studentIdNumber.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _course.dispose();
    _yearLevel.dispose();
    _section.dispose();
    _department.dispose();
    _contactNumber.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() {
        _pickedPhoto = File(picked.path);
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    if (_password.text != _confirmPassword.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final fields = <String, String>{
      'first_name': _firstName.text.trim(),
      'middle_name': _middleName.text.trim(),
      'last_name': _lastName.text.trim(),
      'student_id_number': _studentIdNumber.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'password_confirmation': _confirmPassword.text,
      'course': _course.text.trim(),
      'year_level': _selectedYearLevel,
      'section': _section.text.trim(),
      'department': _department.text.trim(),
      'contact_number': _contactNumber.text.trim(),
    };

    final response = await ApiClient().multipartPost(
      ApiConstants.register,
      fields,
      file: _pickedPhoto,
      fileField: 'profile_photo',
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      TextInput.finishAutofillContext(shouldSave: true);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Registration Successful'),
          content: const Text(
            'Your account has been created and your permanent student QR code has been issued. You can now log in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to login screen
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _errorMessage = response.message ??
            'Registration failed. Please check your information.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Self-Registration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md + 4),
          child: FocusTraversalGroup(
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidateMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo Upload Picker
                    Center(
                      child: Semantics(
                        button: true,
                        label: 'Upload verification profile photo',
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.primaryLight,
                                backgroundImage: _pickedPhoto != null
                                    ? FileImage(_pickedPhoto!)
                                    : null,
                                child: _pickedPhoto == null
                                    ? const Icon(
                                        Icons.add_a_photo,
                                        size: 36,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                              const Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary,
                                  child: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Center(
                      child: Text(
                        'Tap to upload verification profile photo',
                        style: AppTypography.caption,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md + 4),

                    if (_errorMessage != null) ...[
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
                            _errorMessage!,
                            style: AppTypography.bodyMuted.copyWith(
                              color: AppColors.absent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Full Name Fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey<String>('register-first-name'),
                            controller: _firstName,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.givenName],
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 4),
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey<String>('register-last-name'),
                            controller: _lastName,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.familyName],
                            decoration: const InputDecoration(
                              labelText: 'Last Name *',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    TextFormField(
                      key: const ValueKey<String>('register-middle-name'),
                      controller: _middleName,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.middleName],
                      decoration: const InputDecoration(
                        labelText: 'Middle Name (Optional)',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),

                    // Academic Identification
                    TextFormField(
                      key: const ValueKey<String>('register-student-id'),
                      controller: _studentIdNumber,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Student ID Number *',
                        hintText: 'e.g. 20260001 (Numeric only)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
                          return 'Numeric format only';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    TextFormField(
                      key: const ValueKey<String>('register-email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'School Email Address *',
                        hintText: 'student@school.edu',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Enter a valid school email'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),

                    // Degree Program & Year Level Dropdown
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            key: const ValueKey<String>('register-course'),
                            controller: _course,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Course / Program *',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 4),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey<String>('register-year-level'),
                            initialValue: _selectedYearLevel,
                            decoration: const InputDecoration(
                              labelText: 'Year Level *',
                            ),
                            items: _yearLevels
                                .map(
                                  (level) => DropdownMenuItem<String>(
                                    value: level,
                                    child: Text(level),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedYearLevel = value;
                                  _yearLevel.text = value;
                                });
                              }
                            },
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey<String>('register-section'),
                            controller: _section,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Section *',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 4),
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey<String>('register-contact'),
                            controller: _contactNumber,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Contact Number *',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    TextFormField(
                      key: const ValueKey<String>('register-department'),
                      controller: _department,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Department / College *',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),

                    // Passwords
                    TextFormField(
                      key: const ValueKey<String>('register-password'),
                      controller: _password,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText:
                            'Password (min. 8 chars, 1 uppercase, 1 number) *',
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
                      validator: (v) => v == null || v.length < 8
                          ? 'Minimum 8 characters'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    TextFormField(
                      key: const ValueKey<String>('register-confirm-password'),
                      controller: _confirmPassword,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _submitRegistration(),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password *',
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
                      validator: (v) => v == null || v.isEmpty
                          ? 'Please confirm password'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    ElevatedButton(
                      key: const ValueKey<String>('register-submit-button'),
                      onPressed: _isLoading ? null : _submitRegistration,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Complete Registration'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
