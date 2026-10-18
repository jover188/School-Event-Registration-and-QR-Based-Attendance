<?php

namespace Database\Seeders;

use App\Models\ActivityLog;
use App\Models\Attendance;
use App\Models\AttendanceCorrection;
use App\Models\Event;
use App\Models\EventApproval;
use App\Models\EventRegistration;
use App\Models\Notification;
use App\Models\Student;
use App\Models\User;
use Illuminate\Database\Seeder;

class DemoSchoolDataSeeder extends Seeder
{
    /**
     * Seed realistic school events, approvals, registrations, waiting lists,
     * QR attendance scans, manual corrections, notifications, and activity logs.
     *
     * Designed for offline/demo environments where live school database APIs
     * are not yet connected. Safe to run repeatedly (idempotent).
     */
    public function run(): void
    {
        if (User::where('email', 'sisa.mercado@school.edu')->doesntExist()) {
            $this->call([
                RoleSeeder::class,
                UserSeeder::class,
            ]);
        }

        $admin = User::where('email', 'admin@school.edu')->firstOrFail();
        $organizer = User::where('email', 'organizer@school.edu')->firstOrFail();
        $coOrganizer = User::where('email', 'cs.council@school.edu')->first() ?? $organizer;
        $management = User::where('email', 'management@school.edu')->firstOrFail();

        $students = Student::with('user')
            ->get()
            ->keyBy('student_id_number');

        $juan = $students->get('20260001');
        $maria = $students->get('20269001');
        $ibarra = $students->get('20269002');
        $elias = $students->get('20269003');
        $sisa = $students->get('20269004');
        $basilio = $students->get('20269005');
        $isagani = $students->get('20269006');
        $paulita = $students->get('20269007');
        $simoun = $students->get('20269008');

        $today = now()->toDateString();

        // =====================================================================
        // 1. ONGOING EVENT (Today — active for live QR scanning & attendance)
        // =====================================================================
        $ongoingEvent = Event::updateOrCreate(
            ['title' => 'Annual Cybersecurity & Cloud Computing Summit 2026'],
            [
                'organizer_id' => $organizer->id,
                'description' => 'Institution-wide technical symposium on zero-trust architecture, cloud security, and student capstone showcases.',
                'venue' => 'Main University Auditorium',
                'event_date' => $today,
                'start_time' => '08:00:00',
                'end_time' => '17:00:00',
                'registration_start' => now()->subDays(10),
                'registration_end' => now()->addHours(6),
                'max_participants' => 50,
                'late_grace_period_minutes' => 15,
                'walk_in_allowed' => true,
                'status' => 'ongoing',
            ]
        );

        EventApproval::updateOrCreate(
            [
                'event_id' => $ongoingEvent->id,
                'approval_type' => 'publish',
            ],
            [
                'admin_id' => $admin->id,
                'status' => 'approved',
                'remarks' => 'Approved for campus-wide publication. Security and venue capacity verified.',
            ]
        );

        // Registrations & live attendance on Ongoing Event
        if ($juan) {
            $regJuanOngoing = EventRegistration::updateOrCreate(
                ['event_id' => $ongoingEvent->id, 'student_id' => $juan->id],
                [
                    'status' => 'registered',
                    'waiting_list_position' => null,
                    'registered_at' => now()->subDays(4),
                ]
            );
            Attendance::updateOrCreate(
                ['event_id' => $ongoingEvent->id, 'student_id' => $juan->id],
                [
                    'event_registration_id' => $regJuanOngoing->id,
                    'check_in_time' => now()->setTime(8, 5, 0),
                    'check_out_time' => null,
                    'status' => 'present',
                    'scanner_id' => $organizer->id,
                ]
            );
        }

        if ($maria) {
            $regMariaOngoing = EventRegistration::updateOrCreate(
                ['event_id' => $ongoingEvent->id, 'student_id' => $maria->id],
                [
                    'status' => 'registered',
                    'waiting_list_position' => null,
                    'registered_at' => now()->subDays(3),
                ]
            );
            Attendance::updateOrCreate(
                ['event_id' => $ongoingEvent->id, 'student_id' => $maria->id],
                [
                    'event_registration_id' => $regMariaOngoing->id,
                    'check_in_time' => now()->setTime(8, 28, 0),
                    'check_out_time' => null,
                    'status' => 'late',
                    'scanner_id' => $organizer->id,
                ]
            );
        }

        if ($ibarra) {
            $regIbarraOngoing = EventRegistration::updateOrCreate(
                ['event_id' => $ongoingEvent->id, 'student_id' => $ibarra->id],
                [
                    'status' => 'walk_in',
                    'waiting_list_position' => null,
                    'registered_at' => now()->setTime(8, 40, 0),
                ]
            );
            Attendance::updateOrCreate(
                ['event_id' => $ongoingEvent->id, 'student_id' => $ibarra->id],
                [
                    'event_registration_id' => $regIbarraOngoing->id,
                    'check_in_time' => now()->setTime(8, 40, 0),
                    'check_out_time' => null,
                    'status' => 'walk_in',
                    'scanner_id' => $organizer->id,
                ]
            );
        }

        // Registered students not yet checked in on Ongoing Event (ready to be scanned via QR!)
        foreach ([$elias, $sisa, $basilio] as $idx => $pendingStudent) {
            if (! $pendingStudent) {
                continue;
            }
            EventRegistration::updateOrCreate(
                ['event_id' => $ongoingEvent->id, 'student_id' => $pendingStudent->id],
                [
                    'status' => 'registered',
                    'waiting_list_position' => null,
                    'registered_at' => now()->subDays(2)->addHours($idx),
                ]
            );
        }

        // =====================================================================
        // 2. PUBLISHED EVENT (Upcoming in 5 days — Juan is registered)
        // =====================================================================
        $upcomingRegisteredEvent = Event::updateOrCreate(
            ['title' => 'Campus AI & Robotics Innovation Expo'],
            [
                'organizer_id' => $organizer->id,
                'description' => 'Hands-on exhibition of embedded robotics, autonomous rovers, and applied machine learning projects across engineering and computer studies.',
                'venue' => 'Engineering Innovation Hall',
                'event_date' => now()->addDays(5)->toDateString(),
                'start_time' => '09:00:00',
                'end_time' => '16:00:00',
                'registration_start' => now()->subDays(5),
                'registration_end' => now()->addDays(4),
                'max_participants' => 40,
                'late_grace_period_minutes' => 15,
                'walk_in_allowed' => true,
                'status' => 'published',
            ]
        );

        EventApproval::updateOrCreate(
            [
                'event_id' => $upcomingRegisteredEvent->id,
                'approval_type' => 'publish',
            ],
            [
                'admin_id' => $admin->id,
                'status' => 'approved',
                'remarks' => 'Approved. Lab safety checklist attached.',
            ]
        );

        foreach ([$juan, $maria, $elias, $isagani] as $s) {
            if (! $s) {
                continue;
            }
            EventRegistration::updateOrCreate(
                ['event_id' => $upcomingRegisteredEvent->id, 'student_id' => $s->id],
                [
                    'status' => 'registered',
                    'waiting_list_position' => null,
                    'registered_at' => now()->subDays(2),
                ]
            );
        }

        // =====================================================================
        // 3. PUBLISHED FULL EVENT WITH WAITING LIST (Upcoming in 7 days)
        // =====================================================================
        $waitlistEvent = Event::updateOrCreate(
            ['title' => 'Full-Stack Flutter & Cloud Workshop'],
            [
                'organizer_id' => $coOrganizer->id,
                'description' => 'Intensive laboratory workshop on responsive cross-platform Flutter UI architecture and REST API integration. Limited to 3 lab stations.',
                'venue' => 'CCS Laboratory 301',
                'event_date' => now()->addDays(7)->toDateString(),
                'start_time' => '13:00:00',
                'end_time' => '17:00:00',
                'registration_start' => now()->subDays(6),
                'registration_end' => now()->addDays(6),
                'max_participants' => 3,
                'late_grace_period_minutes' => 10,
                'walk_in_allowed' => false,
                'status' => 'published',
            ]
        );

        EventApproval::updateOrCreate(
            [
                'event_id' => $waitlistEvent->id,
                'approval_type' => 'publish',
            ],
            [
                'admin_id' => $admin->id,
                'status' => 'approved',
                'remarks' => 'Approved for 3 laboratory workstations with automatic waitlist promotion.',
            ]
        );

        // 3 confirmed registered students filling capacity (3/3)
        foreach ([$maria, $ibarra, $elias] as $idx => $confirmed) {
            if (! $confirmed) {
                continue;
            }
            EventRegistration::updateOrCreate(
                ['event_id' => $waitlistEvent->id, 'student_id' => $confirmed->id],
                [
                    'status' => 'registered',
                    'waiting_list_position' => null,
                    'registered_at' => now()->subDays(4)->addHours($idx),
                ]
            );
        }

        // Juan (20260001) is #1 on Waiting List; Sisa (20269004) is #2 on Waiting List
        if ($juan) {
            EventRegistration::updateOrCreate(
                ['event_id' => $waitlistEvent->id, 'student_id' => $juan->id],
                [
                    'status' => 'waiting_list',
                    'waiting_list_position' => 1,
                    'registered_at' => now()->subDays(2),
                ]
            );
        }
        if ($sisa) {
            EventRegistration::updateOrCreate(
                ['event_id' => $waitlistEvent->id, 'student_id' => $sisa->id],
                [
                    'status' => 'waiting_list',
                    'waiting_list_position' => 2,
                    'registered_at' => now()->subDay(),
                ]
            );
        }

        // =====================================================================
        // 4. PUBLISHED OPEN EVENT (Upcoming in 10 days — open for Juan to register)
        // =====================================================================
        $openEvent = Event::updateOrCreate(
            ['title' => 'Inter-College Leadership & Governance Forum'],
            [
                'organizer_id' => $organizer->id,
                'description' => 'Annual student leadership assembly covering institutional governance, event compliance, and campus organization accreditation.',
                'venue' => 'Audio-Visual Room Building B',
                'event_date' => now()->addDays(10)->toDateString(),
                'start_time' => '08:30:00',
                'end_time' => '12:00:00',
                'registration_start' => now()->subDays(3),
                'registration_end' => now()->addDays(9),
                'max_participants' => 100,
                'late_grace_period_minutes' => 15,
                'walk_in_allowed' => true,
                'status' => 'published',
            ]
        );

        EventApproval::updateOrCreate(
            [
                'event_id' => $openEvent->id,
                'approval_type' => 'publish',
            ],
            [
                'admin_id' => $admin->id,
                'status' => 'approved',
                'remarks' => 'Approved for all colleges.',
            ]
        );

        // =====================================================================
        // 5. COMPLETED EVENT (7 days ago — rich multi-department report data)
        // =====================================================================
        $completedDate = now()->subDays(7)->toDateString();
        $completedEvent = Event::updateOrCreate(
            ['title' => 'Freshmen & Transferees Academic Orientation 2026'],
            [
                'organizer_id' => $organizer->id,
                'description' => 'Mandatory institutional orientation on academic policies, student handbook, library services, and QR-based event attendance.',
                'venue' => 'University Grand Gymnasium',
                'event_date' => $completedDate,
                'start_time' => '08:00:00',
                'end_time' => '12:00:00',
                'registration_start' => now()->subDays(20),
                'registration_end' => now()->subDays(8),
                'max_participants' => 80,
                'late_grace_period_minutes' => 15,
                'walk_in_allowed' => true,
                'status' => 'completed',
            ]
        );

        EventApproval::updateOrCreate(
            [
                'event_id' => $completedEvent->id,
                'approval_type' => 'publish',
            ],
            [
                'admin_id' => $admin->id,
                'status' => 'approved',
                'remarks' => 'Orientation schedule approved.',
            ]
        );

        // Present attendees (with check-in & check-out)
        foreach ([$juan, $maria, $ibarra] as $idx => $presentStu) {
            if (! $presentStu) {
                continue;
            }
            $reg = EventRegistration::updateOrCreate(
                ['event_id' => $completedEvent->id, 'student_id' => $presentStu->id],
                [
                    'status' => 'registered',
                    'waiting_list_position' => null,
                    'registered_at' => now()->subDays(12),
                ]
            );
            Attendance::updateOrCreate(
                ['event_id' => $completedEvent->id, 'student_id' => $presentStu->id],
                [
                    'event_registration_id' => $reg->id,
                    'check_in_time' => "{$completedDate} 08:0" . (3 + $idx) . ':00',
                    'check_out_time' => "{$completedDate} 12:0" . (1 + $idx) . ':00',
                    'status' => 'present',
                    'scanner_id' => $organizer->id,
                ]
            );
        }

        // Late attendee
        if ($elias) {
            $regLate = EventRegistration::updateOrCreate(
                ['event_id' => $completedEvent->id, 'student_id' => $elias->id],
                [
                    'status' => 'registered',
                    'waiting_list_position' => null,
                    'registered_at' => now()->subDays(11),
                ]
            );
            Attendance::updateOrCreate(
                ['event_id' => $completedEvent->id, 'student_id' => $elias->id],
                [
                    'event_registration_id' => $regLate->id,
                    'check_in_time' => "{$completedDate} 08:27:00",
                    'check_out_time' => "{$completedDate} 12:04:00",
                    'status' => 'late',
                    'scanner_id' => $organizer->id,
                ]
            );
        }

        // Excused attendee (with manual correction audit log)
        if ($sisa) {
            $regExcused = EventRegistration::updateOrCreate(
                ['event_id' => $completedEvent->id, 'student_id' => $sisa->id],
                [
                    'status' => 'registered',
                    'waiting_list_position' => null,
                    'registered_at' => now()->subDays(11),
                ]
            );
            $attExcused = Attendance::updateOrCreate(
                ['event_id' => $completedEvent->id, 'student_id' => $sisa->id],
                [
                    'event_registration_id' => $regExcused->id,
                    'check_in_time' => "{$completedDate} 08:00:00",
                    'check_out_time' => null,
                    'status' => 'excused',
                    'scanner_id' => $organizer->id,
                ]
            );
            AttendanceCorrection::updateOrCreate(
                [
                    'attendance_id' => $attExcused->id,
                    'new_status' => 'excused',
                ],
                [
                    'corrected_by' => $organizer->id,
                    'original_status' => 'absent',
                    'reason' => 'Submitted validated medical certificate from University Clinic.',
                ]
            );
        }

        // Walk-in attendee
        if ($basilio) {
            $regWalkIn = EventRegistration::updateOrCreate(
                ['event_id' => $completedEvent->id, 'student_id' => $basilio->id],
                [
                    'status' => 'walk_in',
                    'waiting_list_position' => null,
                    'registered_at' => "{$completedDate} 08:35:00",
                ]
            );
            Attendance::updateOrCreate(
                ['event_id' => $completedEvent->id, 'student_id' => $basilio->id],
                [
                    'event_registration_id' => $regWalkIn->id,
                    'check_in_time' => "{$completedDate} 08:35:00",
                    'check_out_time' => "{$completedDate} 12:05:00",
                    'status' => 'walk_in',
                    'scanner_id' => $organizer->id,
                ]
            );
        }

        // Absent registered students (registered, no attendance row -> reported as 'absent')
        foreach ([$isagani, $paulita] as $absentStu) {
            if (! $absentStu) {
                continue;
            }
            EventRegistration::updateOrCreate(
                ['event_id' => $completedEvent->id, 'student_id' => $absentStu->id],
                [
                    'status' => 'registered',
                    'waiting_list_position' => null,
                    'registered_at' => now()->subDays(10),
                ]
            );
        }

        // Cancelled registration example
        if ($simoun) {
            EventRegistration::updateOrCreate(
                ['event_id' => $completedEvent->id, 'student_id' => $simoun->id],
                [
                    'status' => 'cancelled',
                    'waiting_list_position' => null,
                    'registered_at' => now()->subDays(14),
                    'cancelled_at' => now()->subDays(9),
                ]
            );
        }

        // =====================================================================
        // 6. PENDING APPROVAL EVENT (Appears in Admin -> Reviews queue)
        // =====================================================================
        Event::updateOrCreate(
            ['title' => 'National Collegiate Hackathon Qualifier'],
            [
                'organizer_id' => $organizer->id,
                'description' => '24-hour inter-university software engineering sprint requiring overnight laboratory access and security clearance.',
                'venue' => 'CCS Multi-Purpose Hall',
                'event_date' => now()->addDays(14)->toDateString(),
                'start_time' => '08:00:00',
                'end_time' => '18:00:00',
                'registration_start' => now()->addDays(1),
                'registration_end' => now()->addDays(12),
                'max_participants' => 60,
                'late_grace_period_minutes' => 15,
                'walk_in_allowed' => false,
                'status' => 'pending_approval',
            ]
        );

        Event::updateOrCreate(
            ['title' => 'Accounting Standards & Tax Compliance Seminar'],
            [
                'organizer_id' => $coOrganizer->id,
                'description' => 'CPA board preparation and updated BIR regulatory compliance seminar for senior accountancy students.',
                'venue' => 'CBA Lecture Theater 2',
                'event_date' => now()->addDays(18)->toDateString(),
                'start_time' => '09:00:00',
                'end_time' => '15:00:00',
                'registration_start' => now()->addDays(2),
                'registration_end' => now()->addDays(16),
                'max_participants' => 75,
                'late_grace_period_minutes' => 15,
                'walk_in_allowed' => true,
                'status' => 'pending_approval',
            ]
        );

        // =====================================================================
        // 7. DRAFT EVENT (Appears in Organizer -> My Events for editing/submission)
        // =====================================================================
        Event::updateOrCreate(
            ['title' => 'Year-End Student Research Colloquium (Draft)'],
            [
                'organizer_id' => $organizer->id,
                'description' => 'Draft schedule for undergraduate thesis defenses and poster presentations.',
                'venue' => 'Research Center Conference Hall',
                'event_date' => now()->addDays(21)->toDateString(),
                'start_time' => '09:00:00',
                'end_time' => '16:00:00',
                'registration_start' => now()->addDays(5),
                'registration_end' => now()->addDays(19),
                'max_participants' => 50,
                'late_grace_period_minutes' => 15,
                'walk_in_allowed' => true,
                'status' => 'draft',
            ]
        );

        // =====================================================================
        // 8. CANCELLED EVENT (Demonstrates cancellation workflow & badges)
        // =====================================================================
        $cancelledEvent = Event::updateOrCreate(
            ['title' => 'Outdoor Campus Acoustic Night'],
            [
                'organizer_id' => $coOrganizer->id,
                'description' => 'Open-air cultural music night postponed due to typhoon weather advisory.',
                'venue' => 'University Grand Oval',
                'event_date' => now()->addDays(3)->toDateString(),
                'start_time' => '17:30:00',
                'end_time' => '21:00:00',
                'registration_start' => now()->subDays(7),
                'registration_end' => now()->addDays(2),
                'max_participants' => 150,
                'late_grace_period_minutes' => 20,
                'walk_in_allowed' => true,
                'status' => 'cancelled',
            ]
        );

        EventApproval::updateOrCreate(
            [
                'event_id' => $cancelledEvent->id,
                'approval_type' => 'cancellation',
            ],
            [
                'admin_id' => $admin->id,
                'status' => 'approved',
                'remarks' => 'Cancellation approved due to severe weather bulletin.',
            ]
        );

        // =====================================================================
        // 9. NOTIFICATIONS (Unread & Read samples across roles)
        // =====================================================================
        if ($juan) {
            Notification::updateOrCreate(
                [
                    'user_id' => $juan->user_id,
                    'title' => 'Attendance Recorded: Cybersecurity Summit',
                ],
                [
                    'message' => 'Your check-in at 08:05 AM for Annual Cybersecurity & Cloud Computing Summit 2026 was recorded as PRESENT.',
                    'notification_type' => 'attendance_recorded',
                    'is_read' => false,
                    'payload' => ['event_id' => $ongoingEvent->id, 'status' => 'present'],
                ]
            );

            Notification::updateOrCreate(
                [
                    'user_id' => $juan->user_id,
                    'title' => 'Waiting List Position #1: Flutter Workshop',
                ],
                [
                    'message' => 'You are currently #1 on the waiting list for Full-Stack Flutter & Cloud Workshop. You will be promoted automatically if a slot opens.',
                    'notification_type' => 'registration_confirmed',
                    'is_read' => false,
                    'payload' => ['event_id' => $waitlistEvent->id, 'waiting_list_position' => 1],
                ]
            );

            Notification::updateOrCreate(
                [
                    'user_id' => $juan->user_id,
                    'title' => 'Event Cancelled: Outdoor Campus Acoustic Night',
                ],
                [
                    'message' => 'Outdoor Campus Acoustic Night has been cancelled due to a severe weather advisory.',
                    'notification_type' => 'event_cancellation',
                    'is_read' => true,
                    'payload' => ['event_id' => $cancelledEvent->id],
                ]
            );
        }

        Notification::updateOrCreate(
            [
                'user_id' => $organizer->id,
                'title' => 'Event Published: Cybersecurity Summit',
            ],
            [
                'message' => 'Your event "Annual Cybersecurity & Cloud Computing Summit 2026" was approved by Administrator.',
                'notification_type' => 'system_announcement',
                'is_read' => false,
                'payload' => ['event_id' => $ongoingEvent->id],
            ]
        );

        Notification::updateOrCreate(
            [
                'user_id' => $admin->id,
                'title' => '2 Events Pending Publishing Review',
            ],
            [
                'message' => 'Organizers submitted 2 events awaiting your publishing approval in the Reviews queue.',
                'notification_type' => 'system_announcement',
                'is_read' => false,
                'payload' => ['pending_count' => 2],
            ]
        );

        Notification::updateOrCreate(
            [
                'user_id' => $management->id,
                'title' => 'Weekly Institutional Turnout Digest Ready',
            ],
            [
                'message' => 'Completed orientation and ongoing summit attendance metrics are available in Read-Only Reports.',
                'notification_type' => 'system_announcement',
                'is_read' => false,
                'payload' => ['report_type' => 'participation_summary'],
            ]
        );

        // =====================================================================
        // 10. AUDIT TRAIL / ACTIVITY LOGS (For Admin -> Activity view)
        // =====================================================================
        $auditEntries = [
            [
                'action' => 'event_published',
                'user_id' => $admin->id,
                'module' => 'events',
                'record_id' => $ongoingEvent->id,
                'metadata' => [
                    'event_title' => $ongoingEvent->title,
                    'decision' => 'approved',
                    'remarks' => 'Approved for campus-wide publication.',
                ],
            ],
            [
                'action' => 'attendance_scan_check_in',
                'user_id' => $organizer->id,
                'module' => 'attendance',
                'record_id' => $ongoingEvent->id,
                'metadata' => [
                    'event_id' => $ongoingEvent->id,
                    'student_id_number' => '20260001',
                    'resulting_status' => 'present',
                ],
            ],
            [
                'action' => 'attendance_manual_correction',
                'user_id' => $organizer->id,
                'module' => 'attendance',
                'record_id' => $completedEvent->id,
                'metadata' => [
                    'event_id' => $completedEvent->id,
                    'student_id_number' => '20269004',
                    'original_status' => 'absent',
                    'new_status' => 'excused',
                    'reason' => 'Submitted validated medical certificate from University Clinic.',
                ],
            ],
            [
                'action' => 'event_cancellation_approved',
                'user_id' => $admin->id,
                'module' => 'events',
                'record_id' => $cancelledEvent->id,
                'metadata' => [
                    'event_title' => $cancelledEvent->title,
                    'remarks' => 'Cancellation approved due to severe weather bulletin.',
                ],
            ],
        ];

        foreach ($auditEntries as $entry) {
            ActivityLog::updateOrCreate(
                [
                    'action' => $entry['action'],
                    'module' => $entry['module'],
                    'record_id' => $entry['record_id'],
                ],
                [
                    'user_id' => $entry['user_id'],
                    'metadata' => $entry['metadata'],
                    'ip_address' => '127.0.0.1',
                    'user_agent' => 'Console/DemoSchoolDataSeeder',
                ]
            );
        }
    }
}
