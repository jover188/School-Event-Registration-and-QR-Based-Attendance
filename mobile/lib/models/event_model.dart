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

  final String category;
  final String? coverImagePath;
  final String targetAudienceType;
  final List<String> targetCourses;
  final List<String> targetYearLevels;
  final List<String> targetSections;
  final List<Map<String, dynamic>> targetRules;
  final bool sendAnnouncement;

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
    this.category = 'General',
    this.coverImagePath,
    this.targetAudienceType = 'all',
    this.targetCourses = const [],
    this.targetYearLevels = const [],
    this.targetSections = const [],
    this.targetRules = const [],
    this.sendAnnouncement = true,
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
      walkInAllowed:
          json['walk_in_allowed'] == true || json['walk_in_allowed'] == 1,
      status: json['status'] ?? 'published',
      userRegistrationStatus: json['user_registration_status'],
      userWaitingPosition: json['user_waiting_position'],
      category: json['category'] ?? 'General',
      coverImagePath: json['cover_image_path'],
      targetAudienceType: json['target_audience_type'] ?? 'all',
      targetCourses: (json['target_courses'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      targetYearLevels: (json['target_year_levels'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      targetSections: (json['target_sections'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      targetRules: (json['target_rules'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      sendAnnouncement: json['send_announcement'] == null
          ? true
          : (json['send_announcement'] == true ||
              json['send_announcement'] == 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'venue': venue,
      'event_date': eventDate,
      'start_time': startTime,
      'end_time': endTime,
      'max_participants': maxParticipants,
      'remaining_slots': remainingSlots,
      'current_registered_count': currentRegisteredCount,
      'late_grace_period_minutes': lateGracePeriodMinutes,
      'walk_in_allowed': walkInAllowed,
      'status': status,
      if (userRegistrationStatus != null)
        'user_registration_status': userRegistrationStatus,
      if (userWaitingPosition != null)
        'user_waiting_position': userWaitingPosition,
      'category': category,
      if (coverImagePath != null) 'cover_image_path': coverImagePath,
      'target_audience_type': targetAudienceType,
      'target_courses': targetCourses,
      'target_year_levels': targetYearLevels,
      'target_sections': targetSections,
      'target_rules': targetRules,
      'send_announcement': sendAnnouncement,
    };
  }

  bool get isRegistered => userRegistrationStatus == 'registered';
  bool get isWaitingList => userRegistrationStatus == 'waiting_list';

  DateTime? get startDateTime {
    if (eventDate.isEmpty || startTime.isEmpty) return null;
    try {
      final dateClean = eventDate.split('T').first.trim();
      final timeClean = startTime.trim();
      final timeParts = timeClean.split(':');
      final hour = timeParts.isNotEmpty ? (int.tryParse(timeParts[0]) ?? 0) : 0;
      final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
      final second = timeParts.length > 2 ? (int.tryParse(timeParts[2].split('.').first) ?? 0) : 0;

      final parsedDate = DateTime.tryParse(dateClean);
      if (parsedDate != null) {
        return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute, second);
      }
      return DateTime.tryParse('${dateClean}T$timeClean');
    } catch (_) {
      return null;
    }
  }

  DateTime? get endDateTime {
    if (eventDate.isEmpty || endTime.isEmpty) return null;
    try {
      final dateClean = eventDate.split('T').first.trim();
      final timeClean = endTime.trim();
      final timeParts = timeClean.split(':');
      final hour = timeParts.isNotEmpty ? (int.tryParse(timeParts[0]) ?? 0) : 0;
      final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
      final second = timeParts.length > 2 ? (int.tryParse(timeParts[2].split('.').first) ?? 0) : 0;

      final parsedDate = DateTime.tryParse(dateClean);
      if (parsedDate != null) {
        return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute, second);
      }
      return DateTime.tryParse('${dateClean}T$timeClean');
    } catch (_) {
      return null;
    }
  }

  bool get isEnded {
    final s = status.trim().toLowerCase();
    if (s == 'completed' || s == 'ended') return true;
    final end = endDateTime;
    if (end != null) {
      return DateTime.now().isAfter(end) || DateTime.now().isAtSameMomentAs(end);
    }
    return false;
  }

  String get audienceSummary {
    if (targetAudienceType == 'course') {
      return targetCourses.isEmpty
          ? 'Specific Courses'
          : 'Course: ${targetCourses.join(", ")}';
    } else if (targetAudienceType == 'year_level') {
      return targetYearLevels.isEmpty
          ? 'Specific Year Levels'
          : 'Year: ${targetYearLevels.join(", ")}';
    } else if (targetAudienceType == 'custom') {
      if (targetRules.isNotEmpty) {
        final rulesFormatted = targetRules
            .map((r) {
              final c = r['course']?.toString() ?? '';
              final y = r['year_level']?.toString() ?? '';
              if (c.isNotEmpty && y.isNotEmpty) return '$c ($y)';
              return c.isNotEmpty ? c : y;
            })
            .where((s) => s.isNotEmpty)
            .join(', ');
        if (rulesFormatted.isNotEmpty) return rulesFormatted;
      }
      final parts = <String>[];
      if (targetCourses.isNotEmpty) parts.add(targetCourses.join(', '));
      if (targetYearLevels.isNotEmpty) parts.add(targetYearLevels.join(', '));
      return parts.isEmpty ? 'Custom Audience' : parts.join(' · ');
    }
    return 'All Students';
  }
}
