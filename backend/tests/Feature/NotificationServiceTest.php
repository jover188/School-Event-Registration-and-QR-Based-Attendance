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

    public function test_announcement_title_validation_length_boundary(): void
    {
        $adminLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'admin@school.edu',
            'password' => 'Admin@12345',
        ]);
        $adminToken = $adminLogin->json('data.token');

        // 150 characters: should pass validation
        $title150 = str_repeat('A', 150);
        $passResp = $this->requestAs($adminToken, 'POST', '/api/v1/admin/announcements', [
            'title' => $title150,
            'message' => 'Testing 150 char title',
            'target_role' => 'all',
        ]);
        $passResp->assertStatus(200);

        // 151 characters: should fail validation with 422
        $title151 = str_repeat('B', 151);
        $failResp = $this->requestAs($adminToken, 'POST', '/api/v1/admin/announcements', [
            'title' => $title151,
            'message' => 'Testing 151 char title',
            'target_role' => 'all',
        ]);
        $failResp->assertStatus(422)
            ->assertJsonValidationErrors(['title']);
    }

    public function test_sound_is_attached_to_sound_enabled_notification_categories(): void
    {
        $studentUser = User::where('role_id', 3)->first();

        // 1. New event announcement
        $n1 = NotificationService::send(
            $studentUser->id,
            'New Event',
            'Event announced.',
            'new_event_published',
            ['event_id' => 1]
        );
        $this->assertNotNull($n1);
        $this->assertEquals(NotificationService::SOUND_CHIME_07, $n1->payload['sound']);
        $this->assertEquals(NotificationService::NOTIFICATION_CHANNEL_ID, $n1->payload['channel_id']);

        // 2. Admin broadcast announcement
        $n2 = NotificationService::send(
            $studentUser->id,
            'Admin Broadcast',
            'Important announcement.',
            'admin_announcement'
        );
        $this->assertNotNull($n2);
        $this->assertEquals(NotificationService::SOUND_CHIME_07, $n2->payload['sound']);
        $this->assertEquals(NotificationService::NOTIFICATION_CHANNEL_ID, $n2->payload['channel_id']);

        // 3. Event reminders (24h and 1h)
        $n3 = NotificationService::send(
            $studentUser->id,
            '24h Reminder',
            'Event starts in 24 hours.',
            'event_reminder_24h',
            ['event_id' => 1]
        );
        $this->assertNotNull($n3);
        $this->assertEquals(NotificationService::SOUND_CHIME_07, $n3->payload['sound']);
        $this->assertEquals(NotificationService::NOTIFICATION_CHANNEL_ID, $n3->payload['channel_id']);

        $n4 = NotificationService::send(
            $studentUser->id,
            '1h Reminder',
            'Event starts in 1 hour.',
            'event_reminder_1h',
            ['event_id' => 1]
        );
        $this->assertNotNull($n4);
        $this->assertEquals(NotificationService::SOUND_CHIME_07, $n4->payload['sound']);
        $this->assertEquals(NotificationService::NOTIFICATION_CHANNEL_ID, $n4->payload['channel_id']);

        // 4. Event cancellation announcement
        $n5 = NotificationService::send(
            $studentUser->id,
            'Event Cancelled',
            'Event was cancelled.',
            'event_cancellation',
            ['event_id' => 1]
        );
        $this->assertNotNull($n5);
        $this->assertEquals(NotificationService::SOUND_CHIME_07, $n5->payload['sound']);
        $this->assertEquals(NotificationService::NOTIFICATION_CHANNEL_ID, $n5->payload['channel_id']);
    }

    public function test_sound_is_not_attached_to_non_sound_categories(): void
    {
        $studentUser = User::where('role_id', 3)->first();

        // Registration confirmed
        $n1 = NotificationService::send(
            $studentUser->id,
            'Registered',
            'Registration confirmed.',
            'registration_confirmed',
            ['event_id' => 1]
        );
        $this->assertNotNull($n1);
        $this->assertArrayNotHasKey('sound', $n1->payload ?? []);

        // Attendance recorded
        $n2 = NotificationService::send(
            $studentUser->id,
            'Attendance',
            'Check-in recorded.',
            'attendance_recorded',
            ['event_id' => 1]
        );
        $this->assertNotNull($n2);
        $this->assertArrayNotHasKey('sound', $n2->payload ?? []);

        // Waiting list promoted
        $n3 = NotificationService::send(
            $studentUser->id,
            'Promoted',
            'Slot opened.',
            'waiting_list_promoted',
            ['event_id' => 1]
        );
        $this->assertNotNull($n3);
        $this->assertArrayNotHasKey('sound', $n3->payload ?? []);
    }

    public function test_unread_count_endpoint_and_after_id_filtering(): void
    {
        $studentUser = User::where('role_id', 3)->first();

        // Log in as student to get token
        $loginRes = $this->postJson('/api/v1/auth/login', [
            'login' => $studentUser->email,
            'password' => 'Student@12345',
        ]);
        $token = $loginRes->json('data.token');

        // Clean existing notifications
        Notification::where('user_id', $studentUser->id)->delete();

        // 1. Initial unread count should be 0
        $countRes = $this->requestAs($token, 'GET', '/api/v1/notifications/unread-count');
        $countRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'unread_count' => 0,
                'latest_id' => 0,
            ]);

        // 2. Create two notifications
        $n1 = NotificationService::send(
            $studentUser->id,
            'Notice 1',
            'First notification.',
            'admin_announcement'
        );
        $n2 = NotificationService::send(
            $studentUser->id,
            'Notice 2',
            'Second notification.',
            'admin_announcement'
        );

        // Verify unread count is 2 and latest_id is $n2->id
        $countRes2 = $this->requestAs($token, 'GET', '/api/v1/notifications/unread-count');
        $countRes2->assertStatus(200)
            ->assertJson([
                'success' => true,
                'unread_count' => 2,
                'latest_id' => $n2->id,
            ]);

        // 3. Query with after_id = $n1->id: only $n2 should be returned
        $afterRes = $this->requestAs($token, 'GET', "/api/v1/notifications?after_id={$n1->id}");
        $afterRes->assertStatus(200);
        $items = $afterRes->json('data');
        $this->assertCount(1, $items);
        $this->assertEquals($n2->id, $items[0]['id']);
    }

    public function test_fcm_dispatch_with_mocked_http_prunes_unregistered_tokens(): void
    {
        $studentUser = User::where('role_id', 3)->first();
        \App\Models\DeviceToken::where('user_id', $studentUser->id)->delete();

        $validToken = \App\Models\DeviceToken::create([
            'user_id' => $studentUser->id,
            'fcm_token' => 'valid_fcm_token_123',
            'platform' => 'android',
        ]);

        $expiredToken = \App\Models\DeviceToken::create([
            'user_id' => $studentUser->id,
            'fcm_token' => 'expired_fcm_token_456',
            'platform' => 'android',
        ]);

        // Set fake server key
        config(['services.fcm.server_key' => 'fake_server_key']);

        \Illuminate\Support\Facades\Http::fake([
            'https://fcm.googleapis.com/fcm/send' => \Illuminate\Support\Facades\Http::response([
                'multicast_id' => 12345,
                'success' => 1,
                'failure' => 1,
                'canonical_ids' => 0,
                'results' => [
                    ['message_id' => '0:123456789'],
                    ['error' => 'NotRegistered'],
                ],
            ], 200),
        ]);

        // Trigger notification send
        $notif = NotificationService::send(
            $studentUser->id,
            'Broadcast',
            'Important announcement.',
            'admin_announcement'
        );

        $this->assertNotNull($notif);

        // Verify expired token was pruned and valid token remained
        $this->assertDatabaseHas('device_tokens', ['fcm_token' => 'valid_fcm_token_123']);
        $this->assertDatabaseMissing('device_tokens', ['fcm_token' => 'expired_fcm_token_456']);
    }

    public function test_device_token_registration_and_removal_with_web_platform(): void
    {
        $studentUser = User::where('role_id', 3)->first();

        $loginRes = $this->postJson('/api/v1/auth/login', [
            'login' => $studentUser->email,
            'password' => 'Student@12345',
        ]);
        $token = $loginRes->json('data.token');

        // Register web device token via /device-tokens
        $registerRes = $this->requestAs($token, 'POST', '/api/v1/device-tokens', [
            'fcm_token' => 'web_token_fcm_xyz123',
            'platform' => 'web',
        ]);

        $registerRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Device token registered successfully for push notifications.',
            ]);

        $this->assertDatabaseHas('device_tokens', [
            'user_id' => $studentUser->id,
            'fcm_token' => 'web_token_fcm_xyz123',
            'platform' => 'web',
        ]);

        // Deregister web device token
        $deleteRes = $this->requestAs($token, 'DELETE', '/api/v1/device-tokens', [
            'fcm_token' => 'web_token_fcm_xyz123',
        ]);

        $deleteRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Device token removed.',
            ]);

        $this->assertDatabaseMissing('device_tokens', [
            'fcm_token' => 'web_token_fcm_xyz123',
        ]);
    }

    public function test_notification_cancellation_reaches_both_registered_and_waitlisted_attendees(): void
    {
        $adminLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'admin@school.edu',
            'password' => 'Admin@12345',
        ]);
        $adminToken = $adminLogin->json('data.token');

        $organizer = User::where('role_id', 2)->first();
        $event = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'Annual Hackathon',
            'description' => 'Coding competition',
            'venue' => 'Innovation Lab',
            'event_date' => now()->addDays(10)->toDateString(),
            'start_time' => '09:00:00',
            'end_time' => '17:00:00',
            'registration_start' => now()->subDay(),
            'registration_end' => now()->addDays(8),
            'max_participants' => 50,
            'status' => 'published',
        ]);

        $studentUsers = User::where('role_id', 3)->has('student')->take(3)->get();
        $this->assertGreaterThanOrEqual(2, $studentUsers->count());

        $registeredUser = $studentUsers[0];
        $waitlistedUser = $studentUsers[1];
        $unregisteredUser = $studentUsers->count() > 2 ? $studentUsers[2] : null;

        $event->registrations()->create([
            'student_id' => $registeredUser->student->id,
            'status' => 'registered',
            'registered_at' => now(),
        ]);

        $event->registrations()->create([
            'student_id' => $waitlistedUser->student->id,
            'status' => 'waiting_list',
            'waiting_list_position' => 1,
            'registered_at' => now(),
        ]);

        // Clean existing notifications for these users
        Notification::whereIn('user_id', $studentUsers->pluck('id'))->delete();

        // Admin approves cancellation
        $reviewResp = $this->requestAs($adminToken, 'POST', "/api/v1/admin/events/{$event->id}/review-cancellation", [
            'action' => 'approved',
            'remarks' => 'Facility renovation conflict',
        ]);
        $reviewResp->assertStatus(200);

        // Both registered and waitlisted receive cancellation notification
        $this->assertDatabaseHas('notifications', [
            'user_id' => $registeredUser->id,
            'notification_type' => 'event_cancellation',
        ]);

        $this->assertDatabaseHas('notifications', [
            'user_id' => $waitlistedUser->id,
            'notification_type' => 'event_cancellation',
        ]);

        if ($unregisteredUser) {
            $this->assertDatabaseMissing('notifications', [
                'user_id' => $unregisteredUser->id,
                'notification_type' => 'event_cancellation',
            ]);
        }
    }

    public function test_fcm_payload_contains_click_action_channel_sound_and_notification_id(): void
    {
        $studentUser = User::where('role_id', 3)->first();
        \App\Models\DeviceToken::where('user_id', $studentUser->id)->delete();

        \App\Models\DeviceToken::create([
            'user_id' => $studentUser->id,
            'fcm_token' => 'fcm_payload_test_token_789',
            'platform' => 'android',
        ]);

        config(['services.fcm.server_key' => 'test_fcm_server_key']);

        \Illuminate\Support\Facades\Http::fake([
            'https://fcm.googleapis.com/fcm/send' => \Illuminate\Support\Facades\Http::response([
                'multicast_id' => 99999,
                'success' => 1,
                'failure' => 0,
                'canonical_ids' => 0,
                'results' => [['message_id' => '0:payload123']],
            ], 200),
        ]);

        $notif = NotificationService::send(
            $studentUser->id,
            'Targeted Alert',
            'Please proceed to Hall A.',
            'event_reminder_1h',
            ['event_id' => 42]
        );

        $this->assertNotNull($notif);

        \Illuminate\Support\Facades\Http::assertSent(function ($request) use ($notif) {
            $data = $request->data();

            // Verify top-level registration_ids
            $hasToken = in_array('fcm_payload_test_token_789', $data['registration_ids'] ?? [], true);

            // Verify notification block
            $notifBlock = $data['notification'] ?? [];
            $hasNotifClickAction = ($notifBlock['click_action'] ?? null) === 'FLUTTER_NOTIFICATION_CLICK';
            $hasNotifChannel = ($notifBlock['channel_id'] ?? null) === NotificationService::NOTIFICATION_CHANNEL_ID;
            $hasNotifSound = ($notifBlock['sound'] ?? null) === NotificationService::SOUND_CHIME_07;

            // Verify data block
            $dataBlock = $data['data'] ?? [];
            $hasDataClickAction = ($dataBlock['click_action'] ?? null) === 'FLUTTER_NOTIFICATION_CLICK';
            $hasDataChannel = ($dataBlock['channel_id'] ?? null) === NotificationService::NOTIFICATION_CHANNEL_ID;
            $hasDataSound = ($dataBlock['sound'] ?? null) === NotificationService::SOUND_CHIME_07;
            $hasNotifId = ($dataBlock['notification_id'] ?? null) === (string) $notif->id;
            $hasNotifType = ($dataBlock['notification_type'] ?? null) === 'event_reminder_1h';
            $hasEventId = ($dataBlock['event_id'] ?? null) === '42';

            return $hasToken
                && $hasNotifClickAction
                && $hasNotifChannel
                && $hasNotifSound
                && $hasDataClickAction
                && $hasDataChannel
                && $hasDataSound
                && $hasNotifId
                && $hasNotifType
                && $hasEventId;
        });
    }

    public function test_fcm_http_v1_dispatch_with_mocked_jwt_and_google_api(): void
    {
        // 1. Generate ephemeral RSA key pair for testing without hardcoding private keys
        $sslConfig = [];
        if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
            $candidateConfigs = [
                'C:/xampp/apache/conf/openssl.cnf',
                'C:/xampp/php/extras/ssl/openssl.cnf',
                getenv('OPENSSL_CONF'),
            ];
            foreach ($candidateConfigs as $cand) {
                if ($cand && file_exists($cand)) {
                    $sslConfig['config'] = $cand;
                    break;
                }
            }
        }

        $rsaKey = openssl_pkey_new(array_merge([
            'private_key_bits' => 1024,
            'private_key_type' => OPENSSL_KEYTYPE_RSA,
        ], $sslConfig));

        $privateKeyPem = '';
        openssl_pkey_export($rsaKey, $privateKeyPem, null, $sslConfig);

        // 2. Set Firebase service account config
        config([
            'services.firebase.project_id' => 'attendify-school-app',
            'services.firebase.client_email' => 'firebase-adminsdk@attendify-school-app.iam.gserviceaccount.com',
            'services.firebase.private_key' => $privateKeyPem,
            'services.fcm.server_key' => null,
        ]);

        \Illuminate\Support\Facades\Cache::forget('fcm_v1_access_token');

        // 3. Prepare user & device tokens
        $studentUser = User::where('role_id', 3)->first();
        \App\Models\DeviceToken::where('user_id', $studentUser->id)->delete();

        \App\Models\DeviceToken::create([
            'user_id' => $studentUser->id,
            'fcm_token' => 'fcm_v1_active_device_token_abc',
            'platform' => 'android',
        ]);

        \App\Models\DeviceToken::create([
            'user_id' => $studentUser->id,
            'fcm_token' => 'fcm_v1_stale_device_token_xyz',
            'platform' => 'android',
        ]);

        // 4. Mock Google OAuth 2.0 & FCM HTTP v1 API
        \Illuminate\Support\Facades\Http::fake([
            'https://oauth2.googleapis.com/token' => \Illuminate\Support\Facades\Http::response([
                'access_token' => 'mock_google_oauth_bearer_token_777',
                'expires_in' => 3600,
                'token_type' => 'Bearer',
            ], 200),
            'https://fcm.googleapis.com/v1/projects/attendify-school-app/messages:send' => function ($request) {
                $payload = $request->data();
                $token = $payload['message']['token'] ?? null;

                if ($token === 'fcm_v1_active_device_token_abc') {
                    return \Illuminate\Support\Facades\Http::response([
                        'name' => 'projects/attendify-school-app/messages/msg_valid_123',
                    ], 200);
                }

                if ($token === 'fcm_v1_stale_device_token_xyz') {
                    return \Illuminate\Support\Facades\Http::response([
                        'error' => [
                            'code' => 404,
                            'message' => 'Requested entity was not found.',
                            'status' => 'NOT_FOUND',
                            'details' => [
                                [
                                    '@type' => 'type.googleapis.com/google.firebase.fcm.v1.FcmError',
                                    'errorCode' => 'UNREGISTERED',
                                ],
                            ],
                        ],
                    ], 404);
                }

                return \Illuminate\Support\Facades\Http::response(['error' => ['code' => 400]], 400);
            },
        ]);

        // 5. Send notification
        $notif = NotificationService::send(
            $studentUser->id,
            'V1 System Announcement',
            'All school operations normal.',
            'admin_announcement',
            ['event_id' => 88]
        );

        $this->assertNotNull($notif);

        // 6. Verify OAuth token was requested using signed JWT
        \Illuminate\Support\Facades\Http::assertSent(function ($request) {
            if ($request->url() === 'https://oauth2.googleapis.com/token') {
                $data = $request->data();
                $jwt = $data['assertion'] ?? '';
                $parts = explode('.', $jwt);

                return ($data['grant_type'] ?? '') === 'urn:ietf:params:oauth:grant-type:jwt-bearer'
                    && count($parts) === 3;
            }
            return false;
        });

        // 7. Verify OAuth token was cached
        $this->assertEquals('mock_google_oauth_bearer_token_777', \Illuminate\Support\Facades\Cache::get('fcm_v1_access_token'));

        // 8. Verify FCM HTTP v1 dispatch payload and Bearer token
        \Illuminate\Support\Facades\Http::assertSent(function ($request) use ($notif) {
            if ($request->url() === 'https://fcm.googleapis.com/v1/projects/attendify-school-app/messages:send') {
                $authHeader = $request->header('Authorization');
                $hasBearer = is_array($authHeader)
                    ? in_array('Bearer mock_google_oauth_bearer_token_777', $authHeader, true)
                    : ($authHeader === 'Bearer mock_google_oauth_bearer_token_777');

                $data = $request->data();
                $msg = $data['message'] ?? [];
                if (($msg['token'] ?? null) === 'fcm_v1_active_device_token_abc') {
                    $notifBlock = $msg['notification'] ?? [];
                    $androidBlock = $msg['android'] ?? [];
                    $androidNotif = $androidBlock['notification'] ?? [];
                    $dataBlock = $msg['data'] ?? [];

                    return $hasBearer
                        && ($notifBlock['title'] ?? null) === 'V1 System Announcement'
                        && ($notifBlock['body'] ?? null) === 'All school operations normal.'
                        && ($androidBlock['priority'] ?? null) === 'HIGH'
                        && ($androidNotif['channel_id'] ?? null) === 'attendify_important_v1'
                        && ($androidNotif['sound'] ?? null) === 'sfxmint_ready_chime_07'
                        && ($androidNotif['click_action'] ?? null) === 'FLUTTER_NOTIFICATION_CLICK'
                        && ($androidNotif['notification_priority'] ?? null) === 'PRIORITY_MAX'
                        && ($androidNotif['default_vibrate_timings'] ?? null) === true
                        && ($dataBlock['notification_id'] ?? null) === (string) $notif->id
                        && ($dataBlock['notification_type'] ?? null) === 'admin_announcement'
                        && ($dataBlock['title'] ?? null) === 'V1 System Announcement'
                        && ($dataBlock['message'] ?? null) === 'All school operations normal.'
                        && ($dataBlock['event_id'] ?? null) === '88';
                }
            }
            return false;
        });

        // 9. Verify token pruning on UNREGISTERED response
        $this->assertDatabaseHas('device_tokens', ['fcm_token' => 'fcm_v1_active_device_token_abc']);
        $this->assertDatabaseMissing('device_tokens', ['fcm_token' => 'fcm_v1_stale_device_token_xyz']);
    }
}
