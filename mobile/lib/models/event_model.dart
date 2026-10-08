class EventModel {
  final int id;
  final String title;
  final String description;
  final String venue;
  final String eventDate;
  final String startTime;
  final String endTime;
  final int? maxParticipants;
  final int? remainingSlots;
  final int currentRegisteredCount;
  final int lateGracePeriodMinutes;
  final bool walkInAllowed;
  final String status;
  final String? userRegistrationStatus;
  final int? userWaitingPosition;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    this.maxParticipants,
    this.remainingSlots,
    required this.currentRegisteredCount,
    required this.lateGracePeriodMinutes,
    required this.walkInAllowed,
    required this.status,
    this.userRegistrationStatus,
    this.userWaitingPosition,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      venue: json['venue'] ?? '',
      eventDate: json['event_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      maxParticipants: json['max_participants'],
      remainingSlots: json['remaining_slots'],
      currentRegisteredCount: json['current_registered_count'] ?? 0,
      lateGracePeriodMinutes: json['late_grace_period_minutes'] ?? 15,
      walkInAllowed: json['walk_in_allowed'] == true || json['walk_in_allowed'] == 1,
      status: json['status'] ?? 'published',
      userRegistrationStatus: json['user_registration_status'],
      userWaitingPosition: json['user_waiting_position'],
    );
  }

  bool get isRegistered => userRegistrationStatus == 'registered';
  bool get isWaitingList => userRegistrationStatus == 'waiting_list';
}
