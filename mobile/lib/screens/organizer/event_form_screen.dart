import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/event_model.dart';

class EventFormScreen extends StatefulWidget {
  final EventModel? event;

  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _venueController;
  late final TextEditingController _coverImageController;
  late final TextEditingController _eventDateController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _registrationStartController;
  late final TextEditingController _registrationEndController;
  late final TextEditingController _maxParticipantsController;
  late final TextEditingController _lateGraceController;

  late final FocusNode _titleFocus = FocusNode();
  late final FocusNode _descriptionFocus = FocusNode();
  late final FocusNode _venueFocus = FocusNode();
  late final FocusNode _coverImageFocus = FocusNode();
  late final FocusNode _eventDateFocus = FocusNode();
  late final FocusNode _startTimeFocus = FocusNode();
  late final FocusNode _endTimeFocus = FocusNode();
  late final FocusNode _registrationStartFocus = FocusNode();
  late final FocusNode _registrationEndFocus = FocusNode();
  late final FocusNode _maxParticipantsFocus = FocusNode();
  late final FocusNode _lateGraceFocus = FocusNode();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _walkInAllowed = false;
  bool _isSaving = false;
  bool _isSubmittingAction = false;
  late String _currentStatus;

  // Audience & Category State
  String _selectedCategory = 'General';
  String _targetAudienceType = 'all';
  List<String> _selectedCourses = <String>[];
  List<String> _selectedYearLevels = <String>[];
  List<Map<String, dynamic>> _targetRules = <Map<String, dynamic>>[];
  bool _sendAnnouncement = true;

  // Custom Combination builder selection
  String _comboCourse = 'BSIT';
  String _comboYearLevel = '1st Year';

  // Dynamic Options (fetched or defaulted)
  List<String> _availableCategories = const [
    'General',
    'Academic',
    'Cultural',
    'Sports',
    'Workshop',
    'Seminar',
    'Career',
    'Community',
  ];
  List<String> _availableCourses = const [
    'BSIT',
    'BSCS',
    'BSIS',
    'BSBA',
    'BSEd',
    'BSHM',
  ];
  List<String> _availableYearLevels = const [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  Map<String, String?> _fieldServerErrors = {};

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    final defaultDate = _formatDate(DateTime.now().add(const Duration(days: 7)));
    final todayStr = _formatDate(DateTime.now());

    _currentStatus = e?.status ?? 'draft';
    _walkInAllowed = e?.walkInAllowed ?? false;

    final rawEventDate = e?.eventDate.isNotEmpty == true
        ? e!.eventDate.split('T').first
        : defaultDate;

    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _venueController = TextEditingController(text: e?.venue ?? '');
    _coverImageController = TextEditingController(text: e?.coverImagePath ?? '');
    _eventDateController = TextEditingController(text: rawEventDate);
    _startTimeController = TextEditingController(
      text: e?.startTime.isNotEmpty == true ? e!.startTime : '09:00:00',
    );
    _endTimeController = TextEditingController(
      text: e?.endTime.isNotEmpty == true ? e!.endTime : '12:00:00',
    );
    _registrationStartController = TextEditingController(
      text: '$todayStr 08:00:00',
    );
    _registrationEndController = TextEditingController(
      text: '$rawEventDate 08:00:00',
    );
    _maxParticipantsController = TextEditingController(
      text: e?.maxParticipants != null ? '${e!.maxParticipants}' : '',
    );
    _lateGraceController = TextEditingController(
      text: '${e?.lateGracePeriodMinutes ?? 15}',
    );

    if (e != null) {
      if (e.category.isNotEmpty) {
        _selectedCategory = e.category;
      }
      _targetAudienceType = e.targetAudienceType;
      _selectedCourses = List<String>.from(e.targetCourses);
      _selectedYearLevels = List<String>.from(e.targetYearLevels);
      _targetRules = List<Map<String, dynamic>>.from(e.targetRules);
      _sendAnnouncement = e.sendAnnouncement;
    }

    _fetchAudienceOptions();

    if (_isEditing) {
      _loadExistingEventDetails();
    }

    _titleController.addListener(_onFieldChanged);
    _venueController.addListener(_onFieldChanged);
    _eventDateController.addListener(_onFieldChanged);
    _startTimeController.addListener(_onFieldChanged);
    _endTimeController.addListener(_onFieldChanged);
    _maxParticipantsController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFieldChanged);
    _venueController.removeListener(_onFieldChanged);
    _eventDateController.removeListener(_onFieldChanged);
    _startTimeController.removeListener(_onFieldChanged);
    _endTimeController.removeListener(_onFieldChanged);
    _maxParticipantsController.removeListener(_onFieldChanged);

    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _coverImageController.dispose();
    _eventDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _registrationStartController.dispose();
    _registrationEndController.dispose();
    _maxParticipantsController.dispose();
    _lateGraceController.dispose();

    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _venueFocus.dispose();
    _coverImageFocus.dispose();
    _eventDateFocus.dispose();
    _startTimeFocus.dispose();
    _endTimeFocus.dispose();
    _registrationStartFocus.dispose();
    _registrationEndFocus.dispose();
    _maxParticipantsFocus.dispose();
    _lateGraceFocus.dispose();
    super.dispose();
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _fetchAudienceOptions() async {
    try {
      final response =
          await ApiClient().get(ApiConstants.eventAudienceOptions);
      if (!mounted) return;
      if (response.success && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        setState(() {
          if (data['categories'] is List &&
              (data['categories'] as List).isNotEmpty) {
            _availableCategories = (data['categories'] as List)
                .map((e) => e.toString())
                .toList();
          }
          if (data['courses'] is List &&
              (data['courses'] as List).isNotEmpty) {
            _availableCourses =
                (data['courses'] as List).map((e) => e.toString()).toList();
          }
          if (data['year_levels'] is List &&
              (data['year_levels'] as List).isNotEmpty) {
            _availableYearLevels = (data['year_levels'] as List)
                .map((e) => e.toString())
                .toList();
          }

          if (!_availableCategories.contains(_selectedCategory)) {
            _selectedCategory = _availableCategories.first;
          }
          if (!_availableCourses.contains(_comboCourse) &&
              _availableCourses.isNotEmpty) {
            _comboCourse = _availableCourses.first;
          }
          if (!_availableYearLevels.contains(_comboYearLevel) &&
              _availableYearLevels.isNotEmpty) {
            _comboYearLevel = _availableYearLevels.first;
          }
        });
      }
    } catch (_) {
      // Keep static defaults on network/offline fallback
    }
  }

  Future<void> _loadExistingEventDetails() async {
    final eventId = widget.event?.id;
    if (eventId == null) return;

    final response = await ApiClient().get(ApiConstants.eventDetail(eventId));
    if (!mounted) return;

    if (response.success && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      setState(() {
        if (data['status'] != null) {
          _currentStatus = data['status'].toString();
        }
        if (data['category'] != null &&
            data['category'].toString().isNotEmpty) {
          _selectedCategory = data['category'].toString();
        }
        if (data['cover_image_path'] != null) {
          _coverImageController.text = data['cover_image_path'].toString();
        }
        if (data['target_audience_type'] != null) {
          _targetAudienceType = data['target_audience_type'].toString();
        }
        if (data['target_courses'] is List) {
          _selectedCourses = (data['target_courses'] as List)
              .map((e) => e.toString())
              .toList();
        }
        if (data['target_year_levels'] is List) {
          _selectedYearLevels = (data['target_year_levels'] as List)
              .map((e) => e.toString())
              .toList();
        }
        if (data['target_rules'] is List) {
          _targetRules = (data['target_rules'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        if (data['send_announcement'] != null) {
          _sendAnnouncement = data['send_announcement'] == true ||
              data['send_announcement'] == 1;
        }
        if (data['registration_start'] != null) {
          _registrationStartController.text = _normalizeDateTime(
            data['registration_start'].toString(),
          );
        }
        if (data['registration_end'] != null) {
          _registrationEndController.text = _normalizeDateTime(
            data['registration_end'].toString(),
          );
        }
        if (data['event_date'] != null) {
          _eventDateController.text =
              data['event_date'].toString().split('T').first;
        }
      });
    }
  }

  String _normalizeDateTime(String raw) {
    return raw.replaceAll('T', ' ').split('.').first.trim();
  }

  Future<void> _pickEventDate() async {
    final initial =
        DateTime.tryParse(_eventDateController.text.trim()) ??
        DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() {
        _eventDateController.text = _formatDate(picked);
        _fieldServerErrors.remove('event_date');
      });
    }
  }

  Future<void> _pickTime(
    TextEditingController controller,
    String fieldKey,
  ) async {
    final parts = controller.text.trim().split(':');
    final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 9) : 9;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: hour.clamp(0, 23),
        minute: minute.clamp(0, 59),
      ),
    );
    if (picked != null && mounted) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      setState(() {
        controller.text = '$hh:$mm:00';
        _fieldServerErrors.remove(fieldKey);
      });
    }
  }

  void _focusFirstInvalidField() {
    final orderedNodes = <FocusNode>[
      _titleFocus,
      _descriptionFocus,
      _venueFocus,
      _coverImageFocus,
      _eventDateFocus,
      _startTimeFocus,
      _endTimeFocus,
      _registrationStartFocus,
      _registrationEndFocus,
      _maxParticipantsFocus,
      _lateGraceFocus,
    ];
    for (final node in orderedNodes) {
      if (node.canRequestFocus) {
        node.requestFocus();
        break;
      }
    }
  }

  String get _audienceSummaryText {
    if (_targetAudienceType == 'course') {
      return _selectedCourses.isEmpty
          ? 'Specific Courses (None Selected)'
          : 'Course: ${_selectedCourses.join(", ")}';
    } else if (_targetAudienceType == 'year_level') {
      return _selectedYearLevels.isEmpty
          ? 'Specific Year Levels (None Selected)'
          : 'Year: ${_selectedYearLevels.join(", ")}';
    } else if (_targetAudienceType == 'custom') {
      if (_targetRules.isNotEmpty) {
        return _targetRules
            .map((r) {
              final c = r['course']?.toString() ?? '';
              final y = r['year_level']?.toString() ?? '';
              if (c.isNotEmpty && y.isNotEmpty) return '$c ($y)';
              return c.isNotEmpty ? c : y;
            })
            .where((s) => s.isNotEmpty)
            .join(', ');
      }
      return 'Custom Rules (No combinations added)';
    }
    return 'All Students';
  }

  void _addCustomCombination() {
    final rule = {'course': _comboCourse, 'year_level': _comboYearLevel};
    final exists = _targetRules.any(
      (r) =>
          r['course'] == rule['course'] &&
          r['year_level'] == rule['year_level'],
    );
    if (!exists) {
      setState(() {
        _targetRules.add(rule);
      });
    }
  }

  void _removeCustomCombination(int index) {
    setState(() {
      _targetRules.removeAt(index);
    });
  }

  Future<void> _saveEvent({bool saveAsDraft = false}) async {
    setState(() => _fieldServerErrors = {});

    final invalidFields = _formKey.currentState!.validateGranularly();
    if (invalidFields.isNotEmpty) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      _focusFirstInvalidField();
      return;
    }

    _formKey.currentState!.save();
    TextInput.finishAutofillContext(shouldSave: true);

    final maxCapStr = _maxParticipantsController.text.trim();
    final maxCap = maxCapStr.isEmpty ? null : int.tryParse(maxCapStr);
    final graceMinutes =
        int.tryParse(_lateGraceController.text.trim()) ?? 15;

    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _selectedCategory,
      'venue': _venueController.text.trim(),
      'cover_image_path': _coverImageController.text.trim().isNotEmpty
          ? _coverImageController.text.trim()
          : null,
      'target_audience_type': _targetAudienceType,
      'target_courses':
          _targetAudienceType == 'course' ? _selectedCourses : <String>[],
      'target_year_levels':
          _targetAudienceType == 'year_level' ? _selectedYearLevels : <String>[],
      'target_sections': <String>[],
      'target_rules':
          _targetAudienceType == 'custom' ? _targetRules : <Map<String, dynamic>>[],
      'send_announcement': _sendAnnouncement,
      'event_date': _eventDateController.text.trim(),
      'start_time': _startTimeController.text.trim(),
      'end_time': _endTimeController.text.trim(),
      'registration_start': _registrationStartController.text.trim(),
      'registration_end': _registrationEndController.text.trim(),
      'max_participants': maxCap,
      'late_grace_period_minutes': graceMinutes,
      'walk_in_allowed': _walkInAllowed,
      if (!_isEditing) 'save_as_draft': saveAsDraft,
    };

    setState(() => _isSaving = true);

    final response = _isEditing
        ? await ApiClient().put(
            ApiConstants.eventDetail(widget.event!.id),
            payload,
          )
        : await ApiClient().post(ApiConstants.events, payload);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (response.success) {
      AppToast.success(
        context,
        response.message ??
            (_isEditing
                ? 'Event updated successfully.'
                : (saveAsDraft
                    ? 'Event draft saved successfully.'
                    : 'Event submitted for approval.')),
      );
      Navigator.pop(context, true);
    } else {
      if (response.errors != null) {
        setState(() {
          _fieldServerErrors = response.errors!.map(
            (key, value) => MapEntry(
              key,
              value is List && value.isNotEmpty
                  ? value.first.toString()
                  : value?.toString(),
            ),
          );
        });
      }
      AppToast.error(
        context,
        response.message ?? 'Failed to save event.',
      );
    }
  }

  Future<void> _submitForApproval() async {
    final eventId = widget.event?.id;
    if (eventId == null) return;

    setState(() => _isSubmittingAction = true);
    final response = await ApiClient().post(
      ApiConstants.submitEventApproval(eventId),
      {},
    );

    if (!mounted) return;
    setState(() => _isSubmittingAction = false);

    if (response.success) {
      setState(() => _currentStatus = 'pending_approval');
      AppToast.success(
        context,
        response.message ??
            'Event submitted for administrator review and approval.',
      );
      Navigator.pop(context, true);
    } else {
      AppToast.error(
        context,
        response.message ?? 'Failed to submit event for approval.',
      );
    }
  }

  Future<void> _requestCancellation() async {
    final eventId = widget.event?.id;
    if (eventId == null) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RequestCancellationDialog(),
    );

    if (reason == null || reason.trim().isEmpty || !mounted) return;

    setState(() => _isSubmittingAction = true);
    final response = await ApiClient().post(
      ApiConstants.requestEventCancellation(eventId),
      {'reason': reason.trim()},
    );

    if (!mounted) return;
    setState(() => _isSubmittingAction = false);

    if (response.success) {
      AppToast.warning(
        context,
        response.message ??
            'Cancellation request recorded. Awaiting administrator approval.',
      );
      Navigator.pop(context, true);
    } else {
      AppToast.error(
        context,
        response.message ?? 'Failed to request event cancellation.',
      );
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? helperText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, size: 18),
      suffixIcon: suffixIcon,
      helperText: helperText ?? ' ',
      helperMaxLines: 3,
      errorMaxLines: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;

    return AppPageScaffold(
      title: _isEditing ? 'Edit Event' : 'Create Event',
      maxWidth: 720,
      body: FocusTraversalGroup(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + d.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isEditing) ...[
                    _EventStatusBanner(status: _currentStatus),
                    SizedBox(height: d.md),
                  ],

                  // SECTION A: Event Information
                  _FormSectionCard(
                    header: const SectionHeader(
                      title: 'Event Information',
                      subtitle:
                          'Provide official event title, description, category, and venue',
                    ),
                    children: [
                      _LabeledEventField(
                        label: 'Event Title',
                        child: TextFormField(
                          key: const ValueKey<String>('event-title-field'),
                          controller: _titleController,
                          focusNode: _titleFocus,
                          autofocus: !_isEditing,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.text,
                          autofillHints: const [AutofillHints.name],
                          forceErrorText: _fieldServerErrors['title'],
                          onChanged: (_) {
                            if (_fieldServerErrors.containsKey('title')) {
                              setState(
                                () => _fieldServerErrors.remove('title'),
                              );
                            }
                          },
                          decoration: _inputDecoration(
                            hintText: 'e.g. Annual IT Cybersecurity Symposium',
                            prefixIcon: LucideIcons.fileText,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Event title is required.';
                            }
                            if (value.trim().length > 200) {
                              return 'Title cannot exceed 200 characters.';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: d.xs),
                      _LabeledEventField(
                        label: 'Event Description',
                        child: TextFormField(
                          key: const ValueKey<String>(
                            'event-description-field',
                          ),
                          controller: _descriptionController,
                          focusNode: _descriptionFocus,
                          maxLines: 3,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.multiline,
                          forceErrorText: _fieldServerErrors['description'],
                          onChanged: (_) {
                            if (_fieldServerErrors.containsKey('description')) {
                              setState(
                                () => _fieldServerErrors.remove('description'),
                              );
                            }
                          },
                          decoration: _inputDecoration(
                            hintText:
                                'Describe the agenda, speakers, objectives, and outcomes',
                            prefixIcon: LucideIcons.alignLeft,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Event description is required.';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: d.xs),
                      ResponsiveGrid(
                        minItemWidth: 260,
                        maxColumns: 2,
                        children: [
                          _LabeledEventField(
                            label: 'Event Category',
                            child: DropdownButtonFormField<String>(
                              key: const ValueKey<String>(
                                'event-category-field',
                              ),
                              isExpanded: true,
                              initialValue: _selectedCategory,
                              decoration: _inputDecoration(
                                hintText: 'Select category',
                                prefixIcon: LucideIcons.tag,
                              ),
                              items: _availableCategories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCategory = val);
                                }
                              },
                            ),
                          ),
                          _LabeledEventField(
                            label: 'Cover Image URL / Path (Optional)',
                            child: TextFormField(
                              key: const ValueKey<String>(
                                'event-cover-image-field',
                              ),
                              controller: _coverImageController,
                              focusNode: _coverImageFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.url,
                              decoration: _inputDecoration(
                                hintText: 'e.g. https://example.com/banner.jpg',
                                prefixIcon: LucideIcons.image,
                                helperText: 'Banner graphic or thumbnail image',
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: d.xs),
                      _LabeledEventField(
                        label: 'Venue / Location',
                        child: TextFormField(
                          key: const ValueKey<String>('event-venue-field'),
                          controller: _venueController,
                          focusNode: _venueFocus,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.streetAddress,
                          autofillHints: const [AutofillHints.location],
                          forceErrorText: _fieldServerErrors['venue'],
                          onChanged: (_) {
                            if (_fieldServerErrors.containsKey('venue')) {
                              setState(
                                () => _fieldServerErrors.remove('venue'),
                              );
                            }
                          },
                          decoration: _inputDecoration(
                            hintText: 'e.g. University Main Auditorium',
                            prefixIcon: LucideIcons.mapPin,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Venue is required.';
                            }
                            if (value.trim().length > 200) {
                              return 'Venue cannot exceed 200 characters.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: d.md),

                  // SECTION B: Target Participants (Audience Selection)
                  _FormSectionCard(
                    header: const SectionHeader(
                      title: 'Target Participants',
                      subtitle:
                          'Restrict event visibility, registration, and announcement delivery',
                    ),
                    children: [
                      Text(
                        'Target Audience Scope',
                        style: d.supporting.copyWith(
                          color: d.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: d.xs),
                      Wrap(
                        spacing: d.sm,
                        runSpacing: d.sm,
                        children: [
                          _AudienceScopeChip(
                            key: const ValueKey('audience-type-all'),
                            label: 'All Students',
                            icon: LucideIcons.users,
                            isSelected: _targetAudienceType == 'all',
                            onTap: () => setState(() => _targetAudienceType = 'all'),
                          ),
                          _AudienceScopeChip(
                            key: const ValueKey('audience-type-course'),
                            label: 'Specific Course / Program',
                            icon: LucideIcons.graduationCap,
                            isSelected: _targetAudienceType == 'course',
                            onTap: () => setState(() => _targetAudienceType = 'course'),
                          ),
                          _AudienceScopeChip(
                            key: const ValueKey('audience-type-year-level'),
                            label: 'Specific Year Level',
                            icon: LucideIcons.layers,
                            isSelected: _targetAudienceType == 'year_level',
                            onTap: () =>
                                setState(() => _targetAudienceType = 'year_level'),
                          ),
                          _AudienceScopeChip(
                            key: const ValueKey('audience-type-custom'),
                            label: 'Custom Combination',
                            icon: LucideIcons.sliders,
                            isSelected: _targetAudienceType == 'custom',
                            onTap: () => setState(() => _targetAudienceType = 'custom'),
                          ),
                        ],
                      ),
                      SizedBox(height: d.md),

                      // Audience Type Sub-Controls
                      if (_targetAudienceType == 'all') ...[
                        Container(
                          padding: EdgeInsets.all(d.sm + 2),
                          decoration: BoxDecoration(
                            color: d.isDark ? d.muted : const Color(0xFFF9F9F8),
                            borderRadius: BorderRadius.circular(d.radiusControl),
                            border: Border.all(color: d.border),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.checkCheck, size: 16, color: d.foreground),
                              SizedBox(width: d.sm),
                              Expanded(
                                child: Text(
                                  'This event is open to all enrolled students across all programs and year levels.',
                                  style: d.supporting.copyWith(color: d.foreground),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_targetAudienceType == 'course') ...[
                        Text(
                          'Select Eligible Courses',
                          style: d.supporting.copyWith(
                            color: d.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: d.xs),
                        Wrap(
                          spacing: d.sm,
                          runSpacing: d.sm,
                          children: _availableCourses.map((course) {
                            final isSelected = _selectedCourses.contains(course);
                            return FilterChip(
                              key: ValueKey('course-chip-$course'),
                              label: Text(course),
                              selected: isSelected,
                              selectedColor: d.foreground,
                              checkmarkColor: d.background,
                              labelStyle: TextStyle(
                                color: isSelected ? d.background : d.foreground,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              backgroundColor: d.card,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? d.foreground : d.border,
                                ),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCourses.add(course);
                                  } else {
                                    _selectedCourses.remove(course);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ] else if (_targetAudienceType == 'year_level') ...[
                        Text(
                          'Select Eligible Year Levels',
                          style: d.supporting.copyWith(
                            color: d.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: d.xs),
                        Wrap(
                          spacing: d.sm,
                          runSpacing: d.sm,
                          children: _availableYearLevels.map((year) {
                            final isSelected = _selectedYearLevels.contains(year);
                            return FilterChip(
                              key: ValueKey('year-chip-$year'),
                              label: Text(year),
                              selected: isSelected,
                              selectedColor: d.foreground,
                              checkmarkColor: d.background,
                              labelStyle: TextStyle(
                                color: isSelected ? d.background : d.foreground,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              backgroundColor: d.card,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? d.foreground : d.border,
                                ),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedYearLevels.add(year);
                                  } else {
                                    _selectedYearLevels.remove(year);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ] else if (_targetAudienceType == 'custom') ...[
                        Text(
                          'Add Course + Year Level Combination',
                          style: d.supporting.copyWith(
                            color: d.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: d.xs),
                        ResponsiveGrid(
                          minItemWidth: 200,
                          maxColumns: 3,
                          children: [
                            DropdownButtonFormField<String>(
                              key: const ValueKey('combo-course-dropdown'),
                              isExpanded: true,
                              initialValue: _comboCourse,
                              decoration: _inputDecoration(
                                hintText: 'Course',
                                prefixIcon: LucideIcons.graduationCap,
                              ),
                              items: _availableCourses
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _comboCourse = val);
                              },
                            ),
                            DropdownButtonFormField<String>(
                              key: const ValueKey('combo-year-dropdown'),
                              isExpanded: true,
                              initialValue: _comboYearLevel,
                              decoration: _inputDecoration(
                                hintText: 'Year Level',
                                prefixIcon: LucideIcons.layers,
                              ),
                              items: _availableYearLevels
                                  .map(
                                    (y) => DropdownMenuItem(
                                      value: y,
                                      child: Text(
                                        y,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _comboYearLevel = val);
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: AppButton(
                                key: const ValueKey('add-combination-button'),
                                pill: true,
                                icon: LucideIcons.plus,
                                label: 'Add Combination',
                                onPressed: _addCustomCombination,
                              ),
                            ),
                          ],
                        ),
                        if (_targetRules.isNotEmpty) ...[
                          SizedBox(height: d.sm),
                          Text(
                            'Active Combinations:',
                            style: d.supporting.copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: d.xs),
                          Wrap(
                            spacing: d.sm,
                            runSpacing: d.sm,
                            children: List.generate(_targetRules.length, (idx) {
                              final rule = _targetRules[idx];
                              final label =
                                  '${rule['course']} – ${rule['year_level']}';
                              return Container(
                                key: ValueKey('combo-rule-$idx'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: d.card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: d.foreground, width: 1.2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: d.supporting.copyWith(
                                        color: d.foreground,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _removeCustomCombination(idx),
                                      child: Icon(
                                        LucideIcons.x,
                                        size: 14,
                                        color: d.foreground,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ],

                      SizedBox(height: d.sm),
                      // Audience Summary Pill
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: d.sm + 2,
                          vertical: d.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: d.isDark
                              ? d.muted.withValues(alpha: 0.5)
                              : const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(d.radiusControl),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.filter, size: 14, color: d.mutedForeground),
                            SizedBox(width: d.xs),
                            Expanded(
                              child: Text(
                                'Audience: $_audienceSummaryText',
                                style: d.supporting.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: d.foreground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: d.md),

                  // SECTION C: Event Schedule
                  _FormSectionCard(
                    header: const SectionHeader(
                      title: 'Event Schedule',
                      subtitle:
                          'Configure event date, start time, and end time',
                    ),
                    children: [
                      _LabeledEventField(
                        label: 'Event Date (YYYY-MM-DD)',
                        child: TextFormField(
                          key: const ValueKey<String>('event-date-field'),
                          controller: _eventDateController,
                          focusNode: _eventDateFocus,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.datetime,
                          forceErrorText: _fieldServerErrors['event_date'],
                          onChanged: (_) {
                            if (_fieldServerErrors.containsKey('event_date')) {
                              setState(
                                () => _fieldServerErrors.remove('event_date'),
                              );
                            }
                          },
                          decoration: _inputDecoration(
                            hintText: '2026-11-15',
                            prefixIcon: LucideIcons.calendar,
                            suffixIcon: IconButton(
                              tooltip: 'Pick Event Date',
                              icon: const Icon(LucideIcons.calendarDays, size: 18),
                              onPressed: _pickEventDate,
                            ),
                          ),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return 'Event date is required.';
                            }
                            if (!RegExp(r'^\d{4}-\d{2}-\d{2}$')
                                .hasMatch(trimmed)) {
                              return 'Use YYYY-MM-DD format.';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: d.xs),
                      ResponsiveGrid(
                        minItemWidth: 260,
                        maxColumns: 2,
                        children: [
                          _LabeledEventField(
                            label: 'Start Time (HH:MM:SS)',
                            child: TextFormField(
                              key: const ValueKey<String>(
                                'event-start-time-field',
                              ),
                              controller: _startTimeController,
                              focusNode: _startTimeFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.datetime,
                              forceErrorText: _fieldServerErrors['start_time'],
                              onChanged: (_) {
                                if (_fieldServerErrors
                                    .containsKey('start_time')) {
                                  setState(
                                    () =>
                                        _fieldServerErrors.remove('start_time'),
                                  );
                                }
                              },
                              decoration: _inputDecoration(
                                hintText: '09:00:00',
                                prefixIcon: LucideIcons.clock,
                                suffixIcon: IconButton(
                                  tooltip: 'Pick Start Time',
                                  icon: const Icon(LucideIcons.clock, size: 18),
                                  onPressed: () => _pickTime(
                                    _startTimeController,
                                    'start_time',
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final trimmed = value?.trim() ?? '';
                                if (trimmed.isEmpty) {
                                  return 'Start time required.';
                                }
                                if (!RegExp(r'^\d{2}:\d{2}(:\d{2})?$')
                                    .hasMatch(trimmed)) {
                                  return 'Use HH:MM:SS.';
                                }
                                return null;
                              },
                            ),
                          ),
                          _LabeledEventField(
                            label: 'End Time (HH:MM:SS)',
                            child: TextFormField(
                              key: const ValueKey<String>(
                                'event-end-time-field',
                              ),
                              controller: _endTimeController,
                              focusNode: _endTimeFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.datetime,
                              forceErrorText: _fieldServerErrors['end_time'],
                              onChanged: (_) {
                                if (_fieldServerErrors
                                    .containsKey('end_time')) {
                                  setState(
                                    () => _fieldServerErrors.remove('end_time'),
                                  );
                                }
                              },
                              decoration: _inputDecoration(
                                hintText: '12:00:00',
                                prefixIcon: LucideIcons.clock,
                                suffixIcon: IconButton(
                                  tooltip: 'Pick End Time',
                                  icon: const Icon(LucideIcons.clock, size: 18),
                                  onPressed: () =>
                                      _pickTime(_endTimeController, 'end_time'),
                                ),
                              ),
                              validator: (value) {
                                final trimmed = value?.trim() ?? '';
                                if (trimmed.isEmpty) {
                                  return 'End time required.';
                                }
                                if (!RegExp(r'^\d{2}:\d{2}(:\d{2})?$')
                                    .hasMatch(trimmed)) {
                                  return 'Use HH:MM:SS.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: d.md),

                  // SECTION D: Registration Period
                  _FormSectionCard(
                    header: const SectionHeader(
                      title: 'Registration Period',
                      subtitle:
                          'Configure registration cutoff window, participant capacity, and walk-in rules',
                    ),
                    children: [
                      ResponsiveGrid(
                        minItemWidth: 260,
                        maxColumns: 2,
                        children: [
                          _LabeledEventField(
                            label: 'Registration Start (YYYY-MM-DD HH:MM:SS)',
                            child: TextFormField(
                              key: const ValueKey<String>(
                                'registration-start-field',
                              ),
                              controller: _registrationStartController,
                              focusNode: _registrationStartFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.datetime,
                              forceErrorText:
                                  _fieldServerErrors['registration_start'],
                              onChanged: (_) {
                                if (_fieldServerErrors
                                    .containsKey('registration_start')) {
                                  setState(
                                    () => _fieldServerErrors
                                        .remove('registration_start'),
                                  );
                                }
                              },
                              decoration: _inputDecoration(
                                hintText: '2026-11-01 08:00:00',
                                prefixIcon: LucideIcons.calendarPlus,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Registration start timestamp is required.';
                                }
                                return null;
                              },
                            ),
                          ),
                          _LabeledEventField(
                            label: 'Registration End (YYYY-MM-DD HH:MM:SS)',
                            child: TextFormField(
                              key: const ValueKey<String>(
                                'registration-end-field',
                              ),
                              controller: _registrationEndController,
                              focusNode: _registrationEndFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.datetime,
                              forceErrorText:
                                  _fieldServerErrors['registration_end'],
                              onChanged: (_) {
                                if (_fieldServerErrors
                                    .containsKey('registration_end')) {
                                  setState(
                                    () => _fieldServerErrors
                                        .remove('registration_end'),
                                  );
                                }
                              },
                              decoration: _inputDecoration(
                                hintText: '2026-11-14 23:59:59',
                                prefixIcon: LucideIcons.calendarCheck,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Registration cutoff timestamp is required.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: d.xs),
                      ResponsiveGrid(
                        minItemWidth: 260,
                        maxColumns: 2,
                        children: [
                          _LabeledEventField(
                            label: 'Max Participants (Optional)',
                            child: TextFormField(
                              key: const ValueKey<String>(
                                'max-participants-field',
                              ),
                              controller: _maxParticipantsController,
                              focusNode: _maxParticipantsFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.number,
                              forceErrorText:
                                  _fieldServerErrors['max_participants'],
                              decoration: _inputDecoration(
                                hintText: 'Empty = Unlimited',
                                prefixIcon: LucideIcons.users,
                                helperText: 'Leave blank for unlimited slots',
                              ),
                              validator: (value) {
                                final trimmed = value?.trim() ?? '';
                                if (trimmed.isEmpty) return null;
                                final parsed = int.tryParse(trimmed);
                                if (parsed == null || parsed < 1) {
                                  return 'Enter a whole number ≥ 1.';
                                }
                                return null;
                              },
                            ),
                          ),
                          _LabeledEventField(
                            label: 'Late Grace Period (Mins)',
                            child: TextFormField(
                              key: const ValueKey<String>(
                                'late-grace-period-field',
                              ),
                              controller: _lateGraceController,
                              focusNode: _lateGraceFocus,
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.number,
                              forceErrorText: _fieldServerErrors[
                                  'late_grace_period_minutes'],
                              decoration: _inputDecoration(
                                hintText: '15',
                                prefixIcon: LucideIcons.timer,
                                helperText: '0–120 minutes after start',
                              ),
                              validator: (value) {
                                final trimmed = value?.trim() ?? '';
                                if (trimmed.isEmpty) {
                                  return 'Required.';
                                }
                                final parsed = int.tryParse(trimmed);
                                if (parsed == null ||
                                    parsed < 0 ||
                                    parsed > 120) {
                                  return 'Enter 0 to 120.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: d.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: d.isDark ? d.muted : const Color(0xFFFBFBFA),
                          borderRadius: BorderRadius.circular(d.radiusControl),
                          border: Border.all(
                            color: d.isDark
                                ? d.border
                                : d.authDark.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: SwitchListTile(
                            key: const ValueKey<String>(
                              'walk-in-allowed-switch',
                            ),
                            title: Text(
                              'Allow Walk-In Attendance',
                              style: d.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Permit unregistered students to check in via QR scan at the venue',
                              style: d.supporting,
                            ),
                            value: _walkInAllowed,
                            onChanged: (val) =>
                                setState(() => _walkInAllowed = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: d.md),

                  // SECTION E: Notification Settings
                  _FormSectionCard(
                    header: const SectionHeader(
                      title: 'Notification Settings',
                      subtitle:
                          'Configure announcement dispatch and reminders',
                    ),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: d.isDark ? d.muted : const Color(0xFFFBFBFA),
                          borderRadius: BorderRadius.circular(d.radiusControl),
                          border: Border.all(
                            color: d.isDark
                                ? d.border
                                : d.authDark.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: SwitchListTile(
                            key: const ValueKey<String>(
                              'send-announcement-switch',
                            ),
                            title: Text(
                              'Send announcement notification when published',
                              style: d.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Dispatches push and in-app alerts to matching students upon admin approval',
                              style: d.supporting,
                            ),
                            value: _sendAnnouncement,
                            onChanged: (val) =>
                                setState(() => _sendAnnouncement = val),
                          ),
                        ),
                      ),
                      SizedBox(height: d.sm),
                      Container(
                        padding: EdgeInsets.all(d.sm + 2),
                        decoration: BoxDecoration(
                          color: d.isDark
                              ? d.muted.withValues(alpha: 0.4)
                              : const Color(0xFFF9F9F8),
                          borderRadius: BorderRadius.circular(d.radiusControl),
                          border: Border.all(color: d.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                LucideIcons.info,
                                size: 16,
                                color: d.foreground,
                              ),
                            ),
                            SizedBox(width: d.sm),
                            Expanded(
                              child: Text(
                                'Notifications will only be sent to students matching the selected audience. Event reminders will only be sent to students who actively register.',
                                style: d.supporting.copyWith(
                                  color: d.mutedForeground,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: d.md),

                  // SECTION F: Review & Publish
                  _FormSectionCard(
                    header: const SectionHeader(
                      title: 'Review & Publish',
                      subtitle:
                          'Review event details and select submission action',
                    ),
                    children: [
                      // Live Summary Card
                      Container(
                        key: const ValueKey<String>('live-summary-card'),
                        padding: EdgeInsets.all(d.md),
                        decoration: BoxDecoration(
                          color: d.isDark
                              ? d.card
                              : const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(d.radiusControl),
                          border: Border.all(color: d.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Live Event Summary',
                                  style: d.cardTitle.copyWith(fontSize: 15),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: d.foreground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _selectedCategory.toUpperCase(),
                                    style: TextStyle(
                                      color: d.background,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: d.sm),
                            _SummaryInfoRow(
                              icon: LucideIcons.fileText,
                              text:
                                  'Title: ${_titleController.text.trim().isEmpty ? "Untitled Event" : _titleController.text.trim()}',
                            ),
                            const SizedBox(height: 4),
                            _SummaryInfoRow(
                              icon: LucideIcons.calendar,
                              text:
                                  '${_eventDateController.text.trim()} • ${_startTimeController.text.trim()} - ${_endTimeController.text.trim()}',
                            ),
                            const SizedBox(height: 4),
                            _SummaryInfoRow(
                              icon: LucideIcons.mapPin,
                              text: _venueController.text.trim().isEmpty
                                  ? 'No venue specified'
                                  : _venueController.text.trim(),
                            ),
                            const SizedBox(height: 4),
                            _SummaryInfoRow(
                              icon: LucideIcons.users,
                              text:
                                  'Audience: $_audienceSummaryText',
                            ),
                            const SizedBox(height: 4),
                            _SummaryInfoRow(
                              icon: LucideIcons.ticket,
                              text:
                                  'Capacity: ${_maxParticipantsController.text.trim().isEmpty ? "Unlimited" : "${_maxParticipantsController.text.trim()} attendees"} • Walk-in: ${_walkInAllowed ? "Allowed" : "Disabled"}',
                            ),
                            const SizedBox(height: 4),
                            _SummaryInfoRow(
                              icon: LucideIcons.bell,
                              text:
                                  'Announcement: ${_sendAnnouncement ? "Active on publish" : "Disabled"}',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: d.md),

                      // Form Actions
                      if (_isEditing) ...[
                        AppButton(
                          key: const ValueKey<String>('save-event-button'),
                          pill: true,
                          onPressed: _isSaving || _isSubmittingAction
                              ? null
                              : _saveEvent,
                          isLoading: _isSaving,
                          icon: LucideIcons.save,
                          label: 'Save Event Changes',
                        ),
                        if (_currentStatus == 'draft') ...[
                          SizedBox(height: d.gap),
                          AppButton(
                            key: const ValueKey<String>(
                              'submit-approval-button',
                            ),
                            variant: AppButtonVariant.outline,
                            pill: true,
                            onPressed: _isSaving || _isSubmittingAction
                                ? null
                                : _submitForApproval,
                            isLoading: _isSubmittingAction,
                            icon: LucideIcons.send,
                            label: 'Submit for Admin Approval',
                          ),
                        ],
                      ] else ...[
                        AppButton(
                          key: const ValueKey<String>('submit-event-button'),
                          pill: true,
                          onPressed: _isSaving || _isSubmittingAction
                              ? null
                              : _saveEvent,
                          isLoading: _isSaving && !_isSubmittingAction,
                          icon: LucideIcons.send,
                          label: 'Submit for Approval',
                        ),
                        SizedBox(height: d.gap),
                        AppButton(
                          key: const ValueKey<String>('save-draft-button'),
                          variant: AppButtonVariant.outline,
                          pill: true,
                          onPressed: _isSaving || _isSubmittingAction
                              ? null
                              : () => _saveEvent(saveAsDraft: true),
                          isLoading: _isSubmittingAction,
                          icon: LucideIcons.fileEdit,
                          label: 'Save as Draft',
                        ),
                      ],
                      if (_isEditing && _currentStatus == 'published') ...[
                        SizedBox(height: d.gap),
                        AppButton(
                          key: const ValueKey<String>(
                            'request-cancellation-button',
                          ),
                          variant: AppButtonVariant.destructive,
                          pill: true,
                          onPressed: _isSaving || _isSubmittingAction
                              ? null
                              : _requestCancellation,
                          isLoading: _isSubmittingAction,
                          icon: LucideIcons.ban,
                          label: 'Request Event Cancellation',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudienceScopeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AudienceScopeChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? d.foreground : d.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? d.foreground : d.border,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? d.background : d.foreground,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? d.background : d.foreground,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SummaryInfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 14, color: d.mutedForeground),
        ),
        SizedBox(width: d.xs + 2),
        Expanded(
          child: Text(
            text,
            style: d.supporting.copyWith(
              color: d.foreground,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormSectionCard extends StatelessWidget {
  final Widget header;
  final List<Widget> children;

  const _FormSectionCard({
    required this.header,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          SizedBox(height: d.md),
          ...children,
        ],
      ),
    );
  }
}

class _LabeledEventField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledEventField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: d.supporting.copyWith(
            color: d.foreground,
            fontWeight: FontWeight.w600,
          ),
          softWrap: true,
        ),
        SizedBox(height: d.xs),
        child,
      ],
    );
  }
}

class _EventStatusBanner extends StatelessWidget {
  final String status;

  const _EventStatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final d = context.design;
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
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: d.sm,
        runSpacing: d.sm,
        children: [
          Text(
            'Current Lifecycle Status',
            style: d.cardTitle,
          ),
          StatusBadge(status: status),
        ],
      ),
    );
  }
}

class _RequestCancellationDialog extends StatefulWidget {
  const _RequestCancellationDialog();

  @override
  State<_RequestCancellationDialog> createState() =>
      _RequestCancellationDialogState();
}

class _RequestCancellationDialogState
    extends State<_RequestCancellationDialog> {
  final GlobalKey<FormState> _dialogFormKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController = TextEditingController();
  late final FocusNode _reasonFocus = FocusNode();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _reasonController.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final invalid = _dialogFormKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      _reasonFocus.requestFocus();
      return;
    }
    _dialogFormKey.currentState!.save();
    Navigator.pop(context, _reasonController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(d.radiusOverlay),
        side: BorderSide(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
        ),
      ),
      backgroundColor: d.card,
      title: const Text('Request Event Cancellation'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: FocusTraversalGroup(
          child: AutofillGroup(
            child: Form(
              key: _dialogFormKey,
              autovalidateMode: _autovalidateMode,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Provide a mandatory justification for cancelling this published event. An administrator will review your request.',
                      style: d.supporting,
                    ),
                    SizedBox(height: d.md),
                    Text(
                      'Cancellation Reason',
                      style: d.supporting.copyWith(
                        color: d.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: d.xs),
                    TextFormField(
                      key: const ValueKey<String>('cancellation-reason-field'),
                      controller: _reasonController,
                      focusNode: _reasonFocus,
                      autofocus: true,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      autofillHints: const [AutofillHints.name],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        hintText: 'Explain why this event must be cancelled',
                        helperText: ' ',
                        errorMaxLines: 3,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 5) {
                          return 'Please enter at least 5 characters.';
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: d.destructive,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
          ),
          onPressed: _submit,
          child: const Text('Submit Request'),
        ),
      ],
    );
  }
}
