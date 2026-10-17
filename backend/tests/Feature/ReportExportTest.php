<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\Event;
use App\Models\EventRegistration;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReportExportTest extends TestCase
{
    use RefreshDatabase;

    private string $adminToken;
    private Event $event;
    private Student $presentStudent;
    private Student $absentStudent;
    private Student $walkInStudent;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();

        $adminLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'admin@school.edu',
            'password' => 'Admin@12345',
        ]);
        $this->adminToken = $adminLogin->json('data.token');

        $organizer = User::where('role_id', 2)->first();
        $this->event = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'Tech Summit 2026',
            'description' => 'Annual technology summit',
            'venue' => 'Grand Auditorium',
            'event_date' => '2026-10-20',
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
            'registration_start' => '2026-10-01 08:00:00',
            'registration_end' => '2026-10-19 17:00:00',
            'max_participants' => 100,
            'walk_in_allowed' => true,
            'status' => 'completed',
        ]);

        // 1. Seeded student -> registered & present
        $this->presentStudent = Student::where('student_id_number', '20260001')->first();
        $regPresent = EventRegistration::create([
            'event_id' => $this->event->id,
            'student_id' => $this->presentStudent->id,
            'status' => 'registered',
            'registered_at' => now(),
        ]);
        Attendance::create([
            'event_id' => $this->event->id,
            'student_id' => $this->presentStudent->id,
            'event_registration_id' => $regPresent->id,
            'check_in_time' => '2026-10-20 08:05:00',
            'check_out_time' => '2026-10-20 17:00:00',
            'status' => 'present',
            'scanner_id' => $organizer->id,
        ]);

        // 2. Absent student -> registered, NO attendance row
        $uAbsent = User::create([
            'role_id' => 3,
            'email' => 'absent@school.edu',
            'password' => bcrypt('Pass@12345'),
            'status' => 'active',
        ]);
        $this->absentStudent = Student::create([
            'user_id' => $uAbsent->id,
            'student_id_number' => '20260050',
            'first_name' => 'Ana',
            'last_name' => 'Reyes',
            'course' => 'BS Accountancy',
            'year_level' => '4th Year',
            'section' => 'BSA-4A',
            'department' => 'College of Business',
            'contact_number' => '09175550050',
        ]);
        EventRegistration::create([
            'event_id' => $this->event->id,
            'student_id' => $this->absentStudent->id,
            'status' => 'registered',
            'registered_at' => now(),
        ]);

        // 3. Walk-in student -> walk_in registration + walk_in attendance
        $uWalk = User::create([
            'role_id' => 3,
            'email' => 'walkin@school.edu',
            'password' => bcrypt('Pass@12345'),
            'status' => 'active',
        ]);
        $this->walkInStudent = Student::create([
            'user_id' => $uWalk->id,
            'student_id_number' => '20260051',
            'first_name' => 'Carlo',
            'last_name' => 'Gomez',
            'course' => 'BS Information Technology',
            'year_level' => '1st Year',
            'section' => 'BSIT-1A',
            'department' => 'College of Computer Studies',
            'contact_number' => '09175550051',
        ]);
        $regWalk = EventRegistration::create([
            'event_id' => $this->event->id,
            'student_id' => $this->walkInStudent->id,
            'status' => 'walk_in',
            'registered_at' => now(),
        ]);
        Attendance::create([
            'event_id' => $this->event->id,
            'student_id' => $this->walkInStudent->id,
            'event_registration_id' => $regWalk->id,
            'check_in_time' => '2026-10-20 09:00:00',
            'status' => 'walk_in',
            'scanner_id' => $organizer->id,
        ]);
    }

    private function requestAs(string $token, string $method, string $uri, array $data = [])
    {
        app('auth')->forgetGuards();
        return $this->withHeader('Authorization', "Bearer {$token}")
            ->json($method, $uri, $data);
    }

    public function test_event_attendance_report_includes_absent_rows_and_supports_filters(): void
    {
        $resp = $this->requestAs(
            $this->adminToken,
            'GET',
            "/api/v1/reports/event-attendance/{$this->event->id}"
        );

        $resp->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('present_count', 1)
            ->assertJsonPath('walk_in_count', 1)
            ->assertJsonPath('absent_count', 1);

        $data = $resp->json('data');
        $this->assertCount(3, $data);

        // Filter by status=absent
        $absentOnly = $this->requestAs(
            $this->adminToken,
            'GET',
            "/api/v1/reports/event-attendance/{$this->event->id}?status=absent"
        );
        $absentOnly->assertStatus(200);
        $this->assertCount(1, $absentOnly->json('data'));
        $this->assertEquals('absent', $absentOnly->json('data.0.status'));

        // Filter by department=College of Business
        $deptFiltered = $this->requestAs(
            $this->adminToken,
            'GET',
            "/api/v1/reports/event-attendance/{$this->event->id}?department=College+of+Business"
        );
        $deptFiltered->assertStatus(200);
        $this->assertCount(1, $deptFiltered->json('data'));
        $this->assertEquals('20260050', $deptFiltered->json('data.0.student.student_id_number'));
    }

    public function test_all_other_six_json_report_endpoints_and_filters(): void
    {
        // 2. Student History Report
        $r2 = $this->requestAs(
            $this->adminToken,
            'GET',
            "/api/v1/reports/student-history/{$this->presentStudent->id}?status=present&date_from=2026-10-01&date_to=2026-10-31"
        );
        $r2->assertStatus(200)->assertJsonPath('total_events_attended', 1);

        // 3. Registration Summary Report
        $r3 = $this->requestAs(
            $this->adminToken,
            'GET',
            "/api/v1/reports/registration-summary/{$this->event->id}?department=College+of+Business"
        );
        $r3->assertStatus(200)
            ->assertJsonPath('summary.registered', 1)
            ->assertJsonPath('summary.walk_in', 0);

        // 4. Participation Summary Report
        $r4 = $this->requestAs(
            $this->adminToken,
            'GET',
            '/api/v1/reports/participation-summary?date_from=2026-10-01&date_to=2026-10-31'
        );
        $r4->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => ['total_events', 'total_registrations', 'total_attendances', 'turnout_percentage'],
                'events',
            ]);

        // 5. Absentee Report
        $r5 = $this->requestAs(
            $this->adminToken,
            'GET',
            "/api/v1/reports/absentee/{$this->event->id}?year_level=4th+Year"
        );
        $r5->assertStatus(200)->assertJsonPath('absentee_count', 1);

        // 6. Walk-In Report
        $r6 = $this->requestAs(
            $this->adminToken,
            'GET',
            "/api/v1/reports/walk-in/{$this->event->id}?year_level=1st+Year"
        );
        $r6->assertStatus(200)->assertJsonPath('walk_in_count', 1);

        // 7. Organizer Summary Report
        $r7 = $this->requestAs(
            $this->adminToken,
            'GET',
            '/api/v1/reports/organizer-summary?date_from=2026-10-01&date_to=2026-10-31'
        );
        $r7->assertStatus(200)->assertJsonPath('success', true);
    }

    public function test_export_supports_all_seven_report_types_in_csv_pdf_and_xlsx(): void
    {
        $cases = [
            ['report_type' => 'event_attendance', 'event_id' => $this->event->id],
            ['report_type' => 'student_history', 'student_id' => $this->presentStudent->id],
            ['report_type' => 'registration_summary', 'event_id' => $this->event->id],
            ['report_type' => 'participation_summary'],
            ['report_type' => 'absentee', 'event_id' => $this->event->id],
            ['report_type' => 'walk_in', 'event_id' => $this->event->id],
            ['report_type' => 'organizer_summary'],
        ];

        foreach ($cases as $params) {
            foreach (['csv', 'pdf', 'xlsx'] as $format) {
                $query = http_build_query(array_merge($params, ['format' => $format]));
                $resp = $this->withHeader('Authorization', "Bearer {$this->adminToken}")
                    ->get("/api/v1/reports/export?{$query}");

                $resp->assertStatus(
                    200,
                    "Failed exporting {$params['report_type']} in {$format} format: " . $resp->getContent()
                );
            }
        }
    }
}
