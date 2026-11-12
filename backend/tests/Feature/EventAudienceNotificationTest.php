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

class EventAudienceNotificationTest extends TestCase
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

    public function test_publishing_announcement_is_sent_only_to_targeted_audience(): void
    {
        $adminToken = $this->tokenFor('admin@school.edu', 'Admin@12345');
        $organizer = User::where('email', 'organizer@school.edu')->first();

        $it1User = $this->createStudentUser('targeted.it1@school.edu', 'BS Information Technology', '1st Year', '20261201');
        $it2User = $this->createStudentUser('targeted.it2@school.edu', 'BS Information Technology', '2nd Year', '20261202');
        $baUser  = $this->createStudentUser('targeted.ba@school.edu', 'BS Business Administration', '1st Year', '20261203');

        $event = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'IT Freshmen Orientation',
            'description' => 'Targeted Event',
            'venue' => 'Audi 1',
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
            'remarks' => 'Approved for IT freshmen',
        ]);

        $response->assertStatus(200);

        // IT1 student receives new_event_published notification
        $this->assertDatabaseHas('notifications', [
            'user_id' => $it1User->id,
            'notification_type' => 'new_event_published',
        ]);

        // IT2 and BA students do NOT receive new_event_published notification
        $this->assertDatabaseMissing('notifications', [
            'user_id' => $it2User->id,
            'notification_type' => 'new_event_published',
        ]);

        $this->assertDatabaseMissing('notifications', [
            'user_id' => $baUser->id,
            'notification_type' => 'new_event_published',
        ]);
    }

    public function test_no_announcements_sent_when_send_announcement_is_false(): void
    {
        $adminToken = $this->tokenFor('admin@school.edu', 'Admin@12345');
        $organizer = User::where('email', 'organizer@school.edu')->first();

        $it1User = $this->createStudentUser('noann.it1@school.edu', 'BS Information Technology', '1st Year', '20261204');

        $event = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'Silent IT Event',
            'description' => 'No announcement',
            'venue' => 'Audi 2',
            'event_date' => now()->addDays(5)->toDateString(),
            'start_time' => '09:00:00',
            'end_time' => '12:00:00',
            'registration_start' => now()->subDay()->toDateTimeString(),
            'registration_end' => now()->addDays(4)->toDateTimeString(),
            'target_audience_type' => 'all',
            'send_announcement' => false,
            'status' => 'pending_approval',
        ]);

        $initialNotifCount = Notification::where('notification_type', 'new_event_published')->count();

        $response = $this->requestAs($adminToken, 'POST', "/api/v1/admin/events/{$event->id}/review", [
            'action' => 'approved',
            'remarks' => 'Approved without announcement',
        ]);

        $response->assertStatus(200);

        $newNotifCount = Notification::where('notification_type', 'new_event_published')->count();
        $this->assertEquals($initialNotifCount, $newNotifCount);

        $this->assertDatabaseMissing('notifications', [
            'user_id' => $it1User->id,
            'notification_type' => 'new_event_published',
        ]);
    }
}
