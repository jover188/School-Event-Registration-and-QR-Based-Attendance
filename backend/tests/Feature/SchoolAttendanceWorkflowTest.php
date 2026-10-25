<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\Role;
use App\Models\Student;
use App\Models\StudentQR;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SchoolAttendanceWorkflowTest extends TestCase
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

    public function test_student_can_login_with_numeric_student_id(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'token',
                    'user' => ['id', 'email', 'role'],
                    'student_profile' => ['student_id_number', 'full_name'],
                ],
            ]);

        $this->assertEquals('20260001', $response->json('data.student_profile.student_id_number'));
    }

    public function test_single_active_session_enforcement(): void
    {
        // 1. Device 1 login
        $login1 = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);
        $token1 = $login1->json('data.token');

        // Verify device 1 works
        $profile1 = $this->requestAs($token1, 'GET', '/api/v1/profile');
        $profile1->assertStatus(200);

        // 2. Device 2 login (terminates device 1)
        $login2 = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);
        $token2 = $login2->json('data.token');

        // 3. Device 1 attempts subsequent request -> must be rejected with 401
        $profile1Retry = $this->requestAs($token1, 'GET', '/api/v1/profile');
        $profile1Retry->assertStatus(401);

        // 4. Device 2 works cleanly
        $profile2 = $this->requestAs($token2, 'GET', '/api/v1/profile');
        $profile2->assertStatus(200);
    }

    public function test_student_can_fetch_and_reissue_permanent_qr(): void
    {
        $login = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);
        $token = $login->json('data.token');

        // 1. Get current permanent QR
        $qrResponse = $this->requestAs($token, 'GET', '/api/v1/student/qr');
        $qrResponse->assertStatus(200);
        $oldQrToken = $qrResponse->json('data.qr_token');
        $this->assertEquals(64, strlen($oldQrToken));

        // 2. Self-service reissue
        $reissueResponse = $this->requestAs($token, 'POST', '/api/v1/student/qr/reissue');
        $reissueResponse->assertStatus(200);
        $newQrToken = $reissueResponse->json('data.new_qr_token');

        $this->assertNotEquals($oldQrToken, $newQrToken);
        $this->assertEquals(64, strlen($newQrToken));
    }

    public function test_full_attendance_checkin_and_checkout_workflow(): void
    {
        // 1. Organizer Login
        $orgLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'organizer@school.edu',
            'password' => 'Organizer@12345',
        ]);
        $orgToken = $orgLogin->json('data.token');

        // 2. Create and Publish Event
        $event = Event::create([
            'organizer_id' => $orgLogin->json('data.user.id'),
            'title' => 'Annual Robotics Expo 2026',
            'description' => 'Showcase of school robotics projects',
            'venue' => 'Gymnasium',
            'event_date' => now()->toDateString(),
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
            'registration_start' => now()->subDay(),
            'registration_end' => now()->addDay(),
            'max_participants' => 50,
            'late_grace_period_minutes' => 15,
            'walk_in_allowed' => true,
            'status' => 'published',
        ]);

        // 3. Student Login & Register
        $studentLogin = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);
        $studentToken = $studentLogin->json('data.token');

        $regResponse = $this->requestAs($studentToken, 'POST', "/api/v1/events/{$event->id}/register");
        $regResponse->assertStatus(201);
        $this->assertEquals('registered', $regResponse->json('data.status'));

        // 4. Get Student Active QR Token
        $qrResp = $this->requestAs($studentToken, 'GET', '/api/v1/student/qr');
        $qrToken = $qrResp->json('data.qr_token');

        // 5. Organizer Scans QR (Check-In Mode)
        $scanResponse = $this->requestAs($orgToken, 'POST', "/api/v1/events/{$event->id}/attendance/scan", [
            'qr_token' => $qrToken,
            'mode' => 'check_in',
        ]);

        $scanResponse->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'attendance_id',
                    'status',
                    'student' => ['student_id_number', 'full_name'],
                ],
            ]);

        // 6. Duplicate Check-In Scan (Must fail with 409 Conflict)
        $dupScan = $this->requestAs($orgToken, 'POST', "/api/v1/events/{$event->id}/attendance/scan", [
            'qr_token' => $qrToken,
            'mode' => 'check_in',
        ]);
        $dupScan->assertStatus(409);

        // 7. Organizer Scans QR (Check-Out Mode)
        $checkOutResponse = $this->requestAs($orgToken, 'POST', "/api/v1/events/{$event->id}/attendance/scan", [
            'qr_token' => $qrToken,
            'mode' => 'check_out',
        ]);
        $checkOutResponse->assertStatus(200);
        $this->assertNotNull($checkOutResponse->json('data.check_out_time'));
    }

    public function test_waiting_list_auto_promotion_on_cancellation(): void
    {
        // 1. Create a capped event (capacity: 1)
        $organizer = User::where('role_id', 2)->first();
        $event = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'Exclusive Hackathon',
            'description' => 'Single-slot exclusive competition',
            'venue' => 'Lab 301',
            'event_date' => now()->addDays(5)->toDateString(),
            'start_time' => '09:00:00',
            'end_time' => '17:00:00',
            'registration_start' => now()->subDay(),
            'registration_end' => now()->addDays(2),
            'max_participants' => 1,
            'status' => 'published',
        ]);

        // Student 1 (Juan, seeded) registers and takes the only slot
        $student1Login = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);
        $token1 = $student1Login->json('data.token');

        $reg1 = $this->requestAs($token1, 'POST', "/api/v1/events/{$event->id}/register");
        $reg1->assertStatus(201);
        $this->assertEquals('registered', $reg1->json('data.status'));

        // Student 2 registers -> Capacity reached -> Placed on Waiting List
        $student2User = User::create([
            'role_id' => 3,
            'email' => 'student2@school.edu',
            'password' => bcrypt('Student2@12345'),
            'status' => 'active',
            'email_verified_at' => now(),
        ]);
        $student2 = Student::create([
            'user_id' => $student2User->id,
            'student_id_number' => '20260002',
            'first_name' => 'Maria',
            'last_name' => 'Santos',
            'course' => 'BS Information Technology',
            'year_level' => '2nd Year',
            'section' => 'IT-2B',
            'department' => 'College of Computer Studies',
            'contact_number' => '+639189876543',
        ]);
        $student2Login = $this->postJson('/api/v1/auth/login', [
            'login' => '20260002',
            'password' => 'Student2@12345',
        ]);
        $token2 = $student2Login->json('data.token');

        $reg2 = $this->requestAs($token2, 'POST', "/api/v1/events/{$event->id}/register");
        $reg2->assertStatus(201);
        $this->assertEquals('waiting_list', $reg2->json('data.status'));
        $this->assertEquals(1, $reg2->json('data.waiting_list_position'));

        // Student 1 cancels registration -> Triggers atomic auto-promotion of Student 2
        $cancel1 = $this->requestAs($token1, 'DELETE', "/api/v1/events/{$event->id}/cancel-registration");
        $cancel1->assertStatus(200);

        // Verify Student 2 is now auto-promoted to 'registered'
        $this->assertDatabaseHas('event_registrations', [
            'event_id' => $event->id,
            'student_id' => $student2->id,
            'status' => 'registered',
            'waiting_list_position' => null,
        ]);
    }

    public function test_walk_in_from_waiting_list_resequences_remaining_positions(): void
    {
        $organizer = User::where('role_id', 2)->first();
        $event = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'Walk-in Waitlist Test Event',
            'description' => 'Testing waitlist re-sequencing on walk-in',
            'venue' => 'Room 101',
            'event_date' => now()->toDateString(),
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
            'registration_start' => now()->subDay(),
            'registration_end' => now()->addDay(),
            'max_participants' => 1,
            'walk_in_allowed' => true,
            'status' => 'published',
        ]);

        // Student 1 takes slot 1 (registered)
        $s1 = Student::where('student_id_number', '20260001')->first();
        $event->registrations()->create([
            'student_id' => $s1->id,
            'status' => 'registered',
            'registered_at' => now(),
        ]);

        // Student 2 is waiting #1
        $u2 = User::create(['role_id' => 3, 'email' => 's2@school.edu', 'password' => bcrypt('Pass@1234'), 'status' => 'active']);
        $s2 = Student::create([
            'user_id' => $u2->id, 'student_id_number' => '20260002', 'first_name' => 'Two', 'last_name' => 'Student',
            'course' => 'BSCS', 'year_level' => '1st Year', 'section' => 'A', 'department' => 'CCS', 'contact_number' => '09170000002',
        ]);
        $qr2 = StudentQR::create(['student_id' => $s2->id, 'qr_token' => str_repeat('b', 64), 'status' => 'active']);
        $event->registrations()->create([
            'student_id' => $s2->id,
            'status' => 'waiting_list',
            'waiting_list_position' => 1,
            'registered_at' => now(),
        ]);

        // Student 3 is waiting #2
        $u3 = User::create(['role_id' => 3, 'email' => 's3@school.edu', 'password' => bcrypt('Pass@1234'), 'status' => 'active']);
        $s3 = Student::create([
            'user_id' => $u3->id, 'student_id_number' => '20260003', 'first_name' => 'Three', 'last_name' => 'Student',
            'course' => 'BSCS', 'year_level' => '1st Year', 'section' => 'A', 'department' => 'CCS', 'contact_number' => '09170000003',
        ]);
        $event->registrations()->create([
            'student_id' => $s3->id,
            'status' => 'waiting_list',
            'waiting_list_position' => 2,
            'registered_at' => now(),
        ]);

        // Organizer scans Student 2 as walk-in
        $orgLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'organizer@school.edu',
            'password' => 'Organizer@12345',
        ]);
        $orgToken = $orgLogin->json('data.token');

        $scan = $this->requestAs($orgToken, 'POST', "/api/v1/events/{$event->id}/attendance/scan", [
            'qr_token' => $qr2->qr_token,
            'mode' => 'check_in',
        ]);
        $scan->assertStatus(200);
        $this->assertEquals('walk_in', $scan->json('data.status'));

        // Student 3 should now be at waiting_list_position 1
        $this->assertDatabaseHas('event_registrations', [
            'event_id' => $event->id,
            'student_id' => $s3->id,
            'status' => 'waiting_list',
            'waiting_list_position' => 1,
        ]);
    }

    public function test_profile_update_and_password_change_compatibility(): void
    {
        $login = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ]);
        $token = $login->json('data.token');

        // Students are rejected from mutating profile (institutional records are immutable)
        $updateResp = $this->requestAs($token, 'POST', '/api/v1/profile', [
            'section' => 'CS-4Z',
            'contact_number' => '+639991112233',
        ]);
        $updateResp->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'ERR_STUDENT_PROFILE_IMMUTABLE',
            ]);

        // Students are rejected from changing password via API
        $studentPwResp = $this->requestAs($token, 'POST', '/api/v1/profile/change-password', [
            'current_password' => 'Student@12345',
            'new_password' => 'NewPass@12345',
            'new_password_confirmation' => 'NewPass@12345',
        ]);
        $studentPwResp->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'ERR_STUDENT_PASSWORD_CHANGE_DISABLED',
            ]);

        // Staff accounts (organizer) retain password change capability
        $orgLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'organizer@school.edu',
            'password' => 'Organizer@12345',
        ]);
        $orgToken = $orgLogin->json('data.token');

        $orgPwResp = $this->requestAs($orgToken, 'POST', '/api/v1/profile/change-password', [
            'current_password' => 'Organizer@12345',
            'new_password' => 'NewStaffPass@12345',
            'new_password_confirmation' => 'NewStaffPass@12345',
        ]);
        $orgPwResp->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Password updated successfully.',
            ]);
    }
}

