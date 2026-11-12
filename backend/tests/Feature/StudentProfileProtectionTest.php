<?php

namespace Tests\Feature;

use App\Models\ActivityLog;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StudentProfileProtectionTest extends TestCase
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

    public function test_student_can_only_update_contact_number_and_protected_fields_are_silently_ignored(): void
    {
        $login = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);
        $login->assertStatus(200);
        $token = $login->json('data.token');

        $student = Student::where('student_id_number', '20260001')->first();
        $originalFirstName = $student->first_name;
        $originalLastName = $student->last_name;
        $originalCourse = $student->course;
        $originalYearLevel = $student->year_level;
        $originalSection = $student->section;
        $originalDept = $student->department;

        // Student attempts to update protected fields alongside contact_number
        $updateResp = $this->requestAs($token, 'PUT', '/api/v1/profile', [
            'first_name' => 'TamperedFirst',
            'last_name' => 'TamperedLast',
            'course' => 'BS Mechanical Engineering',
            'year_level' => '4th Year',
            'section' => 'ME-4A',
            'department' => 'College of Engineering',
            'contact_number' => '+639123334455',
        ]);

        $updateResp->assertStatus(200)
            ->assertJsonPath('success', true);

        // contact_number must be updated
        $this->assertEquals('+639123334455', $updateResp->json('data.contact_number'));
        $this->assertEquals('+639123334455', $updateResp->json('data.student_profile.contact_number'));

        // Protected fields must remain unchanged
        $this->assertEquals($originalFirstName, $updateResp->json('data.student_profile.first_name'));
        $this->assertEquals($originalLastName, $updateResp->json('data.student_profile.last_name'));
        $this->assertEquals($originalCourse, $updateResp->json('data.student_profile.course'));
        $this->assertEquals($originalYearLevel, $updateResp->json('data.student_profile.year_level'));
        $this->assertEquals($originalSection, $updateResp->json('data.student_profile.section'));
        $this->assertEquals($originalDept, $updateResp->json('data.student_profile.department'));

        $student->refresh();
        $this->assertEquals('+639123334455', $student->contact_number);
        $this->assertEquals($originalFirstName, $student->first_name);
        $this->assertEquals($originalLastName, $student->last_name);
        $this->assertEquals($originalCourse, $student->course);

        // Verify activity log was recorded
        $this->assertDatabaseHas('activity_logs', [
            'action' => 'profile_updated',
            'module' => 'auth',
            'user_id' => $student->user_id,
        ]);
    }

    public function test_admin_can_update_student_profile_fields(): void
    {
        $adminLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'admin@school.edu',
            'password' => 'Admin@12345',
        ]);
        $adminToken = $adminLogin->json('data.token');
        $adminId = $adminLogin->json('data.user.id');

        $student = Student::where('student_id_number', '20260001')->first();

        $updateResp = $this->requestAs($adminToken, 'PUT', "/api/v1/admin/students/{$student->id}/profile", [
            'first_name' => 'Juan Carlos',
            'middle_name' => 'Silang',
            'last_name' => 'Dela Cruz Jr.',
            'course' => 'BS Computer Science',
            'year_level' => '4th Year',
            'section' => 'CS-4A',
            'department' => 'College of Computer Studies',
            'contact_number' => '+639171239999',
            'student_id_number' => '99999999', // immutable, should be ignored
        ]);

        $updateResp->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.student_profile.first_name', 'Juan Carlos')
            ->assertJsonPath('data.student_profile.middle_name', 'Silang')
            ->assertJsonPath('data.student_profile.last_name', 'Dela Cruz Jr.')
            ->assertJsonPath('data.student_profile.course', 'BS Computer Science')
            ->assertJsonPath('data.student_profile.year_level', '4th Year')
            ->assertJsonPath('data.student_profile.section', 'CS-4A')
            ->assertJsonPath('data.student_profile.department', 'College of Computer Studies')
            ->assertJsonPath('data.student_profile.contact_number', '+639171239999')
            ->assertJsonPath('data.student_profile.student_id_number', '20260001');

        $student->refresh();
        $this->assertEquals('Juan Carlos', $student->first_name);
        $this->assertEquals('Silang', $student->middle_name);
        $this->assertEquals('Dela Cruz Jr.', $student->last_name);
        $this->assertEquals('20260001', $student->student_id_number);

        // Verify activity log
        $this->assertDatabaseHas('activity_logs', [
            'action' => 'admin_updated_student_profile',
            'module' => 'students',
            'record_id' => $student->id,
            'user_id' => $adminId,
        ]);
    }

    public function test_non_admin_cannot_access_admin_update_student_profile(): void
    {
        // 1. Student attempt
        $studentLogin = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);
        $studentToken = $studentLogin->json('data.token');
        $student = Student::where('student_id_number', '20260001')->first();

        $studentAttempt = $this->requestAs($studentToken, 'PUT', "/api/v1/admin/students/{$student->id}/profile", [
            'first_name' => 'IllegalUpdate',
        ]);
        $studentAttempt->assertStatus(403);

        // 2. Organizer attempt
        $orgLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'organizer@school.edu',
            'password' => 'Organizer@12345',
        ]);
        $orgToken = $orgLogin->json('data.token');

        $orgAttempt = $this->requestAs($orgToken, 'PUT', "/api/v1/admin/students/{$student->id}/profile", [
            'first_name' => 'IllegalUpdate',
        ]);
        $orgAttempt->assertStatus(403);
    }

    public function test_student_can_submit_profile_correction_request(): void
    {
        $login = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);
        $token = $login->json('data.token');
        $userId = $login->json('data.user.id');
        $student = Student::where('student_id_number', '20260001')->first();

        $resp = $this->requestAs($token, 'POST', '/api/v1/profile/correction-request', [
            'fields' => ['first_name', 'last_name'],
            'reason' => 'My surname was misspelled on my high school transcript registration.',
        ]);

        $resp->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Your correction request has been submitted. Management will review it.');

        // Verify request logged to activity_logs
        $log = ActivityLog::where('action', 'profile_correction_requested')
            ->where('module', 'students')
            ->where('record_id', $student->id)
            ->first();

        $this->assertNotNull($log);
        $this->assertEquals($userId, $log->user_id);
        $this->assertEquals(['first_name', 'last_name'], $log->metadata['fields']);
        $this->assertEquals('My surname was misspelled on my high school transcript registration.', $log->metadata['reason']);
        $this->assertEquals('20260001', $log->metadata['student_id_number']);

        // Data was not modified directly
        $student->refresh();
        $this->assertEquals('Juan', $student->first_name);
    }

    public function test_profile_correction_request_validation_and_role_protection(): void
    {
        $login = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);
        $token = $login->json('data.token');

        // Validation fails if fields array is empty
        $resp1 = $this->requestAs($token, 'POST', '/api/v1/profile/correction-request', [
            'fields' => [],
            'reason' => 'Valid reason with more than 10 characters',
        ]);
        $resp1->assertStatus(422);

        // Validation fails if reason is too short (< 10 chars)
        $resp2 = $this->requestAs($token, 'POST', '/api/v1/profile/correction-request', [
            'fields' => ['first_name'],
            'reason' => 'Short',
        ]);
        $resp2->assertStatus(422);

        // Non-student (e.g. Organizer) cannot call this endpoint
        $orgLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'organizer@school.edu',
            'password' => 'Organizer@12345',
        ]);
        $orgToken = $orgLogin->json('data.token');

        $orgResp = $this->requestAs($orgToken, 'POST', '/api/v1/profile/correction-request', [
            'fields' => ['first_name'],
            'reason' => 'Organizer requesting correction',
        ]);
        $orgResp->assertStatus(403);
    }
}
