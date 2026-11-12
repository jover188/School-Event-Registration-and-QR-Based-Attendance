import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/models/event_model.dart';

void main() {
  group('EventModel audience targeting & category', () {
    test('defaults are applied when fields are omitted', () {
      final event = EventModel(
        id: 1,
        title: 'Tech Summit',
        description: 'Annual gathering',
        venue: 'Auditorium',
        eventDate: '2026-11-20',
        startTime: '09:00:00',
        endTime: '12:00:00',
        currentRegisteredCount: 0,
        lateGracePeriodMinutes: 15,
        walkInAllowed: false,
        status: 'published',
      );

      expect(event.category, 'General');
      expect(event.coverImagePath, isNull);
      expect(event.targetAudienceType, 'all');
      expect(event.targetCourses, isEmpty);
      expect(event.targetYearLevels, isEmpty);
      expect(event.targetSections, isEmpty);
      expect(event.targetRules, isEmpty);
      expect(event.sendAnnouncement, isTrue);
      expect(event.audienceSummary, 'All Students');
    });

    test('fromJson deserializes audience fields correctly', () {
      final json = {
        'id': 10,
        'title': 'Coding Workshop',
        'description': 'Hands-on Flutter',
        'venue': 'Lab 3',
        'event_date': '2026-11-25',
        'start_time': '13:00:00',
        'end_time': '16:00:00',
        'category': 'Workshop',
        'cover_image_path': 'https://example.com/cover.png',
        'target_audience_type': 'course',
        'target_courses': ['BSIT', 'BSCS'],
        'target_year_levels': ['2nd Year'],
        'target_sections': ['Section A'],
        'target_rules': [
          {'course': 'BSIT', 'year_level': '2nd Year'}
        ],
        'send_announcement': false,
        'current_registered_count': 12,
        'late_grace_period_minutes': 20,
        'walk_in_allowed': 1,
        'status': 'published',
      };

      final event = EventModel.fromJson(json);

      expect(event.category, 'Workshop');
      expect(event.coverImagePath, 'https://example.com/cover.png');
      expect(event.targetAudienceType, 'course');
      expect(event.targetCourses, ['BSIT', 'BSCS']);
      expect(event.targetYearLevels, ['2nd Year']);
      expect(event.targetSections, ['Section A']);
      expect(event.targetRules, [
        {'course': 'BSIT', 'year_level': '2nd Year'}
      ]);
      expect(event.sendAnnouncement, isFalse);
      expect(event.walkInAllowed, isTrue);
      expect(event.audienceSummary, 'Course: BSIT, BSCS');
    });

    test('toJson serializes all fields properly', () {
      final event = EventModel(
        id: 5,
        title: 'Leadership Seminar',
        description: 'For student leaders',
        venue: 'Function Hall',
        eventDate: '2026-12-01',
        startTime: '10:00:00',
        endTime: '15:00:00',
        maxParticipants: 50,
        remainingSlots: 20,
        currentRegisteredCount: 30,
        lateGracePeriodMinutes: 10,
        walkInAllowed: true,
        status: 'pending_approval',
        category: 'Seminar',
        coverImagePath: '/images/seminar.jpg',
        targetAudienceType: 'custom',
        targetCourses: ['BSBA'],
        targetYearLevels: ['3rd Year', '4th Year'],
        targetSections: const [],
        targetRules: [
          {'course': 'BSBA', 'year_level': '3rd Year'},
          {'course': 'BSBA', 'year_level': '4th Year'},
        ],
        sendAnnouncement: true,
      );

      final json = event.toJson();

      expect(json['title'], 'Leadership Seminar');
      expect(json['category'], 'Seminar');
      expect(json['cover_image_path'], '/images/seminar.jpg');
      expect(json['target_audience_type'], 'custom');
      expect(json['target_courses'], ['BSBA']);
      expect(json['target_year_levels'], ['3rd Year', '4th Year']);
      expect(json['target_rules'], [
        {'course': 'BSBA', 'year_level': '3rd Year'},
        {'course': 'BSBA', 'year_level': '4th Year'},
      ]);
      expect(json['send_announcement'], isTrue);
      expect(json['max_participants'], 50);
      expect(json['walk_in_allowed'], isTrue);
      expect(event.audienceSummary, 'BSBA (3rd Year), BSBA (4th Year)');
    });

    test('audienceSummary formats year_level correctly', () {
      final event = EventModel(
        id: 7,
        title: 'Freshmen Orientation',
        description: 'Welcome',
        venue: 'Gym',
        eventDate: '2026-11-15',
        startTime: '08:00:00',
        endTime: '12:00:00',
        currentRegisteredCount: 0,
        lateGracePeriodMinutes: 15,
        walkInAllowed: true,
        status: 'published',
        targetAudienceType: 'year_level',
        targetYearLevels: ['1st Year'],
      );

      expect(event.audienceSummary, 'Year: 1st Year');
    });
  });
}
