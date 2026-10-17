import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
import 'notification_preferences_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  static const List<String> _yearLevels = <String>[
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
  ];

  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  String? _errorMessage;

  String _email = '';
  String _role = 'student';
  String _status = 'active';
  bool _hasStudentProfile = false;
  String _studentIdNumber = '';
  String _selectedYearLevel = '1st Year';

  AutovalidateMode _profileAutovalidate = AutovalidateMode.disabled;
  AutovalidateMode _passwordAutovalidate = AutovalidateMode.disabled;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _courseController.dispose();
    _sectionController.dispose();
    _departmentController.dispose();
    _contactController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiClient().get(ApiConstants.profile);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final user = (data['user'] as Map<String, dynamic>?) ?? data;
        final student = data['student_profile'] as Map<String, dynamic>?;

        _email = user['email']?.toString() ?? '';
        _role = user['role']?.toString() ?? 'student';
        _status = user['status']?.toString() ?? 'active';

        if (student != null) {
          _hasStudentProfile = true;
          _studentIdNumber = student['student_id_number']?.toString() ?? '';
          _firstNameController.text = student['first_name']?.toString() ?? '';
          _middleNameController.text = student['middle_name']?.toString() ?? '';
          _lastNameController.text = student['last_name']?.toString() ?? '';
          _courseController.text = student['course']?.toString() ?? '';
          _sectionController.text = student['section']?.toString() ?? '';
          _departmentController.text = student['department']?.toString() ?? '';
          _contactController.text = student['contact_number']?.toString() ?? '';

          final year = student['year_level']?.toString() ?? '1st Year';
          _selectedYearLevel =
              _yearLevels.contains(year) ? year : _yearLevels.first;
        } else {
          _hasStudentProfile = false;
        }
      } else {
        _errorMessage = response.message ?? 'Failed to load profile details.';
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) {
      setState(() {
        _profileAutovalidate = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    setState(() => _isSavingProfile = true);

    final response = await ApiClient().put(ApiConstants.profile, {
      'first_name': _firstNameController.text.trim(),
      'middle_name': _middleNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'course': _courseController.text.trim(),
      'year_level': _selectedYearLevel,
      'section': _sectionController.text.trim(),
      'department': _departmentController.text.trim(),
      'contact_number': _contactController.text.trim(),
    });

    if (!mounted) return;

    setState(() => _isSavingProfile = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            response.success ? AppColors.present : AppColors.absent,
        content: Text(
          response.message ??
              (response.success
                  ? 'Profile updated successfully.'
                  : 'Failed to update profile.'),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      setState(() {
        _passwordAutovalidate = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.absent,
          content: Text('New passwords do not match.'),
        ),
      );
      return;
    }

    setState(() => _isSavingPassword = true);

    final response = await ApiClient().post(ApiConstants.changePassword, {
      'current_password': _currentPasswordController.text,
      'new_password': _newPasswordController.text,
      'new_password_confirmation': _confirmPasswordController.text,
    });

    if (!mounted) return;

    setState(() => _isSavingPassword = false);

    if (response.success) {
      TextInput.finishAutofillContext(shouldSave: true);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            response.success ? AppColors.present : AppColors.absent,
        content: Text(
          response.message ??
              (response.success
                  ? 'Password updated successfully.'
                  : 'Failed to update password.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Settings'),
        actions: [
          IconButton(
            tooltip: 'Refresh Profile',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ErrorStateView(
                    message: _errorMessage!,
                    onRetry: _fetchProfile,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Account Identity Summary Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 26,
                                      backgroundColor: AppColors.primaryLight,
                                      child: Icon(
                                        Icons.person_outline,
                                        size: 28,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _email,
                                            style: AppTypography.subtitle,
                                          ),
                                          if (_hasStudentProfile &&
                                              _studentIdNumber.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Student ID: $_studentIdNumber (Immutable)',
                                              style: AppTypography.caption,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: AppSpacing.lg),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    StatusBadge(
                                      status: _role,
                                      label: 'ROLE: ${_role.toUpperCase()}',
                                    ),
                                    StatusBadge(
                                      status: _status,
                                      label: 'STATUS: ${_status.toUpperCase()}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Notification Preferences Link Card
                        Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.notifications_active_outlined,
                              color: AppColors.primary,
                            ),
                            title: const Text(
                              'Notification Preferences',
                              style: AppTypography.subtitle,
                            ),
                            subtitle: const Text(
                              'Manage event reminders and mandatory campus alerts',
                              style: AppTypography.caption,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationPreferencesScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Student Editable Profile Section
                        if (_hasStudentProfile) ...[
                          const SectionHeader(
                            title: 'Academic & Contact Details',
                            subtitle:
                                'Student ID and school email are permanently bound to your identity.',
                          ),
                          const SizedBox(height: AppSpacing.sm + 4),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: FocusTraversalGroup(
                                child: AutofillGroup(
                                  child: Form(
                                    key: _profileFormKey,
                                    autovalidateMode: _profileAutovalidate,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                key: const ValueKey<String>(
                                                  'profile-first-name',
                                                ),
                                                controller:
                                                    _firstNameController,
                                                textInputAction:
                                                    TextInputAction.next,
                                                autofillHints: const [
                                                  AutofillHints.givenName
                                                ],
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'First Name *',
                                                ),
                                                validator: (v) => v == null ||
                                                        v.trim().isEmpty
                                                    ? 'Required'
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm + 4,
                                            ),
                                            Expanded(
                                              child: TextFormField(
                                                key: const ValueKey<String>(
                                                  'profile-last-name',
                                                ),
                                                controller: _lastNameController,
                                                textInputAction:
                                                    TextInputAction.next,
                                                autofillHints: const [
                                                  AutofillHints.familyName
                                                ],
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Last Name *',
                                                ),
                                                validator: (v) => v == null ||
                                                        v.trim().isEmpty
                                                    ? 'Required'
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.sm + 4,
                                        ),
                                        TextFormField(
                                          key: const ValueKey<String>(
                                            'profile-middle-name',
                                          ),
                                          controller: _middleNameController,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.middleName
                                          ],
                                          decoration: const InputDecoration(
                                            labelText: 'Middle Name (Optional)',
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.sm + 4,
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: TextFormField(
                                                key: const ValueKey<String>(
                                                  'profile-course',
                                                ),
                                                controller: _courseController,
                                                textInputAction:
                                                    TextInputAction.next,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText:
                                                      'Course / Program *',
                                                ),
                                                validator: (v) => v == null ||
                                                        v.trim().isEmpty
                                                    ? 'Required'
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm + 4,
                                            ),
                                            Expanded(
                                              child: DropdownButtonFormField<
                                                  String>(
                                                key: const ValueKey<String>(
                                                  'profile-year-level',
                                                ),
                                                initialValue:
                                                    _selectedYearLevel,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Year Level *',
                                                ),
                                                items: _yearLevels
                                                    .map(
                                                      (yr) => DropdownMenuItem<
                                                          String>(
                                                        value: yr,
                                                        child: Text(yr),
                                                      ),
                                                    )
                                                    .toList(),
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    setState(
                                                      () => _selectedYearLevel =
                                                          val,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.sm + 4,
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                key: const ValueKey<String>(
                                                  'profile-section',
                                                ),
                                                controller: _sectionController,
                                                textInputAction:
                                                    TextInputAction.next,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Section *',
                                                ),
                                                validator: (v) => v == null ||
                                                        v.trim().isEmpty
                                                    ? 'Required'
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm + 4,
                                            ),
                                            Expanded(
                                              child: TextFormField(
                                                key: const ValueKey<String>(
                                                  'profile-contact',
                                                ),
                                                controller: _contactController,
                                                keyboardType:
                                                    TextInputType.phone,
                                                textInputAction:
                                                    TextInputAction.next,
                                                autofillHints: const [
                                                  AutofillHints.telephoneNumber
                                                ],
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Contact Number *',
                                                ),
                                                validator: (v) => v == null ||
                                                        v.trim().isEmpty
                                                    ? 'Required'
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.sm + 4,
                                        ),
                                        TextFormField(
                                          key: const ValueKey<String>(
                                            'profile-department',
                                          ),
                                          controller: _departmentController,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) =>
                                              _saveProfile(),
                                          decoration: const InputDecoration(
                                            labelText: 'Department / College *',
                                          ),
                                          validator: (v) =>
                                              v == null || v.trim().isEmpty
                                                  ? 'Required'
                                                  : null,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        ElevatedButton.icon(
                                          key: const ValueKey<String>(
                                            'save-profile-button',
                                          ),
                                          onPressed: _isSavingProfile
                                              ? null
                                              : _saveProfile,
                                          icon: const Icon(Icons.save_outlined),
                                          label: _isSavingProfile
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text(
                                                  'Save Profile Changes',
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Change Password Section
                        const SectionHeader(
                          title: 'Change Password',
                          subtitle:
                              'Requires your current password and a strong 8+ character password.',
                        ),
                        const SizedBox(height: AppSpacing.sm + 4),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: FocusTraversalGroup(
                              child: AutofillGroup(
                                child: Form(
                                  key: _passwordFormKey,
                                  autovalidateMode: _passwordAutovalidate,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextFormField(
                                        key: const ValueKey<String>(
                                          'change-current-password',
                                        ),
                                        controller: _currentPasswordController,
                                        obscureText: _obscureCurrentPassword,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.password
                                        ],
                                        decoration: InputDecoration(
                                          labelText: 'Current Password *',
                                          prefixIcon:
                                              const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            tooltip: _obscureCurrentPassword
                                                ? 'Show current password'
                                                : 'Hide current password',
                                            icon: Icon(
                                              _obscureCurrentPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscureCurrentPassword =
                                                  !_obscureCurrentPassword,
                                            ),
                                          ),
                                        ),
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Enter current password'
                                            : null,
                                      ),
                                      const SizedBox(height: AppSpacing.sm + 4),
                                      TextFormField(
                                        key: const ValueKey<String>(
                                          'change-new-password',
                                        ),
                                        controller: _newPasswordController,
                                        obscureText: _obscureNewPassword,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.newPassword
                                        ],
                                        decoration: InputDecoration(
                                          labelText:
                                              'New Password (min. 8 chars) *',
                                          prefixIcon:
                                              const Icon(Icons.lock_reset),
                                          suffixIcon: IconButton(
                                            tooltip: _obscureNewPassword
                                                ? 'Show new password'
                                                : 'Hide new password',
                                            icon: Icon(
                                              _obscureNewPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscureNewPassword =
                                                  !_obscureNewPassword,
                                            ),
                                          ),
                                        ),
                                        validator: (v) =>
                                            v == null || v.length < 8
                                                ? 'Minimum 8 characters'
                                                : null,
                                      ),
                                      const SizedBox(height: AppSpacing.sm + 4),
                                      TextFormField(
                                        key: const ValueKey<String>(
                                          'change-confirm-password',
                                        ),
                                        controller: _confirmPasswordController,
                                        obscureText: _obscureConfirmPassword,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.newPassword
                                        ],
                                        onFieldSubmitted: (_) =>
                                            _changePassword(),
                                        decoration: InputDecoration(
                                          labelText: 'Confirm New Password *',
                                          prefixIcon:
                                              const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            tooltip: _obscureConfirmPassword
                                                ? 'Show confirm password'
                                                : 'Hide confirm password',
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscureConfirmPassword =
                                                  !_obscureConfirmPassword,
                                            ),
                                          ),
                                        ),
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Confirm your new password'
                                            : null,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      OutlinedButton.icon(
                                        key: const ValueKey<String>(
                                          'update-password-button',
                                        ),
                                        onPressed: _isSavingPassword
                                            ? null
                                            : _changePassword,
                                        icon: const Icon(Icons.key_outlined),
                                        label: _isSavingPassword
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text('Update Password'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
      ),
    );
  }
}
