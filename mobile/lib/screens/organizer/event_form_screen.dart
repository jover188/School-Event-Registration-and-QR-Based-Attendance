import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
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

    if (_isEditing) {
      _loadExistingEventDetails();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
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
    final cleaned = raw.replaceAll('T', ' ').split('.').first.trim();
    return cleaned;
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

  Future<void> _saveEvent() async {
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
      'venue': _venueController.text.trim(),
      'event_date': _eventDateController.text.trim(),
      'start_time': _startTimeController.text.trim(),
      'end_time': _endTimeController.text.trim(),
      'registration_start': _registrationStartController.text.trim(),
      'registration_end': _registrationEndController.text.trim(),
      'max_participants': maxCap,
      'late_grace_period_minutes': graceMinutes,
      'walk_in_allowed': _walkInAllowed,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(
            response.message ??
                (_isEditing
                    ? 'Event updated successfully.'
                    : 'Event draft created successfully.'),
          ),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(response.message ?? 'Failed to save event.'),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(
            response.message ??
                'Event submitted for administrator review and approval.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(
            response.message ?? 'Failed to submit event for approval.',
          ),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.late,
          content: Text(
            response.message ??
                'Cancellation request recorded. Awaiting administrator approval.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(
            response.message ?? 'Failed to request event cancellation.',
          ),
        ),
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

                  // Section 1: Event Details
                  _FormSectionCard(
                    header: const SectionHeader(
                      title: 'Event Details',
                      subtitle:
                          'Provide official event title, description, and venue',
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
                          autofillHints: const [AutofillHints.name],
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
                                'Describe the agenda, speakers, and target participants',
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
                      _LabeledEventField(
                        label: 'Venue',
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

                  // Section 2: Schedule & Registration Window
                  _FormSectionCard(
                    header: const SectionHeader(
                      title: 'Schedule & Registration Window',
                      subtitle:
                          'Configure event date, start/end times, and cutoff window',
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
                          autofillHints: const [AutofillHints.birthday],
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
                              autofillHints: const [AutofillHints.name],
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
                              autofillHints: const [AutofillHints.name],
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
                      SizedBox(height: d.xs),
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
                              autofillHints: const [AutofillHints.name],
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
                              autofillHints: const [AutofillHints.name],
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
                    ],
                  ),
                  SizedBox(height: d.md),

                  // Section 3: Capacity & Attendance Rules
                  _FormSectionCard(
                    header: const SectionHeader(
                      title: 'Capacity & Attendance Rules',
                      subtitle:
                          'Configure participant cap, late grace period, and walk-in rules',
                    ),
                    children: [
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
                              autofillHints: const [AutofillHints.name],
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
                              autofillHints: const [AutofillHints.name],
                              forceErrorText: _fieldServerErrors[
                                  'late_grace_period_minutes'],
                              onFieldSubmitted: (_) => _saveEvent(),
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
                  SizedBox(height: d.lg),

                  // Action Buttons
                  AppButton(
                    key: const ValueKey<String>('save-event-button'),
                    pill: true,
                    onPressed:
                        _isSaving || _isSubmittingAction ? null : _saveEvent,
                    isLoading: _isSaving,
                    icon: _isEditing ? LucideIcons.save : LucideIcons.plus,
                    label: _isEditing
                        ? 'Save Event Changes'
                        : 'Create Event Draft',
                  ),
                  if (_isEditing && _currentStatus == 'draft') ...[
                    SizedBox(height: d.gap),
                    AppButton(
                      key: const ValueKey<String>('submit-approval-button'),
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
            ),
          ),
        ),
      ),
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
        Wrap(
          spacing: d.sm,
          runSpacing: d.sm,
          alignment: WrapAlignment.end,
          children: [
            AppButton(
              size: AppButtonSize.compact,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
              label: 'Back',
            ),
            AppButton(
              size: AppButtonSize.compact,
              variant: AppButtonVariant.destructive,
              onPressed: _submit,
              label: 'Submit Request',
            ),
          ],
        ),
      ],
    );
  }
}
