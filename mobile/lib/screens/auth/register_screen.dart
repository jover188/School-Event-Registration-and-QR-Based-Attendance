import 'dart:io';
import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _studentIdNumber = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _course = TextEditingController();
  final _yearLevel = TextEditingController();
  final _section = TextEditingController();
  final _department = TextEditingController();
  final _contactNumber = TextEditingController();

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
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _pickedPhoto = File(picked.path);
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

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

    final fields = {
      'first_name': _firstName.text.trim(),
      'middle_name': _middleName.text.trim(),
      'last_name': _lastName.text.trim(),
      'student_id_number': _studentIdNumber.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'password_confirmation': _confirmPassword.text,
      'course': _course.text.trim(),
      'year_level': _yearLevel.text.trim(),
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

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      if (!mounted) return;
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
        _errorMessage = response.message ?? 'Registration failed. Please check your information.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Self-Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Upload Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                        backgroundImage: _pickedPhoto != null ? FileImage(_pickedPhoto!) : null,
                        child: _pickedPhoto == null
                            ? const Icon(Icons.add_a_photo, size: 36, color: AppTheme.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primary,
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Tap to upload verification profile photo', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.absentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.absentColor),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.absentColor, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              // Full Name Fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstName,
                      decoration: const InputDecoration(labelText: 'First Name *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastName,
                      decoration: const InputDecoration(labelText: 'Last Name *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _middleName,
                decoration: const InputDecoration(labelText: 'Middle Name (Optional)'),
              ),
              const SizedBox(height: 12),

              // Academic Identification
              TextFormField(
                controller: _studentIdNumber,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Student ID Number *',
                  hintText: 'e.g. 20260001 (Numeric only)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) return 'Numeric format only';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'School Email Address *',
                  hintText: 'student@school.edu',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) => v == null || !v.contains('@') ? 'Enter a valid school email' : null,
              ),
              const SizedBox(height: 12),

              // Degree Program & Year
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _course,
                      decoration: const InputDecoration(labelText: 'Course / Program *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _yearLevel,
                      decoration: const InputDecoration(labelText: 'Year Level *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _section,
                      decoration: const InputDecoration(labelText: 'Section *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _contactNumber,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Contact Number *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _department,
                decoration: const InputDecoration(labelText: 'Department / College *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Passwords
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (min. 8 chars, 1 uppercase, 1 number) *',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => v == null || v.length < 8 ? 'Minimum 8 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password *',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Please confirm password' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitRegistration,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Complete Registration'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
