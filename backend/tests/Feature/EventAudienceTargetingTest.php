<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\Notification;
use App\Models\NotificationPreference;
use App\Models\Student;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EventAudienceTargetingTest extends TestCase
{
    use RefreshDatabase;

    private const NOW = '2026-11-12 10:00:00';

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
        Carbon::setTestNow(self::NOW);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function tokenFor(string $login, string $password): string
    {
        app('auth')->forgetGuards();
        $response = $this->postJson('/api/v1/auth/login', [
            'login' => $login,
            'password' => $password,
        ]);
        return $response->json('data.token');
    }

    private function requestAs(string $token, string $method, string $uri, array $data = [])
    {
        app('auth')->forgetGuards();
        return $this->withHeader('Authorization', "Bearer {$token}")
            ->json($method, $uri, $data);
    }

    private function createStudentUser(string $email, string $course, string $yearLevel, string $studentIdNum): User
    {
        $user = User::create([
            'role_id' => 3,
            'email' => $email,
            'password' => bcrypt('Password@123'),
            'status' => 'active',
            'email_verified_at' => now(),
        ]);

        Student::create([
            'user_id' => $user->id,
            'student_id_number' => $studentIdNum,
            'first_name' => 'Student',
            'last_name' => $course,
            'course' => $course,
            'year_level' => $yearLevel,
            'section' => '1A',
            'department' => 'CITE',
            'contact_number' => '09123456789',
        ]);

        NotificationPreference::create([
            'user_id' => $user->id,
            'new_event_published' => true,
        ]);

        return $user;
    }

    public function test_targeted_event_visibility_and_registration_guard(): void
    {
        $organizer = User::where('email', 'organizer@school.edu')->first();

        // 1. BSIT 1st Year event created
        $bsit1Event = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'BSIT 1st Year Hackathon',
            'description' => 'Targeted Event for IT Freshmen',
            'category' => 'Workshop',
            'venue' => 'Lab 301',
            'event_date' => now()->addDays(5)->toDateString(),
            'start_time' => '09:00:00',
            'end_time' => '17:00:00',
            'registration_start' => now()->subDay()->toDateTimeString(),
            'registration_end' => now()->addDays(4)->toDateTimeString(),
            'max_participants' => 30,
            'target_audience_type' => 'custom',
            'target_rules' => [
                ['course' => 'BS Information Technology', 'year_level' => '1st Year'],
            ],
            'status' => 'published',
        ]);

        $it1User = $this->createStudentUser('bsit1@school.edu', 'BS Information Technology', '1st Year', '20262001');
        $it2User = $this->createStudentUser('bsit2@school.edu', 'BS Information Technology', '2nd Year', '20262002');
        $baUser  = $this->createStudentUser('bsba1@school.edu', 'BS Business Administration', '1st Year', '20262003');

        $it1Token = $this->tokenFor('bsit1@school.edu', 'Password@123');
        $it2Token = $this->tokenFor('bsit2@school.edu', 'Password@123');
        $baToken  = $this->tokenFor('bsba1@school.edu', 'Password@123');

        // BSIT 1st Year student can see the event in GET /api/v1/events and register
        $resIt1List = $this->requestAs($it1Token, 'GET', '/api/v1/events');
        $resIt1List->assertStatus(200);
        $it1EventIds = collect($resIt1List->json('data'))->pluck('id')->toArray();
        $this->assertContains($bsit1Event->id, $it1EventIds);

        $resIt1Show = $this->requestAs($it1Token, 'GET', "/api/v1/events/{$bsit1Event->id}");
        $resIt1Show->assertStatus(200);

        $resIt1Reg = $this->requestAs($it1Token, 'POST', "/api/v1/events/{$bsit1Event->id}/register");
        $resIt1Reg->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'registered',
                ],
            ]);

        // BSIT 2nd Year student cannot see the event in GET /api/v1/events, cannot view in GET /api/v1/events/{id}, and cannot register
        $resIt2List = $this->requestAs($it2Token, 'GET', '/api/v1/events');
        $resIt2List->assertStatus(200);
        $it2EventIds = collect($resIt2List->json('data'))->pluck('id')->toArray();
        $this->assertNotContains($bsit1Event->id, $it2EventIds);

        $resIt2Show = $this->requestAs($it2Token, 'GET', "/api/v1/events/{$bsit1Event->id}");
        $resIt2Show->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'ERR_AUDIENCE_INELIGIBLE',
            ]);

        $resIt2Reg = $this->requestAs($it2Token, 'POST', "/api/v1/events/{$bsit1Event->id}/register");
        $resIt2Reg->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'ERR_AUDIENCE_INELIGIBLE',
            ]);

        // BSBA student cannot see, view, or register
        $resBaList = $this->requestAs($baToken, 'GET', '/api/v1/events');
        $resBaList->assertStatus(200);
        $baEventIds = collect($resBaList->json('data'))->pluck('id')->toArray();
        $this->assertNotContains($bsit1Event->id, $baEventIds);

        $resBaShow = $this->requestAs($baToken, 'GET', "/api/v1/events/{$bsit1Event->id}");
        $resBaShow->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'ERR_AUDIENCE_INELIGIBLE',
            ]);

        $resBaReg = $this->requestAs($baToken, 'POST', "/api/v1/events/{$bsit1Event->id}/register");
        $resBaReg->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'ERR_AUDIENCE_INELIGIBLE',
            ]);
    }

    public function test_only_selected_audience_receives_announcement_when_approved(): void
    {
        $adminToken = $this->tokenFor('admin@school.edu', 'Admin@12345');
        $organizer = User::where('email', 'organizer@school.edu')->first();

        $it1User = $this->createStudentUser('pub.it1@school.edu', 'BS Information Technology', '1st Year', '20262004');
        $it2User = $this->createStudentUser('pub.it2@school.edu', 'BS Information Technology', '2nd Year', '20262005');
        $baUser  = $this->createStudentUser('pub.ba@school.edu', 'BS Business Administration', '1st Year', '20262006');

        $event = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'IT 1st Year Symposium',
            'description' => 'Targeted Event',
            'venue' => 'AVR 1',
            'event_date' => now()->addDays(5)->toDateString(),
            'start_time' => '09:00:00',
            'end_time' => '12:00:00',
            'registration_start' => now()->subDay()->toDateTimeString(),
            'registration_end' => now()->addDays(4)->toDateTimeString(),
            'target_audience_type' => 'custom',
            'target_rules' => [
                ['course' => 'BS Information Technology', 'year_level' => '1st Year'],
            ],
            'send_announcement' => true,
            'status' => 'pending_approval',
        ]);

        $response = $this->requestAs($adminToken, 'POST', "/api/v1/admin/events/{$event->id}/review", [
            'action' => 'approved',
            'remarks' => 'Approved',
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('notifications', [
            'user_id' => $it1User->id,
            'notification_type' => 'new_event_published',
        ]);

        $this->assertDatabaseMissing('notifications', [
            'user_id' => $it2User->id,
            'notification_type' => 'new_event_published',
        ]);

        $this->assertDatabaseMissing('notifications', [
            'user_id' => $baUser->id,
            'notification_type' => 'new_event_published',
        ]);
    }

    public function test_when_send_announcement_is_false_no_announcements_sent(): void
    {
        $adminToken = $this->tokenFor('admin@school.edu', 'Admin@12345');
        $organizer = User::where('email', 'organizer@school.edu')->first();

        $it1User = $this->createStudentUser('silent.it1@school.edu', 'BS Information Technology', '1st Year', '20262007');

        $event = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'Unannounced Event',
            'description' => 'No push notification',
            'venue' => 'AVR 2',
            'event_date' => now()->addDays(5)->toDateString(),
            'start_time' => '09:00:00',
            'end_time' => '12:00:00',
            'registration_start' => now()->subDay()->toDateTimeString(),
            'registration_end' => now()->addDays(4)->toDateTimeString(),
            'target_audience_type' => 'all',
            'send_announcement' => false,
            'status' => 'pending_approval',
        ]);

        $initialCount = Notification::where('notification_type', 'new_event_published')->count();

        $response = $this->requestAs($adminToken, 'POST', "/api/v1/admin/events/{$event->id}/review", [
            'action' => 'approved',
        ]);

        $response->assertStatus(200);

        $finalCount = Notification::where('notification_type', 'new_event_published')->count();
        $this->assertEquals($initialCount, $finalCount);

        $this->assertDatabaseMissing('notifications', [
            'user_id' => $it1User->id,
            'notification_type' => 'new_event_published',
        ]);
    }

    public function test_all_students_targeting_works_for_everyone(): void
    {
        $organizer = User::where('email', 'organizer@school.edu')->first();

        $openEvent = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'All University Fest',
            'description' => 'Fest for everyone',
            'venue' => 'Campus Oval',
            'event_date' => now()->addDays(5)->toDateString(),
            'start_time' => '08:00:00',
            'end_time' => '20:00:00',
            'registration_start' => now()->subDay()->toDateTimeString(),
            'registration_end' => now()->addDays(4)->toDateTimeString(),
            'target_audience_type' => 'all',
            'status' => 'published',
        ]);

        $it1User = $this->createStudentUser('all.it1@school.edu', 'BS Information Technology', '1st Year', '20262008');
        $baUser  = $this->createStudentUser('all.ba@school.edu', 'BS Business Administration', '3rd Year', '20262009');

        $it1Token = $this->tokenFor('all.it1@school.edu', 'Password@123');
        $baToken  = $this->tokenFor('all.ba@school.edu', 'Password@123');

        // Both can see
        $resIt1 = $this->requestAs($it1Token, 'GET', '/api/v1/events');
        $this->assertContains($openEvent->id, collect($resIt1->json('data'))->pluck('id')->toArray());

        $resBa = $this->requestAs($baToken, 'GET', '/api/v1/events');
        $this->assertContains($openEvent->id, collect($resBa->json('data'))->pluck('id')->toArray());

        // Both can view
        $this->requestAs($it1Token, 'GET', "/api/v1/events/{$openEvent->id}")->assertStatus(200);
        $this->requestAs($baToken, 'GET', "/api/v1/events/{$openEvent->id}")->assertStatus(200);

        // Both can register
        $this->requestAs($it1Token, 'POST', "/api/v1/events/{$openEvent->id}/register")->assertStatus(201);
        $this->requestAs($baToken, 'POST', "/api/v1/events/{$openEvent->id}/register")->assertStatus(201);
    }
}
