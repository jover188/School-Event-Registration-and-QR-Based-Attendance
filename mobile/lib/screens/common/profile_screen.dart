import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_button.dart';
import '../auth/account_input.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
import 'notification_preferences_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const ProfileScreen({super.key, this.initialData});

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
    if (widget.initialData != null) {
      _isLoading = false;
      _applyProfileData(widget.initialData!);
    } else {
      _fetchProfile();
    }
  }

  void _applyProfileData(Map<String, dynamic> data) {
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
        _applyProfileData(response.data as Map<String, dynamic>);
      } else {
        _errorMessage = response.message ?? 'Failed to load profile details.';
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_isSavingProfile) return;
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

    final d = context.design;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: response.success ? d.success : d.destructive,
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
    if (_isSavingPassword) return;
    if (!_passwordFormKey.currentState!.validate()) {
      setState(() {
        _passwordAutovalidate = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.design.destructive,
          content: const Text('New passwords do not match.'),
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

    final d = context.design;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: response.success ? d.success : d.destructive,
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
    final d = context.design;
    return AppPageScaffold(
      title: 'My Profile & Settings',
      maxWidth: 720,
      actions: [
        IconButton(
          tooltip: 'Refresh Profile',
          icon: Icon(LucideIcons.refreshCw, size: 18, color: d.foreground),
          onPressed: _isLoading ? null : _fetchProfile,
        ),
      ],
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ErrorStateView(
                    message: _errorMessage!,
                    onRetry: _fetchProfile,
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(d.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Account Identity Summary Card
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(d.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: d.selection,
                                        borderRadius: BorderRadius.circular(
                                          d.radiusControl,
                                        ),
                                        border: Border.all(
                                          color: d.primary.withValues(
                                            alpha: 0.18,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        LucideIcons.user,
                                        size: 22,
                                        color: d.primary,
                                      ),
                                    ),
                                    SizedBox(width: d.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _email,
                                            style: d.sectionTitle,
                                          ),
                                          if (_hasStudentProfile &&
                                              _studentIdNumber.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Student ID: $_studentIdNumber (Immutable)',
                                              style: d.supporting,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: d.lg, color: d.border),
                                Wrap(
                                  spacing: d.sm,
                                  runSpacing: d.sm,
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
                        SizedBox(height: d.md),

                        // Notification Preferences Link Card
                        Card(
                          child: ListTile(
                            leading: Icon(
                              LucideIcons.bell,
                              size: 20,
                              color: d.primary,
                            ),
                            title: Text(
                              'Notification Preferences',
                              style: d.cardTitle,
                            ),
                            subtitle: Text(
                              'Manage event reminders and mandatory campus alerts',
                              style: d.supporting,
                            ),
                            trailing: Icon(
                              LucideIcons.chevronRight,
                              size: 18,
                              color: d.mutedForeground,
                            ),
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
                        SizedBox(height: d.lg),

                        // Student Editable Profile Section
                        if (_hasStudentProfile) ...[
                          const SectionHeader(
                            title: 'Academic & Contact Details',
                            subtitle:
                                'Student ID and school email are permanently bound to your identity.',
                          ),
                          SizedBox(height: d.gap),
                          Card(
                            child: Padding(
                              padding: EdgeInsets.all(d.md),
                              child: FocusTraversalGroup(
                                child: AutofillGroup(
                                  child: Form(
                                    key: _profileFormKey,
                                    autovalidateMode: _profileAutovalidate,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ResponsiveGrid(
                                          minItemWidth: 280,
                                          maxColumns: 2,
                                          children: [
                                            AccountInput(
                                              key: const ValueKey<String>(
                                                'profile-first-name',
                                              ),
                                              controller: _firstNameController,
                                              textInputAction:
                                                  TextInputAction.next,
                                              autofillHints: const [
                                                AutofillHints.givenName
                                              ],
                                              decoration: const InputDecoration(
                                                labelText: 'First Name *',
                                              ),
                                              validator: (v) => v == null ||
                                                      v.trim().isEmpty
                                                  ? 'Required'
                                                  : null,
                                            ),
                                            AccountInput(
                                              key: const ValueKey<String>(
                                                'profile-last-name',
                                              ),
                                              controller: _lastNameController,
                                              textInputAction:
                                                  TextInputAction.next,
                                              autofillHints: const [
                                                AutofillHints.familyName
                                              ],
                                              decoration: const InputDecoration(
                                                labelText: 'Last Name *',
                                              ),
                                              validator: (v) => v == null ||
                                                      v.trim().isEmpty
                                                  ? 'Required'
                                                  : null,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: d.gap),
                                        AccountInput(
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
                                        SizedBox(height: d.gap),
                                        ResponsiveGrid(
                                          minItemWidth: 280,
                                          maxColumns: 2,
                                          children: [
                                            AccountInput(
                                              key: const ValueKey<String>(
                                                'profile-course',
                                              ),
                                              controller: _courseController,
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration: const InputDecoration(
                                                labelText: 'Course / Program *',
                                              ),
                                              validator: (v) => v == null ||
                                                      v.trim().isEmpty
                                                  ? 'Required'
                                                  : null,
                                            ),
                                            DropdownButtonFormField<String>(
                                              key: const ValueKey<String>(
                                                'profile-year-level',
                                              ),
                                              initialValue: _selectedYearLevel,
                                              isExpanded: true,
                                              decoration: const InputDecoration(
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
                                          ],
                                        ),
                                        SizedBox(height: d.gap),
                                        ResponsiveGrid(
                                          minItemWidth: 280,
                                          maxColumns: 2,
                                          children: [
                                            AccountInput(
                                              key: const ValueKey<String>(
                                                'profile-section',
                                              ),
                                              controller: _sectionController,
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration: const InputDecoration(
                                                labelText: 'Section *',
                                              ),
                                              validator: (v) => v == null ||
                                                      v.trim().isEmpty
                                                  ? 'Required'
                                                  : null,
                                            ),
                                            AccountInput(
                                              key: const ValueKey<String>(
                                                'profile-contact',
                                              ),
                                              controller: _contactController,
                                              keyboardType: TextInputType.phone,
                                              textInputAction:
                                                  TextInputAction.next,
                                              autofillHints: const [
                                                AutofillHints.telephoneNumber
                                              ],
                                              decoration: const InputDecoration(
                                                labelText: 'Contact Number *',
                                              ),
                                              validator: (v) => v == null ||
                                                      v.trim().isEmpty
                                                  ? 'Required'
                                                  : null,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: d.gap),
                                        AccountInput(
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
                                        SizedBox(height: d.md),
                                        AppButton(
                                          key: const ValueKey<String>(
                                            'save-profile-button',
                                          ),
                                          onPressed: _isSavingProfile
                                              ? null
                                              : _saveProfile,
                                          isLoading: _isSavingProfile,
                                          label: 'Save Profile Changes',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: d.lg),
                        ],

                        // Change Password Section
                        const SectionHeader(
                          title: 'Change Password',
                          subtitle:
                              'Requires your current password and a strong 8+ character password.',
                        ),
                        SizedBox(height: d.gap),
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(d.md),
                            child: FocusTraversalGroup(
                              child: AutofillGroup(
                                child: Form(
                                  key: _passwordFormKey,
                                  autovalidateMode: _passwordAutovalidate,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      AccountInput(
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
                                          prefixIcon: Icon(
                                            LucideIcons.lock,
                                            size: 18,
                                            color: d.mutedForeground,
                                          ),
                                          suffixIcon: IconButton(
                                            tooltip: _obscureCurrentPassword
                                                ? 'Show current password'
                                                : 'Hide current password',
                                            icon: Icon(
                                              _obscureCurrentPassword
                                                  ? LucideIcons.eyeOff
                                                  : LucideIcons.eye,
                                              size: 18,
                                              color: d.mutedForeground,
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
                                      SizedBox(height: d.gap),
                                      AccountInput(
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
                                          prefixIcon: Icon(
                                            LucideIcons.keyRound,
                                            size: 18,
                                            color: d.mutedForeground,
                                          ),
                                          suffixIcon: IconButton(
                                            tooltip: _obscureNewPassword
                                                ? 'Show new password'
                                                : 'Hide new password',
                                            icon: Icon(
                                              _obscureNewPassword
                                                  ? LucideIcons.eyeOff
                                                  : LucideIcons.eye,
                                              size: 18,
                                              color: d.mutedForeground,
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
                                      SizedBox(height: d.gap),
                                      AccountInput(
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
                                          prefixIcon: Icon(
                                            LucideIcons.lock,
                                            size: 18,
                                            color: d.mutedForeground,
                                          ),
                                          suffixIcon: IconButton(
                                            tooltip: _obscureConfirmPassword
                                                ? 'Show confirm password'
                                                : 'Hide confirm password',
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? LucideIcons.eyeOff
                                                  : LucideIcons.eye,
                                              size: 18,
                                              color: d.mutedForeground,
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
                                      SizedBox(height: d.md),
                                      AppButton(
                                        variant: AppButtonVariant.outline,
                                        key: const ValueKey<String>(
                                          'update-password-button',
                                        ),
                                        onPressed: _isSavingPassword
                                            ? null
                                            : _changePassword,
                                        isLoading: _isSavingPassword,
                                        label: 'Update Password',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: d.xl),
                      ],
                    ),
                  ),
      ),
    );
  }
}
