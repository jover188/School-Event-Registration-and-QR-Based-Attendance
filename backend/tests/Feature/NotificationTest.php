<?php

namespace Tests\Feature;

use App\Models\DeviceToken;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationTest extends TestCase
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

    /**
     * Test DeviceToken registration endpoint POST /api/v1/notifications/device-token
     * correctly stores token with authenticated user.
     */
    public function test_device_token_registration_stores_token_with_authenticated_user(): void
    {
        $studentUser = User::where('role_id', 3)->first();

        $loginRes = $this->postJson('/api/v1/auth/login', [
            'login' => $studentUser->email,
            'password' => 'Student@12345',
        ]);
        $token = $loginRes->json('data.token');

        $deviceToken = 'test_device_token_' . bin2hex(random_bytes(16));

        $res = $this->requestAs($token, 'POST', '/api/v1/notifications/device-token', [
            'fcm_token' => $deviceToken,
            'platform' => 'android',
        ]);

        $res->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Device token registered successfully for push notifications.',
            ]);

        $this->assertDatabaseHas('device_tokens', [
            'user_id' => $studentUser->id,
            'fcm_token' => $deviceToken,
            'platform' => 'android',
        ]);
    }

    /**
     * Test if token is registered by User A and then re-registered by User B,
     * it updates the user_id to User B (preventing duplicate delivery to old user).
     */
    public function test_device_token_re_registered_by_different_user_updates_user_id(): void
    {
        $students = User::where('role_id', 3)->take(2)->get();
        $this->assertCount(2, $students, 'Two students required for re-registration test.');

        $userA = $students[0];
        $userB = $students[1];

        // 1. User A logs in and registers the device token
        $loginA = $this->postJson('/api/v1/auth/login', [
            'login' => $userA->email,
            'password' => 'Student@12345',
        ]);
        $tokenA = $loginA->json('data.token');

        $sharedFcmToken = 'shared_hardware_device_token_' . bin2hex(random_bytes(12));

        $resA = $this->requestAs($tokenA, 'POST', '/api/v1/notifications/device-token', [
            'fcm_token' => $sharedFcmToken,
            'platform' => 'android',
        ]);
        $resA->assertStatus(200);

        $this->assertDatabaseHas('device_tokens', [
            'user_id' => $userA->id,
            'fcm_token' => $sharedFcmToken,
        ]);

        // 2. User B logs in on the same physical device and registers the same token
        $loginB = $this->postJson('/api/v1/auth/login', [
            'login' => $userB->email,
            'password' => 'Student@12345',
        ]);
        $tokenB = $loginB->json('data.token');

        $resB = $this->requestAs($tokenB, 'POST', '/api/v1/notifications/device-token', [
            'fcm_token' => $sharedFcmToken,
            'platform' => 'android',
        ]);
        $resB->assertStatus(200);

        // 3. Verify exactly 1 record exists with this FCM token, now belonging to User B
        $this->assertEquals(1, DeviceToken::where('fcm_token', $sharedFcmToken)->count());
        $this->assertDatabaseHas('device_tokens', [
            'user_id' => $userB->id,
            'fcm_token' => $sharedFcmToken,
        ]);
        $this->assertDatabaseMissing('device_tokens', [
            'user_id' => $userA->id,
            'fcm_token' => $sharedFcmToken,
        ]);
    }

    /**
     * Test NotificationService::getFirebaseCredentials() correctly parses a valid service account JSON string from FIREBASE_CREDENTIALS_JSON.
     */
    public function test_get_firebase_credentials_correctly_parses_valid_service_account_json_string(): void
    {
        $rawPrivateKey = "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCfakeKey...\n-----END PRIVATE KEY-----";
        $escapedPrivateKey = str_replace("\n", "\\n", $rawPrivateKey);

        $serviceAccountJson = json_encode([
            'type' => 'service_account',
            'project_id' => 'attendify-production-project',
            'private_key_id' => 'key_identifier_987654',
            'private_key' => $escapedPrivateKey,
            'client_email' => 'firebase-adminsdk-live@attendify-production-project.iam.gserviceaccount.com',
            'client_id' => '123456789012345678901',
            'auth_uri' => 'https://accounts.google.com/o/oauth2/auth',
            'token_uri' => 'https://oauth2.googleapis.com/token',
        ]);

        config([
            'services.firebase.credentials_json' => $serviceAccountJson,
            'services.firebase.credentials_path' => null,
            'services.firebase.project_id' => null,
            'services.firebase.client_email' => null,
            'services.firebase.private_key' => null,
        ]);

        $credentials = NotificationService::getFirebaseCredentials();

        $this->assertIsArray($credentials);
        $this->assertEquals('attendify-production-project', $credentials['project_id']);
        $this->assertEquals('firebase-adminsdk-live@attendify-production-project.iam.gserviceaccount.com', $credentials['client_email']);
        $this->assertStringContainsString("\n", $credentials['private_key']);
        $this->assertStringNotContainsString("\\n", $credentials['private_key']);
        $this->assertEquals($rawPrivateKey, $credentials['private_key']);
    }

    /**
     * Test NotificationService::getFirebaseCredentials() returns null when no credentials configured.
     */
    public function test_get_firebase_credentials_returns_null_when_unconfigured(): void
    {
        config([
            'services.firebase.credentials_json' => null,
            'services.firebase.credentials_path' => null,
            'services.firebase.project_id' => null,
            'services.firebase.client_email' => null,
            'services.firebase.private_key' => null,
        ]);
        putenv('FIREBASE_CREDENTIALS_JSON');
        putenv('FIREBASE_CREDENTIALS');
        putenv('FIREBASE_PROJECT_ID');
        putenv('FIREBASE_CLIENT_EMAIL');
        putenv('FIREBASE_PRIVATE_KEY');

        $this->assertNull(NotificationService::getFirebaseCredentials());
    }

    /**
     * Test Device token deregistration DELETE /api/v1/notifications/device-token removes token.
     */
    public function test_device_token_deregistration_removes_token(): void
    {
        $studentUser = User::where('role_id', 3)->first();

        $loginRes = $this->postJson('/api/v1/auth/login', [
            'login' => $studentUser->email,
            'password' => 'Student@12345',
        ]);
        $token = $loginRes->json('data.token');

        $fcmToken = 'device_to_remove_' . bin2hex(random_bytes(16));

        // First register
        $this->requestAs($token, 'POST', '/api/v1/notifications/device-token', [
            'fcm_token' => $fcmToken,
            'platform' => 'android',
        ])->assertStatus(200);

        $this->assertDatabaseHas('device_tokens', [
            'user_id' => $studentUser->id,
            'fcm_token' => $fcmToken,
        ]);

        // Then deregister via DELETE /api/v1/notifications/device-token
        $delRes = $this->requestAs($token, 'DELETE', '/api/v1/notifications/device-token', [
            'fcm_token' => $fcmToken,
        ]);

        $delRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Device token removed.',
            ]);

        $this->assertDatabaseMissing('device_tokens', [
            'fcm_token' => $fcmToken,
        ]);
    }

    public function test_fcm_diagnostic_endpoint_accessible_to_admin(): void
    {
        $adminUser = User::where('role_id', 1)->first();

        $loginRes = $this->postJson('/api/v1/auth/login', [
            'login' => $adminUser->email,
            'password' => 'Admin@12345',
        ]);
        $token = $loginRes->json('data.token');

        $res = $this->requestAs($token, 'GET', '/api/v1/admin/fcm-diagnostic');
        $res->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'firebase_credentials_resolved',
                    'device_tokens_total',
                    'recent_device_tokens',
                ],
            ]);
    }
}
