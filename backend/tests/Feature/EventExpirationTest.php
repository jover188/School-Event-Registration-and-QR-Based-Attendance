<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\Event;
use App\Models\EventRegistration;
use App\Models\Role;
use App\Models\Student;
use App\Models\StudentQR;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EventExpirationTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;
    private User $organizer;
    private User $studentUser;
    private Student $student;
    private StudentQR $studentQr;

    protected function setUp(): void
    {
        parent::setUp();

        // 1. Seed Roles
        Role::create(['id' => 1, 'name' => 'Administrator', 'slug' => 'administrator']);
        Role::create(['id' => 2, 'name' => 'Organizer', 'slug' => 'organizer']);
        Role::create(['id' => 3, 'name' => 'Student', 'slug' => 'student']);
        Role::create(['id' => 4, 'name' => 'Management', 'slug' => 'management']);

        // 2. Create Users
        $this->admin = User::factory()->create(['role_id' => 1, 'status' => 'active']);
        $this->organizer = User::factory()->create(['role_id' => 2, 'status' => 'active']);
        $this->studentUser = User::factory()->create(['role_id' => 3, 'status' => 'active']);

        $this->student = Student::create([
            'user_id' => $this->studentUser->id,
            'student_id_number' => '20260001',
            'first_name' => 'Maria',
            'last_name' => 'Clara',
            'contact_number' => '09123456789',
            'department' => 'College of Computer Studies',
            'course' => 'BS Information Technology',
            'year_level' => '3rd Year',
            'section' => 'A',
            'status' => 'active',
        ]);

        $this->studentQr = StudentQR::create([
            'student_id' => $this->student->id,
            'qr_token' => str_repeat('a', 64),
            'status' => 'active',
            'issued_at' => now(),
        ]);
    }

    private function tokenFor(User $user): string
    {
        app('auth')->forgetGuards();
        $sessionId = \Illuminate\Support\Str::uuid()->toString();
        $user->update(['active_session_id' => $sessionId]);
        return $user->createToken("session-{$sessionId}")->plainTextToken;
    }

    /**
     * Test 1: Correctly ended event retains status and rejects QR scans.
     */
    public function test_correctly_ended_event_retains_completed_status_and_rejects_scans(): void
    {
        $event = Event::create([
            'organizer_id' => $this->organizer->id,
            'title' => 'Past Orientation',
            'description' => 'Completed event description',
            'venue' => 'Main Auditorium',
            'event_date' => now()->subDays(5)->toDateString(),
            'start_time' => '08:00:00',
            'end_time' => '12:00:00',
            'registration_start' => now()->subDays(10),
            'registration_end' => now()->subDays(6),
            'status' => 'completed',
        ]);

        $this->assertTrue($event->hasEnded());
        $this->assertEquals('completed', $event->status);

        $orgToken = $this->tokenFor($this->organizer);
        $response = $this->withHeader('Authorization', "Bearer {$orgToken}")
            ->postJson("/api/v1/events/{$event->id}/attendance/scan", [
                'qr_token' => $this->studentQr->qr_token,
                'mode' => 'check_in',
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('error_code', 'ERR_EVENT_NOT_ACTIVE');
    }

    /**
     * Test 2: Event past its scheduled end time stored as published is auto-closed on query.
     */
    public function test_expired_published_event_is_automatically_transitioned_to_completed_on_query(): void
    {
        $expiredEvent = Event::create([
            'organizer_id' => $this->organizer->id,
            'title' => 'Expired Tech Symposium',
            'description' => 'Event held yesterday',
            'venue' => 'Lab 1',
            'event_date' => now()->subDay()->toDateString(),
            'start_time' => '09:00:00',
            'end_time' => '11:00:00',
            'registration_start' => now()->subDays(3),
            'registration_end' => now()->subDays(2),
            'status' => 'published',
        ]);

        $futureEvent = Event::create([
            'organizer_id' => $this->organizer->id,
            'title' => 'Upcoming Hackathon',
            'description' => 'Future event',
            'venue' => 'Gym',
            'event_date' => now()->addDays(3)->toDateString(),
            'start_time' => '09:00:00',
            'end_time' => '17:00:00',
            'registration_start' => now()->subDay(),
            'registration_end' => now()->addDay(),
            'status' => 'published',
        ]);

        $studentToken = $this->tokenFor($this->studentUser);

        // Student queries events list
        $response = $this->withHeader('Authorization', "Bearer {$studentToken}")
            ->getJson('/api/v1/events');

        $response->assertStatus(200);

        // The expired event should have transitioned in DB to completed
        $this->assertEquals('completed', $expiredEvent->fresh()->status);
        $this->assertEquals('published', $futureEvent->fresh()->status);

        // Students only see published and ongoing events
        $eventIds = collect($response->json('data'))->pluck('id')->all();
        $this->assertContains($futureEvent->id, $eventIds);
        $this->assertNotContains($expiredEvent->id, $eventIds);
    }

    /**
     * Test 3: Event reaching exact end time transitions correctly.
     */
    public function test_event_reaching_exact_end_time_transitions_to_completed(): void
    {
        $now = Carbon::parse('2026-11-23 15:00:00');

        $event = Event::create([
            'organizer_id' => $this->organizer->id,
            'title' => 'Exact Expiration Seminar',
            'description' => 'Testing boundary time',
            'venue' => 'Room 204',
            'event_date' => '2026-11-23',
            'start_time' => '13:00:00',
            'end_time' => '15:00:00',
            'registration_start' => '2026-11-20 00:00:00',
            'registration_end' => '2026-11-22 23:59:59',
            'status' => 'ongoing',
        ]);

        // At exact end time 15:00:00, hasEnded should be true
        $this->assertTrue($event->hasEnded($now));

        // syncExpiredEvents should transition it
        Event::syncExpiredEvents($now);
        $this->assertEquals('completed', $event->fresh()->status);
    }

    /**
     * Test 4: QR scan attempt on expired event is rejected and updates status.
     */
    public function test_qr_scan_attempt_on_expired_event_rejects_and_updates_status(): void
    {
        $expiredEvent = Event::create([
            'organizer_id' => $this->organizer->id,
            'title' => 'Just Ended Conference',
            'description' => 'Ended 10 minutes ago',
            'venue' => 'Hall C',
            'event_date' => now()->toDateString(),
            'start_time' => now()->subHours(2)->format('H:i:s'),
            'end_time' => now()->subMinutes(10)->format('H:i:s'),
            'registration_start' => now()->subDays(2),
            'registration_end' => now()->subDay(),
            'walk_in_allowed' => true,
            'status' => 'ongoing',
        ]);

        $orgToken = $this->tokenFor($this->organizer);
        $response = $this->withHeader('Authorization', "Bearer {$orgToken}")
            ->postJson("/api/v1/events/{$expiredEvent->id}/attendance/scan", [
                'qr_token' => $this->studentQr->qr_token,
                'mode' => 'check_in',
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('error_code', 'ERR_EVENT_NOT_ACTIVE');

        // Status should be updated to completed
        $this->assertEquals('completed', $expiredEvent->fresh()->status);

        // No attendance record should be written
        $this->assertEquals(0, Attendance::where('event_id', $expiredEvent->id)->count());
    }

    /**
     * Test 5: Existing attendance records on expired events remain intact.
     */
    public function test_existing_attendance_records_on_expired_events_remain_intact(): void
    {
        $event = Event::create([
            'organizer_id' => $this->organizer->id,
            'title' => 'Orientation with Valid Attendees',
            'description' => 'Event held earlier today',
            'venue' => 'AVR',
            'event_date' => now()->subDays(2)->toDateString(),
            'start_time' => '08:00:00',
            'end_time' => '12:00:00',
            'registration_start' => now()->subDays(5),
            'registration_end' => now()->subDays(3),
            'status' => 'published',
        ]);

        $reg = EventRegistration::create([
            'event_id' => $event->id,
            'student_id' => $this->student->id,
            'status' => 'registered',
            'registered_at' => now()->subDays(4),
        ]);

        $att = Attendance::create([
            'event_id' => $event->id,
            'student_id' => $this->student->id,
            'event_registration_id' => $reg->id,
            'check_in_time' => now()->subDays(2)->setTime(8, 5, 0),
            'check_out_time' => now()->subDays(2)->setTime(12, 1, 0),
            'status' => 'present',
        ]);

        // Trigger synchronization
        Event::syncExpiredEvents();

        $this->assertEquals('completed', $event->fresh()->status);

        // Verify attendance record still exists unchanged
        $savedAtt = Attendance::find($att->id);
        $this->assertNotNull($savedAtt);
        $this->assertEquals('present', $savedAtt->status);
        $this->assertEquals($event->id, $savedAtt->event_id);
        $this->assertEquals($this->student->id, $savedAtt->student_id);

        // Student attendance history endpoint returns it
        $studentToken = $this->tokenFor($this->studentUser);
        app('auth')->forgetGuards();
        $historyRes = $this->withHeader('Authorization', "Bearer {$studentToken}")
            ->getJson('/api/v1/student/attendance-history');

        $historyRes->assertStatus(200);
        $this->assertCount(1, $historyRes->json('data'));
        $this->assertEquals('Orientation with Valid Attendees', $historyRes->json('data.0.event.title'));
    }

    /**
     * Test 6: Event created through organizer draft -> admin approval workflow transitions properly.
     */
    public function test_event_created_through_approval_workflow_transitions_upon_reaching_end_time(): void
    {
        $orgToken = $this->tokenFor($this->organizer);
        app('auth')->forgetGuards();

        // Step 1: Organizer creates draft event
        $createRes = $this->withHeader('Authorization', "Bearer {$orgToken}")
            ->postJson('/api/v1/events', [
                'title' => 'Robotics Seminar',
                'description' => 'Hands-on assembly',
                'venue' => 'Room 401',
                'event_date' => now()->toDateString(),
                'start_time' => '08:00:00',
                'end_time' => '12:00:00',
                'registration_start' => now()->subDays(3)->toDateTimeString(),
                'registration_end' => now()->addDays(1)->toDateTimeString(),
                'save_as_draft' => false, // submits for approval
            ]);

        $createRes->assertStatus(201);
        $eventId = $createRes->json('data.id');

        // Step 2: Admin approves publishing
        $adminToken = $this->tokenFor($this->admin);
        app('auth')->forgetGuards();
        $reviewRes = $this->withHeader('Authorization', "Bearer {$adminToken}")
            ->postJson("/api/v1/admin/events/{$eventId}/review", [
                'action' => 'approved',
                'remarks' => 'Approved for publishing',
            ]);

        $reviewRes->assertStatus(200);
        $event = Event::findOrFail($eventId);
        $this->assertEquals('published', $event->status);

        // Step 3: Fast-forward time past end time
        $afterEnd = Carbon::now()->setTime(13, 0, 0);
        Event::syncExpiredEvents($afterEnd);

        $this->assertEquals('completed', $event->fresh()->status);
    }
}
