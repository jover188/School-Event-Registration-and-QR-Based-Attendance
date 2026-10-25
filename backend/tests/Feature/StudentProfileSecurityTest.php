<?php

namespace Tests\Feature;

use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StudentProfileSecurityTest extends TestCase
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

    public function test_student_cannot_update_profile_information_via_put_or_post(): void
    {
        $login = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);
        $login->assertStatus(200);
        $token = $login->json('data.token');
        $userId = $login->json('data.user.id');

        $student = Student::where('student_id_number', '20260001')->firstOrFail();
        $originalFirstName = $student->first_name;

        // 1. Attempt PUT /api/v1/profile
        $putResponse = $this->requestAs($token, 'PUT', '/api/v1/profile', [
            'first_name' => 'Tampered',
            'section' => 'CS-99',
            'contact_number' => '09999999999',
        ]);

        $putResponse->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'ERR_STUDENT_PROFILE_IMMUTABLE',
                'message' => 'Students are not permitted to modify institutional profile information. Profile changes must be requested through the school registrar or administrator.',
            ]);

        // Student database record remains unmodified
        $this->assertDatabaseMissing('students', [
            'first_name' => 'Tampered',
        ]);
        $this->assertDatabaseHas('students', [
            'student_id_number' => '20260001',
            'first_name' => $originalFirstName,
        ]);

        // 2. Attempt POST /api/v1/profile
        $postResponse = $this->requestAs($token, 'POST', '/api/v1/profile', [
            'first_name' => 'TamperedPost',
            'section' => 'CS-99',
        ]);

        $postResponse->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'ERR_STUDENT_PROFILE_IMMUTABLE',
                'message' => 'Students are not permitted to modify institutional profile information. Profile changes must be requested through the school registrar or administrator.',
            ]);

        // 3. Assert security audit log exists
        $this->assertDatabaseHas('activity_logs', [
            'action' => 'unauthorized_profile_update_attempt',
            'user_id' => $userId,
        ]);
    }

    public function test_student_cannot_change_password_via_api(): void
    {
        $login = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);
        $login->assertStatus(200);
        $token = $login->json('data.token');
        $userId = $login->json('data.user.id');

        // Attempt POST /api/v1/profile/change-password
        $pwResponse = $this->requestAs($token, 'POST', '/api/v1/profile/change-password', [
            'current_password' => 'Student@12345',
            'new_password' => 'NewSecret@12345',
            'new_password_confirmation' => 'NewSecret@12345',
        ]);

        $pwResponse->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'ERR_STUDENT_PASSWORD_CHANGE_DISABLED',
                'message' => 'Student password changes are managed by institutional administration or SIS synchronization. Contact your administrator to reset credentials.',
            ]);

        // Assert student can still authenticate with old password
        $reLogin = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);
        $reLogin->assertStatus(200);

        // Assert security audit log exists
        $this->assertDatabaseHas('activity_logs', [
            'action' => 'unauthorized_password_change_attempt',
            'user_id' => $userId,
        ]);
    }

    public function test_staff_can_still_change_password(): void
    {
        $login = $this->postJson('/api/v1/auth/login', [
            'login' => 'organizer@school.edu',
            'password' => 'Organizer@12345',
        ]);
        $login->assertStatus(200);
        $token = $login->json('data.token');

        // Attempt POST /api/v1/profile/change-password
        $pwResponse = $this->requestAs($token, 'POST', '/api/v1/profile/change-password', [
            'current_password' => 'Organizer@12345',
            'new_password' => 'NewStaffPass@12345',
            'new_password_confirmation' => 'NewStaffPass@12345',
        ]);

        $pwResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Password updated successfully.',
            ]);

        // Verify organizer can login with new password
        $newLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'organizer@school.edu',
            'password' => 'NewStaffPass@12345',
        ]);
        $newLogin->assertStatus(200);
    }
}
