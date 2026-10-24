import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/event_model.dart';

class EventDetailScreen extends StatefulWidget {
  final int? eventId;
  final EventModel? event;
  final EventModel? initialEvent;
  final String? initialErrorMessage;

  const EventDetailScreen({
    super.key,
    this.eventId,
    this.event,
    this.initialEvent,
    this.initialErrorMessage,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  EventModel? _event;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _hasFixtureData =>
      widget.initialEvent != null || widget.initialErrorMessage != null;

  int get _resolvedEventId =>
      widget.eventId ??
      _event?.id ??
      widget.initialEvent?.id ??
      widget.event?.id ??
      0;

  @override
  void initState() {
    super.initState();
    _event = widget.initialEvent ?? widget.event;
    _errorMessage = widget.initialErrorMessage;
    if (_hasFixtureData) {
      _isLoading = false;
    } else if (_event != null) {
      _isLoading = false;
      _refreshEventDetails();
    } else {
      _isLoading = true;
      _refreshEventDetails();
    }
  }

  @override
  void didUpdateWidget(covariant EventDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialEvent != oldWidget.initialEvent ||
        widget.event != oldWidget.event ||
        widget.initialErrorMessage != oldWidget.initialErrorMessage) {
      _event = widget.initialEvent ?? widget.event;
      _errorMessage = widget.initialErrorMessage;
      if (_hasFixtureData) {
        _isLoading = false;
      }
    }
  }

  Future<void> _refreshEventDetails() async {
    if (_hasFixtureData && widget.initialEvent != null) {
      setState(() {
        _event = widget.initialEvent;
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }

    final id = _resolvedEventId;
    if (id <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage ??= 'Unable to load event details.';
      });
      return;
    }

    if (_event == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final response = await ApiClient().get(ApiConstants.eventDetail(id));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (response.success && response.data is Map) {
        _event = EventModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        _errorMessage = null;
      } else if (_event == null) {
        _errorMessage = response.message ?? 'Unable to load event details.';
      }
    });
  }

  Future<void> _handleRegister() async {
    final event = _event;
    if (event == null) return;

    setState(() => _isSubmitting = true);
    final response =
        await ApiClient().post(ApiConstants.registerEvent(event.id), {});
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response.success) {
      await _refreshEventDetails();
      if (!mounted) return;
      AppToast.success(
        context,
        response.message ?? 'Registration successful!',
      );
    } else {
      AppToast.error(
        context,
        response.message ?? 'Registration failed.',
      );
    }
  }

  Future<void> _handleCancelRegistration() async {
    final event = _event;
    if (event == null) return;
    final d = context.design;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Cancel Registration?'),
        content: const Text(
          'Are you sure you want to cancel your registration for this event? Your slot will be given to the next student on the waiting list.',
        ),
        actions: [
          OutlinedButton(
            key: const ValueKey('cancel-dialog-keep-button'),
            style: OutlinedButton.styleFrom(
              foregroundColor: d.foreground,
              backgroundColor: d.card,
              side: BorderSide(color: d.border, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(d.radiusControl),
              ),
              padding: EdgeInsets.symmetric(horizontal: d.md, vertical: 10),
            ),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Registration'),
          ),
          ElevatedButton(
            key: const ValueKey('cancel-dialog-confirm-button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: d.destructive,
              foregroundColor: d.destructiveForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(d.radiusControl),
              ),
              padding: EdgeInsets.symmetric(horizontal: d.md, vertical: 10),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Slot'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    final response =
        await ApiClient().delete(ApiConstants.cancelRegistration(event.id));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response.success) {
      await _refreshEventDetails();
      if (!mounted) return;
      AppToast.info(
        context,
        'Your registration has been cancelled.',
      );
    } else {
      AppToast.error(
        context,
        response.message ?? 'Cancellation failed.',
      );
    }
  }

  Widget _buildMainDetails(BuildContext context, EventModel event) {
    final d = context.design;
    return Column(
      key: const ValueKey('event-detail-main-pane'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
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
                    LucideIcons.calendar,
                    size: 18,
                    color: d.primary,
                  ),
                  SizedBox(width: d.sm),
                  Expanded(
                    child: Text(
                      event.title,
                      style:
                          d.sectionTitle.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(width: d.sm),
                  StatusBadge(status: event.status),
                ],
              ),
              SizedBox(height: d.gap),
              _EventInfoRow(
                icon: LucideIcons.mapPin,
                text: event.venue,
              ),
              SizedBox(height: d.sm),
              _EventInfoRow(
                icon: LucideIcons.calendar,
                text:
                    '${event.eventDate} • ${event.startTime} - ${event.endTime}',
              ),
              SizedBox(height: d.sm),
              _EventInfoRow(
                icon: LucideIcons.clock,
                text: 'Late check-in after ${event.lateGracePeriodMinutes} mins',
              ),
            ],
          ),
        ),
        SizedBox(height: d.md),
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
              const SectionHeader(title: 'About'),
              SizedBox(height: d.sm),
              Text(
                event.description,
                style: d.body,
              ),
              if (event.walkInAllowed) ...[
                SizedBox(height: d.gap),
                _EventInfoRow(
                  icon: LucideIcons.circleCheck,
                  iconColor: d.primary,
                  text: 'Walk-ins allowed',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionPane(BuildContext context, EventModel event) {
    final d = context.design;
    final remaining = event.remainingSlots;
    final isFull = remaining != null && remaining <= 0;
    final statusNormalized = event.status.trim().toLowerCase();
    final isCancelled = statusNormalized == 'cancelled';
    final isCompleted = statusNormalized == 'completed';

    return Container(
      key: const ValueKey('event-detail-action-pane'),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionHeader(title: 'Registration'),
          SizedBox(height: d.gap),
          Text('Available Slots', style: d.supporting),
          const SizedBox(height: 2),
          Text(
            remaining == null
                ? 'Unlimited Slots'
                : isFull
                    ? '0 slots left (Full)'
                    : '$remaining slots left',
            style: d.cardTitle.copyWith(
              color: isFull ? d.warning : d.success,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: d.xs),
          Text(
            'Registered: ${event.currentRegisteredCount}${event.maxParticipants != null ? ' / ${event.maxParticipants}' : ''}',
            style: d.supporting,
          ),
          if (event.userRegistrationStatus != null) ...[
            Divider(height: d.lg, color: d.authDark.withValues(alpha: 0.08)),
            Text('Your Status', style: d.supporting),
            SizedBox(height: d.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(
                status: event.userRegistrationStatus!,
                label: event.isRegistered
                    ? 'REGISTERED'
                    : event.isWaitingList
                        ? 'WAITING LIST #${event.userWaitingPosition ?? 1}'
                        : null,
              ),
            ),
            SizedBox(height: d.xs),
            Text(
              event.isRegistered
                  ? 'Your slot is confirmed.'
                  : event.isWaitingList
                      ? 'Queue position #${event.userWaitingPosition ?? 1}. Promoted automatically if a slot opens.'
                      : 'Registration cancelled.',
              style: d.supporting,
            ),
          ],
          Divider(height: d.lg, color: d.authDark.withValues(alpha: 0.08)),
          if (event.isRegistered || event.isWaitingList) ...[
            AppButton(
              key: const ValueKey('cancel-registration-button'),
              variant: AppButtonVariant.destructive,
              pill: true,
              icon: LucideIcons.xCircle,
              isLoading: _isSubmitting,
              onPressed: (isCancelled || isCompleted)
                  ? null
                  : _handleCancelRegistration,
              label: 'Cancel My Registration',
            ),
          ] else if (isCancelled) ...[
            Text(
              'Registration is closed because this event has been cancelled.',
              style: d.supporting.copyWith(color: d.destructive),
            ),
            SizedBox(height: d.sm),
            const AppButton(
              key: ValueKey('register-event-button'),
              variant: AppButtonVariant.outline,
              pill: true,
              icon: LucideIcons.ban,
              onPressed: null,
              label: 'Event Cancelled',
            ),
          ] else if (isCompleted) ...[
            Text(
              'Registration is closed because this event has been completed.',
              style: d.supporting,
            ),
            SizedBox(height: d.sm),
            const AppButton(
              key: ValueKey('register-event-button'),
              variant: AppButtonVariant.outline,
              pill: true,
              icon: LucideIcons.checkCheck,
              onPressed: null,
              label: 'Event Completed',
            ),
          ] else ...[
            if (isFull) ...[
              Text(
                'Event capacity is full. Joining the waiting list places you in queue for automatic promotion.',
                style: d.supporting,
              ),
              SizedBox(height: d.sm),
            ],
            AppButton(
              key: const ValueKey('register-event-button'),
              variant: AppButtonVariant.primary,
              pill: true,
              icon: isFull ? LucideIcons.listOrdered : LucideIcons.userCheck,
              isLoading: _isSubmitting,
              onPressed: _handleRegister,
              label: isFull ? 'Join Waiting List' : 'Register for Event',
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final event = _event;

    return AppPageScaffold(
      title: event?.title ?? 'Event Details',
      body: _isLoading && event == null
          ? Center(
              child: AppSpinner(
                size: 28,
                color: d.authDark,
              ),
            )
          : _errorMessage != null && event == null
              ? ErrorStateView(
                  message: _errorMessage!,
                  onRetry: _refreshEventDetails,
                )
              : event == null
                  ? ErrorStateView(
                      message: 'Event details are unavailable.',
                      onRetry: _refreshEventDetails,
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final textScale =
                            MediaQuery.textScalerOf(context).scale(1);
                        final useSidePane =
                            constraints.maxWidth >= 960 && textScale < 1.5;

                        if (useSidePane) {
                          return SingleChildScrollView(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildMainDetails(context, event),
                                ),
                                SizedBox(width: d.lg),
                                SizedBox(
                                  width: 320,
                                  child: _buildActionPane(context, event),
                                ),
                              ],
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildMainDetails(context, event),
                              SizedBox(height: d.md),
                              _buildActionPane(context, event),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

class _EventInfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String text;

  const _EventInfoRow({
    required this.icon,
    this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: iconColor ?? d.primary),
        SizedBox(width: d.sm),
        Expanded(
          child: Text(
            text,
            style: d.body,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
