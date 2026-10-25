import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
import 'notification_preferences_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool embedded;

  const ProfileScreen({
    super.key,
    this.initialData,
    this.embedded = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  String _email = '';
  String _role = 'student';
  String _status = 'active';
  bool _hasStudentProfile = false;
  String _studentIdNumber = '';
  String _firstName = '';
  String _middleName = '';
  String _lastName = '';
  String _course = '';
  String _yearLevel = '';
  String _section = '';
  String _department = '';

  String get _fullName {
    final parts = [
      _firstName,
      if (_middleName.isNotEmpty) _middleName,
      _lastName,
    ].where((s) => s.trim().isNotEmpty).join(' ');
    return parts.isEmpty ? 'Student' : parts;
  }

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
      _firstName = student['first_name']?.toString() ?? '';
      _middleName = student['middle_name']?.toString() ?? '';
      _lastName = student['last_name']?.toString() ?? '';
      _course = student['course']?.toString() ?? '';
      _yearLevel = student['year_level']?.toString() ?? '';
      _section = student['section']?.toString() ?? '';
      _department = student['department']?.toString() ?? '';
    } else {
      _hasStudentProfile = false;
    }
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

  Widget _buildDetailField({
    required String label,
    required String value,
    required IconData icon,
    required AppDesignTokens design,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: design.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: design.mutedForeground,
              ),
              SizedBox(width: design.xs),
              Expanded(
                child: Text(
                  label,
                  style: design.supporting,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            style: design.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return AppPageScaffold(
      title: 'My Profile & Settings',
      embedded: widget.embedded,
      maxWidth: 720,
      body: SafeArea(
        child: _isLoading
            ? Center(child: AppSpinner(color: d.authDark, size: 28))
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
                        Container(
                          padding: EdgeInsets.all(d.md),
                          decoration: BoxDecoration(
                            color: d.card,
                            borderRadius: BorderRadius.circular(d.radiusCard),
                            border: Border.all(color: d.border, width: 1),
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
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.user,
                                    size: 18,
                                    color: d.primary,
                                  ),
                                  SizedBox(width: d.sm),
                                  Expanded(
                                    child: Text(
                                      _email,
                                      style: d.sectionTitle,
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
                        SizedBox(height: d.md),

                        // Notification Preferences Link Card
                        Container(
                          decoration: BoxDecoration(
                            color: d.card,
                            borderRadius: BorderRadius.circular(d.radiusCard),
                            border: Border.all(color: d.border, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: d.authDark.withValues(alpha: 0.04),
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(d.radiusCard),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const NotificationPreferencesScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.all(d.md),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                LucideIcons.bell,
                                                size: 18,
                                                color: d.primary,
                                              ),
                                              SizedBox(width: d.sm),
                                              Expanded(
                                                child: Text(
                                                  'Notification Preferences',
                                                  style: d.cardTitle,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Manage event reminders and mandatory campus alerts',
                                            style: d.supporting,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: d.sm),
                                    Icon(
                                      LucideIcons.chevronRight,
                                      size: 18,
                                      color: d.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: d.lg),

                        // Student Institutional Profile Section
                        if (_hasStudentProfile) ...[
                          const SectionHeader(
                            title: 'Institutional Academic Identity',
                            subtitle:
                                'Official student records synchronized with school information systems.',
                          ),
                          SizedBox(height: d.gap),

                          // Notice Banner
                          Container(
                            key: const ValueKey<String>(
                              'institutional-notice-banner',
                            ),
                            padding: EdgeInsets.all(d.md),
                            decoration: BoxDecoration(
                              color: d.isDark
                                  ? d.muted
                                  : const Color(0xFFF4F6F8),
                              borderRadius:
                                  BorderRadius.circular(d.radiusCard),
                              border: Border.all(
                                color: d.isDark
                                    ? d.border
                                    : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  LucideIcons.info,
                                  size: 20,
                                  color: d.primary,
                                ),
                                SizedBox(width: d.sm + 2),
                                Expanded(
                                  child: Text(
                                    'Institutional records are synchronized with the School Student Information System (SIS) and are read-only. For official record corrections, contact the registrar\'s office.',
                                    style: d.supporting.copyWith(
                                      color: d.foreground,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: d.gap),

                          // Read-Only Institutional Identity Card
                          Container(
                            key: const ValueKey<String>(
                              'student-institutional-card',
                            ),
                            padding: EdgeInsets.all(d.md),
                            decoration: BoxDecoration(
                              color: d.card,
                              borderRadius:
                                  BorderRadius.circular(d.radiusCard),
                              border: Border.all(color: d.border, width: 1),
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
                              children: [
                                Wrap(
                                  spacing: d.sm,
                                  runSpacing: d.sm,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: d.sm + 2,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: d.isDark
                                            ? d.muted
                                            : const Color(0xFFEFEFEF),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.full,
                                        ),
                                        border: Border.all(color: d.border),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.idCard,
                                            size: 13,
                                            color: d.foreground,
                                          ),
                                          SizedBox(width: d.xs),
                                          Flexible(
                                            child: Text(
                                              _studentIdNumber,
                                              style: d.badge.copyWith(
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: d.sm + 2,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: d.isDark
                                            ? d.statusBackgroundColor(
                                                'approved',
                                              )
                                            : AppPalette.successBackground,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.full,
                                        ),
                                        border: Border.all(
                                          color: d
                                              .statusColor('approved')
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.shieldCheck,
                                            size: 13,
                                            color: d.statusColor('approved'),
                                          ),
                                          SizedBox(width: d.xs),
                                          Flexible(
                                            child: Text(
                                              'Institutional Record',
                                              style: d.badge.copyWith(
                                                color:
                                                    d.statusColor('approved'),
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: d.md),
                                Text(
                                  'Full Name',
                                  style: d.supporting,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _fullName,
                                  style: d.cardTitle.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Divider(height: d.lg, color: d.border),
                                ResponsiveGrid(
                                  minItemWidth: 260,
                                  maxColumns: 2,
                                  children: [
                                    _buildDetailField(
                                      label: 'Course / Program',
                                      value: _course,
                                      icon: LucideIcons.graduationCap,
                                      design: d,
                                    ),
                                    _buildDetailField(
                                      label: 'Year Level',
                                      value: _yearLevel,
                                      icon: LucideIcons.layers,
                                      design: d,
                                    ),
                                    _buildDetailField(
                                      label: 'Section',
                                      value: _section,
                                      icon: LucideIcons.users,
                                      design: d,
                                    ),
                                    _buildDetailField(
                                      label: 'Department / College',
                                      value: _department,
                                      icon: LucideIcons.building2,
                                      design: d,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: d.lg),
                        ] else ...[
                          const SectionHeader(
                            title: 'Account Information',
                            subtitle:
                                'Staff credentials and access permissions are managed by system administrators.',
                          ),
                          SizedBox(height: d.lg),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}
