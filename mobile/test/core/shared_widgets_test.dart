import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/core/widgets/empty_state_view.dart';
import 'package:school_event_attendance/core/widgets/error_state_view.dart';
import 'package:school_event_attendance/core/widgets/event_card.dart';
import 'package:school_event_attendance/core/widgets/section_header.dart';
import 'package:school_event_attendance/core/widgets/stat_metric_card.dart';
import 'package:school_event_attendance/core/widgets/status_badge.dart';
import 'package:school_event_attendance/models/event_model.dart';
import '../support/app_test_host.dart';

void main() {
  testWidgets(
    'shared widgets render at 320x568 and 844x390 at 2x text without overflow or nested buttons',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var cardTapped = 0;
      var trailingTapped = 0;
      var retried = 0;

      final event = EventModel(
        id: 99,
        title:
            'Annual Institutional Cybersecurity and Artificial Intelligence Systems Engineering Colloquium 2026',
        description: 'Long event description for testing wrapping behavior.',
        venue:
            'Main University Amphitheater and Graduate Research Complex Room 402B',
        eventDate: '2026-11-18',
        startTime: '08:30:00',
        endTime: '17:00:00',
        maxParticipants: 250,
        remainingSlots: 12,
        currentRegisteredCount: 238,
        lateGracePeriodMinutes: 15,
        walkInAllowed: true,
        status: 'published',
        userRegistrationStatus: 'waiting_list',
        userWaitingPosition: 4,
      );

      for (final size in [const Size(320, 568), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          AppTestHost(
            child: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(2),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(
                        title: 'Campus Events and Registration Overview',
                        subtitle: 'Browse upcoming institutional activities',
                        actionLabel: 'Refresh All',
                        onAction: () {},
                      ),
                      const SizedBox(height: 12),
                      const StatMetricCard(
                        label: 'Total Registered Events This Semester',
                        value: '18',
                        icon: Icons.event_available,
                        subtitle: 'Including 2 waiting list entries',
                      ),
                      const SizedBox(height: 12),
                      const StatusBadge(status: 'pending_approval'),
                      const SizedBox(height: 12),
                      EventCard(
                        event: event,
                        showCapacity: true,
                        onTap: () => cardTapped++,
                        trailingAction: TextButton(
                          onPressed: () => trailingTapped++,
                          child: const Text('Manage'),
                        ),
                      ),
                      SizedBox(
                        height: 360,
                        child: ErrorStateView(
                          message:
                              'Unable to synchronize latest event registrations due to temporary network timeout.',
                          onRetry: () => retried++,
                        ),
                      ),
                      const SizedBox(
                        height: 360,
                        child: EmptyStateView(
                          title: 'No matching events found',
                          message:
                              'Try clearing your search query or selecting another status filter.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'size $size');
        expect(find.text('NOV'), findsOneWidget);
        expect(find.text('18'), findsWidgets);
        expect(find.text('WAITING #4'), findsOneWidget);
      }

      // Verify independent trailing action does not trigger card tap
      await tester.ensureVisible(find.text('Manage'));
      await tester.tap(find.text('Manage'));
      await tester.pump();
      expect(trailingTapped, 1);
      expect(cardTapped, 0);
    },
  );
}
