<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\AttendanceCorrection;
use App\Models\Event;
use App\Models\EventRegistration;
use App\Models\Student;
use App\Models\StudentQR;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthAndStaffOperationsTest extends TestCase
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

    public function test_verify_email_activates_pending_user_account(): void
    {
        $user = User::create([
            'role_id' => 3,
            'email' => 'pending.student@school.edu',
            'password' => bcrypt('Pending@12345'),
            'status' => 'pending',
            'email_verified_at' => null,
        ]);

        // Login before verification must fail with 403 ERR_EMAIL_UNVERIFIED
        $loginBefore = $this->postJson('/api/v1/auth/login', [
            'login' => 'pending.student@school.edu',
            'password' => 'Pending@12345',
        ]);
        $loginBefore->assertStatus(403)
            ->assertJsonPath('error_code', 'ERR_EMAIL_UNVERIFIED');

        // Verify email
        $verifyResp = $this->postJson('/api/v1/auth/verify-email', [
            'email' => 'pending.student@school.edu',
            'code' => '123456',
        ]);
        $verifyResp->assertStatus(200)
            ->assertJsonPath('success', true);

        $user->refresh();
        $this->assertEquals('active', $user->status);
        $this->assertNotNull($user->email_verified_at);

        // Login after verification succeeds
        $loginAfter = $this->postJson('/api/v1/auth/login', [
            'login' => 'pending.student@school.edu',
            'password' => 'Pending@12345',
        ]);
        $loginAfter->assertStatus(200);
    }

    public function test_forgot_password_and_reset_password_workflow(): void
    {
        $studentUser = User::where('role_id', 3)->first();
        $email = $studentUser->email;

        // 1. Request reset token
        $forgotResp = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => $email,
        ]);
        $forgotResp->assertStatus(200)
            ->assertJsonPath('success', true);

        $plainToken = $forgotResp->json('data.reset_token');
        $this->assertNotEmpty($plainToken);

        // 2. Reset password with token
        $resetResp = $this->postJson('/api/v1/auth/reset-password', [
            'email' => $email,
            'token' => $plainToken,
            'password' => 'ResetPass@999',
            'password_confirmation' => 'ResetPass@999',
        ]);
        $resetResp->assertStatus(200)
            ->assertJsonPath('success', true);

        // 3. Login with new password succeeds
        $loginResp = $this->postJson('/api/v1/auth/login', [
            'login' => $email,
            'password' => 'ResetPass@999',
        ]);
        $loginResp->assertStatus(200);
    }

    public function test_staff_can_cancel_registration_and_promote_waiting_list(): void
    {
        $orgLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'organizer@school.edu',
            'password' => 'Organizer@12345',
        ]);
        $orgToken = $orgLogin->json('data.token');
        $organizerId = $orgLogin->json('data.user.id');

        $event = Event::create([
            'organizer_id' => $organizerId,
            'title' => 'Capped Seminar',
            'description' => 'Seminar with 1 slot',
            'venue' => 'Room 202',
            'event_date' => now()->addDays(3)->toDateString(),
            'start_time' => '09:00:00',
            'end_time' => '12:00:00',
            'registration_start' => now()->subDay(),
            'registration_end' => now()->addDays(2),
            'max_participants' => 1,
            'status' => 'published',
        ]);

        $s1 = Student::where('student_id_number', '20260001')->first();
        $reg1 = EventRegistration::create([
            'event_id' => $event->id,
            'student_id' => $s1->id,
            'status' => 'registered',
            'registered_at' => now(),
        ]);

        $u2 = User::create([
            'role_id' => 3,
            'email' => 'waitstudent@school.edu',
            'password' => bcrypt('Pass@12345'),
            'status' => 'active',
        ]);
        $s2 = Student::create([
            'user_id' => $u2->id,
            'student_id_number' => '20260099',
            'first_name' => 'Wait',
            'last_name' => 'Candidate',
            'course' => 'BSIT',
            'year_level' => '2nd Year',
            'section' => 'IT-2A',
            'department' => 'CCS',
            'contact_number' => '09171234567',
        ]);
        $reg2 = EventRegistration::create([
            'event_id' => $event->id,
            'student_id' => $s2->id,
            'status' => 'waiting_list',
            'waiting_list_position' => 1,
            'registered_at' => now(),
        ]);

        $cancelResp = $this->requestAs(
            $orgToken,
            'DELETE',
            "/api/v1/events/{$event->id}/registrations/{$reg1->id}"
        );
        $cancelResp->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('event_registrations', [
            'id' => $reg1->id,
            'status' => 'cancelled',
        ]);

        $this->assertDatabaseHas('event_registrations', [
            'id' => $reg2->id,
            'status' => 'registered',
            'waiting_list_position' => null,
        ]);
    }

    public function test_admin_can_reissue_student_qr_code(): void
    {
        $adminLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'admin@school.edu',
            'password' => 'Admin@12345',
        ]);
        $adminToken = $adminLogin->json('data.token');

        $student = Student::where('student_id_number', '20260001')->first();
        $oldToken = $student->activeQr?->qr_token;

        $reissueResp = $this->requestAs(
            $adminToken,
            'POST',
            "/api/v1/admin/students/{$student->id}/qr/reissue"
        );

        $reissueResp->assertStatus(200)
            ->assertJsonPath('success', true);

        $newToken = $reissueResp->json('data.new_qr_token');
        $this->assertEquals(64, strlen($newToken));
        $this->assertNotEquals($oldToken, $newToken);

        if ($oldToken) {
            $this->assertDatabaseHas('student_qrs', [
                'student_id' => $student->id,
                'qr_token' => $oldToken,
                'status' => 'revoked',
            ]);
        }
    }

    public function test_organizer_can_manually_mark_attendance_including_absent_and_excused(): void
    {
        $orgLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'organizer@school.edu',
            'password' => 'Organizer@12345',
        ]);
        $orgToken = $orgLogin->json('data.token');
        $organizerId = $orgLogin->json('data.user.id');

        $event = Event::create([
            'organizer_id' => $organizerId,
            'title' => 'Manual Mark Test Event',
            'description' => 'Event for testing manual attendance marking',
            'venue' => 'Auditorium',
            'event_date' => now()->toDateString(),
            'start_time' => '08:00:00',
            'end_time' => '17:00:00',
            'registration_start' => now()->subDay(),
            'registration_end' => now()->addDay(),
            'max_participants' => 50,
            'status' => 'ongoing',
        ]);

        $student = Student::where('student_id_number', '20260001')->first();
        EventRegistration::create([
            'event_id' => $event->id,
            'student_id' => $student->id,
            'status' => 'registered',
            'registered_at' => now(),
        ]);

        // Mark student as excused manually
        $markResp = $this->requestAs($orgToken, 'POST', "/api/v1/events/{$event->id}/attendance/mark", [
            'student_id' => $student->id,
            'status' => 'excused',
            'reason' => 'Submitted medical certificate from clinic.',
        ]);

        $markResp->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'excused');

        $this->assertDatabaseHas('attendances', [
            'event_id' => $event->id,
            'student_id' => $student->id,
            'status' => 'excused',
        ]);

        $this->assertDatabaseHas('attendance_corrections', [
            'original_status' => 'absent',
            'new_status' => 'excused',
            'reason' => 'Submitted medical certificate from clinic.',
        ]);

        // Mark student as absent (check_in_time becomes null)
        $markAbsentResp = $this->requestAs($orgToken, 'POST', "/api/v1/events/{$event->id}/attendance/mark", [
            'student_id' => $student->id,
            'status' => 'absent',
            'reason' => 'Marked absent after verification.',
        ]);

        $markAbsentResp->assertStatus(200)
            ->assertJsonPath('data.status', 'absent');

        $att = Attendance::where('event_id', $event->id)->where('student_id', $student->id)->first();
        $this->assertNull($att->check_in_time);
    }
}
