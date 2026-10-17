import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/status_badge.dart';
import 'student_qr_inspect_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocus = FocusNode();

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedRole = 'all';
  String _selectedStatus = 'all';
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final queryParams = <String, String>{};
    if (_selectedRole != 'all') {
      queryParams['role'] = _selectedRole;
    }
    if (_selectedStatus != 'all') {
      queryParams['status'] = _selectedStatus;
    }
    final search = _searchController.text.trim();
    if (search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await ApiClient().get(
      ApiConstants.adminUsers,
      queryParams: queryParams.isEmpty ? null : queryParams,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data is List) {
        _users = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      } else {
        _errorMessage =
            response.message ?? 'Failed to load user accounts.';
      }
    });
  }

  Future<void> _openCreateStaffDialog() async {
    final payload =
        await showDialog<({String email, String password, int roleId})>(
      context: context,
      builder: (_) => const _CreateStaffUserDialog(),
    );

    if (payload == null || !mounted) return;

    final response = await ApiClient().post(ApiConstants.adminUsers, {
      'email': payload.email,
      'password': payload.password,
      'role_id': payload.roleId,
    });

    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(
            response.message ?? 'Staff user account created successfully.',
          ),
        ),
      );
      _fetchUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(
            response.message ?? 'Failed to create staff user account.',
          ),
        ),
      );
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final userId = (user['id'] as num?)?.toInt();
    if (userId == null) return;

    final response = await ApiClient().patch(
      ApiConstants.adminUserStatus(userId),
      {},
    );

    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(
            response.message ?? 'User status updated successfully.',
          ),
        ),
      );
      _fetchUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(
            response.message ?? 'Failed to update user account status.',
          ),
        ),
      );
    }
  }

  Future<void> _openResetPasswordDialog(Map<String, dynamic> user) async {
    final userId = (user['id'] as num?)?.toInt();
    if (userId == null) return;
    final email = user['email']?.toString() ?? 'User #$userId';

    final newPassword = await showDialog<String>(
      context: context,
      builder: (_) => _ResetUserPasswordDialog(email: email),
    );

    if (newPassword == null || newPassword.isEmpty || !mounted) return;

    final response = await ApiClient().post(
      ApiConstants.adminResetPassword(userId),
      {'password': newPassword},
    );

    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(
            response.message ?? 'Password reset and sessions revoked.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(
            response.message ?? 'Failed to reset user password.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User & Role Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh Users',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey<String>('create-staff-user-fab'),
        onPressed: _openCreateStaffDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Create Staff User'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: TextField(
                key: const ValueKey<String>('user-search-field'),
                controller: _searchController,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _fetchUsers(),
                decoration: InputDecoration(
                  labelText: 'Search Users by Email, Name, or Student ID',
                  hintText: 'Type email or name and press search',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Search Users',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _fetchUsers,
                  ),
                ),
              ),
            ),
            _UserFilterSection(
              selectedRole: _selectedRole,
              selectedStatus: _selectedStatus,
              onSelectRole: (role) {
                setState(() => _selectedRole = role);
                _fetchUsers();
              },
              onSelectStatus: (status) {
                setState(() => _selectedStatus = status);
                _fetchUsers();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? ErrorStateView(
                          message: _errorMessage!,
                          onRetry: _fetchUsers,
                        )
                      : _users.isEmpty
                          ? EmptyStateView(
                              icon: Icons.people_outline,
                              title: 'No users match the selected filters.',
                              actionLabel: 'Refresh',
                              onAction: _fetchUsers,
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchUsers,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  AppSpacing.md,
                                  AppSpacing.md,
                                  88,
                                ),
                                itemCount: _users.length,
                                itemBuilder: (context, index) {
                                  final user = _users[index];
                                  return _AdminUserCard(
                                    user: user,
                                    onToggleStatus: () =>
                                        _toggleUserStatus(user),
                                    onResetPassword: () =>
                                        _openResetPasswordDialog(user),
                                    onInspectQr: (studentId, studentName) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              StudentQrInspectScreen(
                                            studentId: studentId,
                                            studentName: studentName,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserFilterSection extends StatelessWidget {
  final String selectedRole;
  final String selectedStatus;
  final ValueChanged<String> onSelectRole;
  final ValueChanged<String> onSelectStatus;

  const _UserFilterSection({
    required this.selectedRole,
    required this.selectedStatus,
    required this.onSelectRole,
    required this.onSelectStatus,
  });

  static const List<({String value, String label})> _roles = [
    (value: 'all', label: 'All Roles'),
    (value: 'administrator', label: 'Administrator'),
    (value: 'organizer', label: 'Organizer'),
    (value: 'student', label: 'Student'),
    (value: 'management', label: 'Management'),
  ];

  static const List<({String value, String label})> _statuses = [
    (value: 'all', label: 'All Statuses'),
    (value: 'active', label: 'Active'),
    (value: 'inactive', label: 'Inactive'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              for (final r in _roles)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    key: ValueKey<String>('role-filter-${r.value}'),
                    label: Text(r.label),
                    selected: selectedRole == r.value,
                    onSelected: (_) => onSelectRole(r.value),
                  ),
                ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              for (final s in _statuses)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    key: ValueKey<String>('status-filter-${s.value}'),
                    label: Text(s.label),
                    selected: selectedStatus == s.value,
                    onSelected: (_) => onSelectStatus(s.value),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggleStatus;
  final VoidCallback onResetPassword;
  final void Function(int studentId, String? studentName) onInspectQr;

  const _AdminUserCard({
    required this.user,
    required this.onToggleStatus,
    required this.onResetPassword,
    required this.onInspectQr,
  });

  @override
  Widget build(BuildContext context) {
    final email = user['email']?.toString() ?? 'N/A';
    final status = user['status']?.toString() ?? 'active';
    final roleMap = user['role'] is Map<String, dynamic>
        ? user['role'] as Map<String, dynamic>
        : null;
    final roleSlug =
        roleMap?['slug']?.toString() ?? user['role']?.toString() ?? 'user';
    final student = user['student'] is Map<String, dynamic>
        ? user['student'] as Map<String, dynamic>
        : null;
    final studentId = (student?['id'] as num?)?.toInt();
    final studentName = student?['full_name']?.toString() ??
        [
          student?['first_name']?.toString() ?? '',
          student?['last_name']?.toString() ?? '',
        ].where((s) => s.trim().isNotEmpty).join(' ');
    final studentNumber = student?['student_id_number']?.toString();
    final course = student?['course']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (studentName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$studentName${studentNumber != null ? ' ($studentNumber)' : ''}${course != null ? ' • $course' : ''}',
                          style: AppTypography.bodyMuted,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    StatusBadge(
                      status: 'completed',
                      label: roleSlug.toUpperCase(),
                      showIcon: false,
                    ),
                    StatusBadge(status: status),
                  ],
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onToggleStatus,
                  icon: Icon(
                    status == 'active'
                        ? Icons.person_off_outlined
                        : Icons.check_circle_outline,
                    size: 16,
                  ),
                  label: Text(
                    status == 'active' ? 'Deactivate' : 'Activate',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onResetPassword,
                  icon: const Icon(Icons.lock_reset_outlined, size: 16),
                  label: const Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                if (studentId != null)
                  ElevatedButton.icon(
                    onPressed: () => onInspectQr(
                      studentId,
                      studentName.isEmpty ? email : studentName,
                    ),
                    icon: const Icon(Icons.qr_code_2_outlined, size: 16),
                    label: const Text(
                      'Inspect QR',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateStaffUserDialog extends StatefulWidget {
  const _CreateStaffUserDialog();

  @override
  State<_CreateStaffUserDialog> createState() => _CreateStaffUserDialogState();
}

class _CreateStaffUserDialogState extends State<_CreateStaffUserDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _passwordController =
      TextEditingController();
  late final FocusNode _emailFocus = FocusNode();
  late final FocusNode _passwordFocus = FocusNode();

  int _selectedRoleId = 2; // Default Organizer
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final invalid = _formKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      if (!_emailController.text.contains('@')) {
        _emailFocus.requestFocus();
      } else {
        _passwordFocus.requestFocus();
      }
      return;
    }
    _formKey.currentState!.save();
    TextInput.finishAutofillContext(shouldSave: true);
    Navigator.pop(
      context,
      (
        email: _emailController.text.trim(),
        password: _passwordController.text,
        roleId: _selectedRoleId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Staff Account'),
      content: FocusTraversalGroup(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    key: const ValueKey<String>('staff-role-dropdown'),
                    initialValue: _selectedRoleId,
                    decoration: const InputDecoration(
                      labelText: 'Account Role',
                      helperText: ' ',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 2,
                        child: Text('Event Organizer (Role #2)'),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text('School Management - Read Only (Role #4)'),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text('System Administrator (Role #1)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedRoleId = val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    key: const ValueKey<String>('staff-email-field'),
                    controller: _emailController,
                    focusNode: _emailFocus,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Official Email Address',
                      hintText: 'organizer@school.edu.ph',
                      prefixIcon: Icon(Icons.email_outlined),
                      helperText: ' ',
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty || !trimmed.contains('@')) {
                        return 'Enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    key: const ValueKey<String>('staff-password-field'),
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Initial Password',
                      hintText: 'Minimum 8 characters',
                      prefixIcon: Icon(Icons.lock_outline),
                      helperText: ' ',
                    ),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Password must be at least 8 characters.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Create User'),
        ),
      ],
    );
  }
}

class _ResetUserPasswordDialog extends StatefulWidget {
  final String email;

  const _ResetUserPasswordDialog({required this.email});

  @override
  State<_ResetUserPasswordDialog> createState() =>
      _ResetUserPasswordDialogState();
}

class _ResetUserPasswordDialogState extends State<_ResetUserPasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _passwordController =
      TextEditingController();
  late final FocusNode _passwordFocus = FocusNode();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final invalid = _formKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      _passwordFocus.requestFocus();
      return;
    }
    _formKey.currentState!.save();
    Navigator.pop(context, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset User Password'),
      content: FocusTraversalGroup(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Set a new password for ${widget.email}. All existing sessions for this user will be immediately revoked.',
                  style: AppTypography.bodyMuted,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const ValueKey<String>('reset-password-field'),
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Minimum 8 characters',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                    helperText: ' ',
                  ),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Password must be at least 8 characters.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Reset Password'),
        ),
      ],
    );
  }
}
