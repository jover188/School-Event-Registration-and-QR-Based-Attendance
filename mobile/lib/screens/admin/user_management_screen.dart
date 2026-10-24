import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/account_input.dart';
import 'student_qr_inspect_screen.dart';

class UserManagementScreen extends StatefulWidget {
  final bool embedded;
  final String? initialRoleFilter;
  final bool qrInspectMode;
  final List<Map<String, dynamic>>? initialUsers;

  const UserManagementScreen({
    super.key,
    this.embedded = false,
    this.initialRoleFilter,
    this.qrInspectMode = false,
    this.initialUsers,
  });

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocus = FocusNode();

  bool _isLoading = true;
  String? _errorMessage;
  late String _selectedRole =
      widget.initialRoleFilter ?? (widget.qrInspectMode ? 'student' : 'all');
  String _selectedStatus = 'all';
  List<Map<String, dynamic>>? _fixtureUsers;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialUsers != null) {
      _isLoading = false;
      _fixtureUsers = widget.initialUsers!
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _users = _applyLocalFilters(_fixtureUsers!);
    } else {
      _fetchUsers();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  static String _extractRoleSlug(Map<String, dynamic> user) {
    final roleMap = user['role'] is Map
        ? Map<String, dynamic>.from(user['role'] as Map)
        : null;
    return (roleMap?['slug']?.toString() ?? user['role']?.toString() ?? 'user')
        .toLowerCase();
  }

  List<Map<String, dynamic>> _applyLocalFilters(
    List<Map<String, dynamic>> source,
  ) {
    final search = _searchController.text.trim().toLowerCase();
    return source.where((user) {
      final roleSlug = _extractRoleSlug(user);
      if (_selectedRole != 'all' && roleSlug != _selectedRole) {
        return false;
      }
      final status = (user['status']?.toString() ?? 'active').toLowerCase();
      if (_selectedStatus != 'all' && status != _selectedStatus) {
        return false;
      }
      if (search.isNotEmpty) {
        final email = (user['email']?.toString() ?? '').toLowerCase();
        final student = user['student'] is Map
            ? Map<String, dynamic>.from(user['student'] as Map)
            : null;
        final fullName = (student?['full_name']?.toString() ??
                '${student?['first_name'] ?? ''} ${student?['last_name'] ?? ''}')
            .toLowerCase();
        final studentNumber =
            (student?['student_id_number']?.toString() ?? '').toLowerCase();
        if (!email.contains(search) &&
            !fullName.contains(search) &&
            !studentNumber.contains(search)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _fetchUsers() async {
    if (_fixtureUsers != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _users = _applyLocalFilters(_fixtureUsers!);
      });
      return;
    }

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
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
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

    if (_fixtureUsers != null) {
      final roleSlug = switch (payload.roleId) {
        1 => 'administrator',
        4 => 'management',
        _ => 'organizer',
      };
      setState(() {
        _fixtureUsers!.insert(0, {
          'id': _fixtureUsers!.length + 100,
          'email': payload.email,
          'status': 'active',
          'role': {'slug': roleSlug},
        });
        _users = _applyLocalFilters(_fixtureUsers!);
      });
      AppToast.success(context, 'Staff user account created successfully.');
      return;
    }

    final response = await ApiClient().post(ApiConstants.adminUsers, {
      'email': payload.email,
      'password': payload.password,
      'role_id': payload.roleId,
    });

    if (!mounted) return;

    if (response.success) {
      AppToast.success(
        context,
        response.message ?? 'Staff user account created successfully.',
      );
      _fetchUsers();
    } else {
      AppToast.error(
        context,
        response.message ?? 'Failed to create staff user account.',
      );
    }
  }

  Future<void> _confirmAndToggleUserStatus(Map<String, dynamic> user) async {
    final userId = (user['id'] as num?)?.toInt();
    if (userId == null) return;
    final email = user['email']?.toString() ?? 'User #$userId';
    final currentStatus =
        (user['status']?.toString() ?? 'active').toLowerCase();
    final isDeactivating = currentStatus == 'active';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmUserStatusDialog(
        email: email,
        isDeactivating: isDeactivating,
      ),
    );

    if (confirmed != true || !mounted) return;

    final nextStatus = isDeactivating ? 'inactive' : 'active';

    if (_fixtureUsers != null) {
      setState(() {
        for (var i = 0; i < _fixtureUsers!.length; i++) {
          if ((_fixtureUsers![i]['id'] as num?)?.toInt() == userId) {
            _fixtureUsers![i] = {
              ..._fixtureUsers![i],
              'status': nextStatus,
            };
          }
        }
        _users = _applyLocalFilters(_fixtureUsers!);
      });
      AppToast.success(context, 'User status updated to $nextStatus.');
      return;
    }

    final response = await ApiClient().patch(
      ApiConstants.adminUserStatus(userId),
      {},
    );

    if (!mounted) return;

    if (response.success) {
      AppToast.success(
        context,
        response.message ?? 'User status updated successfully.',
      );
      _fetchUsers();
    } else {
      AppToast.error(
        context,
        response.message ?? 'Failed to update user account status.',
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

    if (_fixtureUsers != null) {
      AppToast.success(
        context,
        'Password reset for $email and prior sessions revoked.',
      );
      return;
    }

    final response = await ApiClient().post(
      ApiConstants.adminResetPassword(userId),
      {'password': newPassword},
    );

    if (!mounted) return;

    if (response.success) {
      AppToast.success(
        context,
        response.message ?? 'Password reset and sessions revoked.',
      );
    } else {
      AppToast.error(
        context,
        response.message ?? 'Failed to reset user password.',
      );
    }
  }

  void _openQrInspect(int studentId, String? studentLabel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentQrInspectScreen(
          studentId: studentId,
          studentName: studentLabel,
          studentLabel: studentLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final title = widget.qrInspectMode
        ? 'Student QR Records'
        : 'User & Role Management';

    return AppPageScaffold(
      title: title,
      embedded: widget.embedded,
      body: RefreshIndicator(
        onRefresh: _fetchUsers,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: widget.qrInspectMode
                        ? 'Student QR Identity Directory'
                        : 'Institutional Accounts',
                    subtitle: widget.qrInspectMode
                        ? 'Select a student account to inspect active QR tokens, audit history, or force-reissue a code'
                        : 'Search accounts, manage status, reset passwords, or provision staff users',
                    trailing: Wrap(
                      spacing: d.sm,
                      runSpacing: d.xs,
                      children: [
                        if (!widget.qrInspectMode)
                          AppButton(
                            key: const ValueKey<String>(
                              'create-staff-user-fab',
                            ),
                            pill: true,
                            onPressed: _openCreateStaffDialog,
                            icon: LucideIcons.userPlus,
                            label: 'Create Staff User',
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: d.gap),
                  AccountInput(
                    key: const ValueKey<String>('user-search-field'),
                    controller: _searchController,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (_) => _fetchUsers(),
                    decoration: InputDecoration(
                      labelText:
                          'Search Users by Email, Name, or Student ID',
                      hintText: 'Type email, name, or student ID',
                      prefixIcon: Icon(
                        LucideIcons.search,
                        size: 18,
                        color: d.mutedForeground,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Search Users',
                        icon: const Icon(LucideIcons.arrowRight, size: 18),
                        onPressed: _fetchUsers,
                      ),
                    ),
                  ),
                  SizedBox(height: d.gap),
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
                  const Divider(),
                ],
              ),
            ),
            if (_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: d.xl),
                  child: Center(
                    child: Semantics(
                      label: 'Loading user accounts',
                      child: AppSpinner(color: d.authDark, size: 28),
                    ),
                  ),
                ),
              )
            else if (_errorMessage != null && _users.isEmpty)
              SliverToBoxAdapter(
                child: ErrorStateView(
                  message: _errorMessage!,
                  onRetry: _fetchUsers,
                ),
              )
            else if (_users.isEmpty)
              SliverToBoxAdapter(
                child: EmptyStateView(
                  icon: LucideIcons.users,
                  title: 'No users match the selected filters.',
                  actionLabel: 'Refresh',
                  onAction: _fetchUsers,
                ),
              )
            else
              ResponsiveCardSliver(
                itemCount: _users.length,
                minItemWidth: 340,
                maxColumns: 2,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return _AdminUserCard(
                    user: user,
                    qrInspectMode: widget.qrInspectMode,
                    onToggleStatus: () => _confirmAndToggleUserStatus(user),
                    onResetPassword: () => _openResetPasswordDialog(user),
                    onInspectQr: _openQrInspect,
                  );
                },
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
    final d = context.design;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: d.sm,
          runSpacing: d.xs,
          children: [
            for (final r in _roles)
              ChoiceChip(
                key: ValueKey<String>('role-filter-${r.value}'),
                label: Text(r.label),
                selected: selectedRole == r.value,
                onSelected: (_) => onSelectRole(r.value),
              ),
          ],
        ),
        SizedBox(height: d.sm),
        Wrap(
          spacing: d.sm,
          runSpacing: d.xs,
          children: [
            for (final s in _statuses)
              ChoiceChip(
                key: ValueKey<String>('status-filter-${s.value}'),
                label: Text(s.label),
                selected: selectedStatus == s.value,
                onSelected: (_) => onSelectStatus(s.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool qrInspectMode;
  final VoidCallback onToggleStatus;
  final VoidCallback onResetPassword;
  final void Function(int studentId, String? studentName) onInspectQr;

  const _AdminUserCard({
    required this.user,
    required this.qrInspectMode,
    required this.onToggleStatus,
    required this.onResetPassword,
    required this.onInspectQr,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final userId = (user['id'] as num?)?.toInt() ?? 0;
    final email = user['email']?.toString() ?? 'N/A';
    final status = user['status']?.toString() ?? 'active';
    final roleMap = user['role'] is Map
        ? Map<String, dynamic>.from(user['role'] as Map)
        : null;
    final roleSlug =
        roleMap?['slug']?.toString() ?? user['role']?.toString() ?? 'user';
    final student = user['student'] is Map
        ? Map<String, dynamic>.from(user['student'] as Map)
        : null;
    final studentId = (student?['id'] as num?)?.toInt() ??
        (user['student_id'] as num?)?.toInt() ??
        (roleSlug.toLowerCase() == 'student' ? userId : null);
    final studentName = student?['full_name']?.toString() ??
        [
          student?['first_name']?.toString() ?? '',
          student?['last_name']?.toString() ?? '',
        ].where((s) => s.trim().isNotEmpty).join(' ');
    final studentNumber = student?['student_id_number']?.toString();
    final course = student?['course']?.toString();

    return Container(
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: d.authDark.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: d.sm,
            runSpacing: d.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(email, style: d.cardTitle),
              Wrap(
                spacing: d.xs,
                runSpacing: d.xs,
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
          if (studentName.isNotEmpty || studentNumber != null) ...[
            SizedBox(height: d.xs),
            Text(
              '${studentName.isEmpty ? email : studentName}${studentNumber != null ? ' ($studentNumber)' : ''}${course != null ? ' • $course' : ''}',
              style: d.supporting,
            ),
          ],
          const Divider(),
          Wrap(
            spacing: d.sm,
            runSpacing: d.sm,
            alignment: WrapAlignment.end,
            children: [
              if (!qrInspectMode) ...[
                AppButton(
                  key: ValueKey<String>('toggle-user-status-$userId'),
                  pill: true,
                  variant: status == 'active'
                      ? AppButtonVariant.outline
                      : AppButtonVariant.primary,
                  onPressed: onToggleStatus,
                  icon: status == 'active'
                      ? LucideIcons.userX
                      : LucideIcons.userCheck,
                  label: status == 'active' ? 'Deactivate' : 'Activate',
                ),
                AppButton(
                  key: ValueKey<String>('reset-user-password-$userId'),
                  pill: true,
                  variant: AppButtonVariant.outline,
                  onPressed: onResetPassword,
                  icon: LucideIcons.keyRound,
                  label: 'Reset Password',
                ),
              ],
              if (studentId != null && studentId > 0)
                AppButton(
                  key: ValueKey<String>('inspect-student-qr-$studentId'),
                  pill: true,
                  variant: AppButtonVariant.primary,
                  onPressed: () => onInspectQr(
                    studentId,
                    studentName.isEmpty ? email : studentName,
                  ),
                  icon: LucideIcons.qrCode,
                  label: 'Inspect QR',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmUserStatusDialog extends StatelessWidget {
  final String email;
  final bool isDeactivating;

  const _ConfirmUserStatusDialog({
    required this.email,
    required this.isDeactivating,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(d.radiusCard),
        side: BorderSide(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
        ),
      ),
      title: Row(
        children: [
          Icon(
            isDeactivating ? LucideIcons.userX : LucideIcons.userCheck,
            size: 20,
            color: isDeactivating ? d.destructive : d.success,
          ),
          SizedBox(width: d.sm),
          Expanded(
            child: Text(
              '${isDeactivating ? 'Deactivate' : 'Activate'} User Account?',
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isDeactivating
                    ? 'Deactivating $email will immediately block login access and revoke any active session for this institutional account.'
                    : 'Activating $email will restore login access for this institutional account.',
                style: d.body,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Wrap(
          spacing: d.sm,
          runSpacing: d.sm,
          alignment: WrapAlignment.end,
          children: [
            AppButton(
              pill: true,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(context, false),
              label: 'Cancel',
            ),
            AppButton(
              key: const ValueKey<String>('confirm-user-status-button'),
              pill: true,
              variant: isDeactivating
                  ? AppButtonVariant.destructive
                  : AppButtonVariant.primary,
              onPressed: () => Navigator.pop(context, true),
              label: isDeactivating ? 'Confirm Deactivate' : 'Confirm Activate',
            ),
          ],
        ),
      ],
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
    final d = context.design;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(d.radiusCard),
        side: BorderSide(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
        ),
      ),
      title: Row(
        children: [
          Icon(LucideIcons.userPlus, size: 20, color: d.primary),
          SizedBox(width: d.sm),
          const Expanded(child: Text('Create Staff Account')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: FocusTraversalGroup(
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
                      isExpanded: true,
                      initialValue: _selectedRoleId,
                      decoration: InputDecoration(
                        labelText: 'Account Role',
                        prefixIcon: Icon(
                          LucideIcons.shield,
                          size: 18,
                          color: d.mutedForeground,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 2,
                          child: Text(
                            'Event Organizer (Role #2)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child: Text(
                            'School Management - Read Only (Role #4)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text(
                            'System Administrator (Role #1)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedRoleId = val);
                        }
                      },
                    ),
                    SizedBox(height: d.gap),
                    AccountInput(
                      key: const ValueKey<String>('staff-email-field'),
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Official Email Address',
                        hintText: 'organizer@school.edu.ph',
                        prefixIcon: Icon(
                          LucideIcons.mail,
                          size: 18,
                          color: d.mutedForeground,
                        ),
                      ),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty || !trimmed.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: d.gap),
                    AccountInput(
                      key: const ValueKey<String>('staff-password-field'),
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Initial Password',
                        hintText: 'Minimum 8 characters',
                        prefixIcon: Icon(
                          LucideIcons.lock,
                          size: 18,
                          color: d.mutedForeground,
                        ),
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
      ),
      actions: [
        Wrap(
          spacing: d.sm,
          runSpacing: d.sm,
          alignment: WrapAlignment.end,
          children: [
            AppButton(
              pill: true,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
              label: 'Cancel',
            ),
            AppButton(
              key: const ValueKey<String>('confirm-create-staff-button'),
              pill: true,
              onPressed: _submit,
              label: 'Create User',
            ),
          ],
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
    final d = context.design;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(d.radiusCard),
        side: BorderSide(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
        ),
      ),
      title: Row(
        children: [
          Icon(LucideIcons.keyRound, size: 20, color: d.primary),
          SizedBox(width: d.sm),
          const Expanded(child: Text('Reset User Password')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: FocusTraversalGroup(
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Set a new password for ${widget.email}. All existing sessions for this user will be immediately revoked.',
                      style: d.supporting,
                    ),
                    SizedBox(height: d.md),
                    AccountInput(
                      key: const ValueKey<String>('reset-password-field'),
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Minimum 8 characters',
                        prefixIcon: Icon(
                          LucideIcons.lock,
                          size: 18,
                          color: d.mutedForeground,
                        ),
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
      ),
      actions: [
        Wrap(
          spacing: d.sm,
          runSpacing: d.sm,
          alignment: WrapAlignment.end,
          children: [
            AppButton(
              pill: true,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
              label: 'Cancel',
            ),
            AppButton(
              key: const ValueKey<String>('confirm-reset-password-button'),
              pill: true,
              onPressed: _submit,
              label: 'Reset Password',
            ),
          ],
        ),
      ],
    );
  }
}
