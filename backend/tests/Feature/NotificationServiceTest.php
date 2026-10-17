<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\Notification;
use App\Models\NotificationPreference;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationServiceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    private function requestAs(string $token, string $method, string $uri, array $data = [])
    {
        app('auth')->forgetGuards();
        return $this->withHeader('Authorization', "Bearer {$token}")
            ->json($method, $uri, $data);
    }

    public function test_optional_notifications_respect_user_preferences(): void
    {
        $studentUser = User::where('email', 'student1@school.edu')->first()
            ?? User::where('role_id', 3)->first();

        NotificationPreference::updateOrCreate(
            ['user_id' => $studentUser->id],
            [
                'new_event_published' => false,
                'registration_confirmed' => false,
                'event_reminders' => false,
                'event_updates' => false,
                'waiting_list_promoted' => false,
                'admin_announcements' => false,
            ]
        );

        // Optional notifications must be suppressed when preference is false
        $this->assertNull(NotificationService::send(
            $studentUser->id,
            'New Event',
            'A new event was published.',
            'new_event_published',
            ['event_id' => 1]
        ));

        $this->assertNull(NotificationService::send(
            $studentUser->id,
            'Registered',
            'Registration confirmed.',
            'registration_confirmed',
            ['event_id' => 1]
        ));

        $this->assertNull(NotificationService::send(
            $studentUser->id,
            'Reminder',
            'Event starts in 24h.',
            'event_reminder_24h',
            ['event_id' => 1]
        ));

        $this->assertNull(NotificationService::send(
            $studentUser->id,
            'Event Updated',
            'Venue changed.',
            'event_updates',
            ['event_id' => 1]
        ));

        $this->assertNull(NotificationService::send(
            $studentUser->id,
            'Promoted',
            'You got a slot.',
            'waiting_list_promoted',
            ['event_id' => 1]
        ));

        $this->assertNull(NotificationService::send(
            $studentUser->id,
            'Announcement',
            'System notice.',
            'admin_announcement'
        ));

        $this->assertEquals(0, Notification::where('user_id', $studentUser->id)->count());

        // Enable new_event_published and verify it is delivered
        NotificationPreference::where('user_id', $studentUser->id)->update(['new_event_published' => true]);

        $notif = NotificationService::send(
            $studentUser->id,
            'New Event Allowed',
            'This one should be sent.',
            'new_event_published',
            ['event_id' => 2]
        );

        $this->assertNotNull($notif);
        $this->assertEquals(1, Notification::where('user_id', $studentUser->id)->count());
    }

    public function test_mandatory_notifications_always_delivered_even_when_all_preferences_disabled(): void
    {
        $studentUser = User::where('role_id', 3)->first();

        NotificationPreference::updateOrCreate(
            ['user_id' => $studentUser->id],
            [
                'new_event_published' => false,
                'registration_confirmed' => false,
                'event_reminders' => false,
                'event_updates' => false,
                'waiting_list_promoted' => false,
                'admin_announcements' => false,
            ]
        );

        $cancelNotif = NotificationService::send(
            $studentUser->id,
            'Event Cancelled',
            'Event has been cancelled.',
            'event_cancellation',
            ['event_id' => 10]
        );

        $attNotif = NotificationService::send(
            $studentUser->id,
            'Attendance Recorded',
            'Checked in as PRESENT.',
            'attendance_recorded',
            ['event_id' => 10, 'status' => 'present']
        );

        $this->assertNotNull($cancelNotif);
        $this->assertNotNull($attNotif);
        $this->assertEquals(2, Notification::where('user_id', $studentUser->id)->count());
    }

    public function test_event_publish_and_update_dispatch_notifications_via_service(): void
    {
        $adminLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'admin@school.edu',
            'password' => 'Admin@12345',
        ]);
        $adminToken = $adminLogin->json('data.token');

        $organizer = User::where('role_id', 2)->first();
        $event = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'AI Ethics Forum',
            'description' => 'Forum on responsible computing',
            'venue' => 'Main Hall',
            'event_date' => now()->addDays(7)->toDateString(),
            'start_time' => '10:00:00',
            'end_time' => '12:00:00',
            'registration_start' => now()->subDay(),
            'registration_end' => now()->addDays(5),
            'max_participants' => 100,
            'status' => 'pending_approval',
        ]);

        // Admin approves event -> active students receive new_event_published notification
        $reviewResp = $this->requestAs($adminToken, 'POST', "/api/v1/admin/events/{$event->id}/review", [
            'action' => 'approved',
            'remarks' => 'Looks good',
        ]);
        $reviewResp->assertStatus(200);

        $studentUser = User::where('role_id', 3)->first();
        $this->assertDatabaseHas('notifications', [
            'user_id' => $studentUser->id,
            'notification_type' => 'new_event_published',
        ]);

        // Register student for the event, then update the published event -> receives event_updates
        $event->registrations()->create([
            'student_id' => $studentUser->student->id,
            'status' => 'registered',
            'registered_at' => now(),
        ]);

        $updateResp = $this->requestAs($adminToken, 'PUT', "/api/v1/events/{$event->id}", [
            'venue' => 'Updated Auditorium',
        ]);
        $updateResp->assertStatus(200);

        $this->assertDatabaseHas('notifications', [
            'user_id' => $studentUser->id,
            'notification_type' => 'event_updates',
        ]);
    }

    public function test_admin_can_send_targeted_and_broadcast_announcements(): void
    {
        $adminLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'admin@school.edu',
            'password' => 'Admin@12345',
        ]);
        $adminToken = $adminLogin->json('data.token');

        // Send announcement targeted to students only
        $resp = $this->requestAs($adminToken, 'POST', '/api/v1/admin/announcements', [
            'title' => 'Campus Maintenance Notice',
            'message' => 'QR scanners will be updated tonight at 11 PM.',
            'target_role' => 'student',
        ]);

        $resp->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertGreaterThanOrEqual(1, $resp->json('data.sent_count'));

        $studentUser = User::where('role_id', 3)->first();
        $organizerUser = User::where('role_id', 2)->first();

        $this->assertDatabaseHas('notifications', [
            'user_id' => $studentUser->id,
            'title' => 'Campus Maintenance Notice',
            'notification_type' => 'admin_announcement',
        ]);

        $this->assertDatabaseMissing('notifications', [
            'user_id' => $organizerUser->id,
            'title' => 'Campus Maintenance Notice',
        ]);
    }
}
