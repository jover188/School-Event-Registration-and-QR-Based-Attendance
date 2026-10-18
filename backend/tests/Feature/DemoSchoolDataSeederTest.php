<?php

namespace Tests\Feature;

use App\Models\ActivityLog;
use App\Models\Attendance;
use App\Models\AttendanceCorrection;
use App\Models\Event;
use App\Models\EventApproval;
use App\Models\EventRegistration;
use App\Models\Notification;
use App\Models\Role;
use App\Models\Student;
use App\Models\StudentQR;
use App\Models\User;
use Database\Seeders\DemoSchoolDataSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DemoSchoolDataSeederTest extends TestCase
{
    use RefreshDatabase;

    private function requestAs(string $token, string $method, string $uri, array $data = [])
    {
        app('auth')->forgetGuards();
        return $this->withHeader('Authorization', "Bearer {$token}")
            ->json($method, $uri, $data);
    }

    public function test_demo_school_data_seeder_populates_all_domain_tables_and_is_idempotent(): void
    {
        // Run twice to verify idempotency (no duplicate constraint errors or row inflation)
        $this->seed(DemoSchoolDataSeeder::class);
        $this->seed(DemoSchoolDataSeeder::class);

        $this->assertEquals(4, Role::count());
        $this->assertEquals(14, User::count());
        $this->assertEquals(10, Student::count());

        // 10 active QRs + 1 revoked historical QR for student 20260001
        $this->assertEquals(10, StudentQR::where('status', 'active')->count());
        $this->assertEquals(1, StudentQR::where('status', 'revoked')->count());

        // All 6 event statuses represented across 9 events
        $this->assertEquals(9, Event::count());
        $this->assertEquals(1, Event::where('status', 'ongoing')->count());
        $this->assertEquals(3, Event::where('status', 'published')->count());
        $this->assertEquals(1, Event::where('status', 'completed')->count());
        $this->assertEquals(2, Event::where('status', 'pending_approval')->count());
        $this->assertEquals(1, Event::where('status', 'draft')->count());
        $this->assertEquals(1, Event::where('status', 'cancelled')->count());

        // Approvals, registrations, attendances, corrections, notifications, and audit logs
        $this->assertGreaterThanOrEqual(5, EventApproval::count());
        $this->assertGreaterThanOrEqual(20, EventRegistration::count());
        $this->assertGreaterThanOrEqual(9, Attendance::count());
        $this->assertGreaterThanOrEqual(1, AttendanceCorrection::count());
        $this->assertGreaterThanOrEqual(6, Notification::count());
        $this->assertGreaterThanOrEqual(5, ActivityLog::count());
    }

    public function test_seeded_demo_data_powers_dashboards_for_all_four_roles(): void
    {
        $this->seed(DemoSchoolDataSeeder::class);

        // 1. Student login via numeric Student ID (20260001)
        $studentLogin = $this->postJson('/api/v1/auth/login', [
            'login' => '20260001',
            'password' => 'Student@12345',
        ])->assertStatus(200);
        $studentToken = $studentLogin->json('data.token');

        $this->requestAs($studentToken, 'GET', '/api/v1/dashboard/student')
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->requestAs($studentToken, 'GET', '/api/v1/student/qr')
            ->assertStatus(200)
            ->assertJsonPath(
                'data.qr_token',
                'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90'
            );

        // 2. Organizer login & dashboard
        $organizerLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'organizer@school.edu',
            'password' => 'Organizer@12345',
        ])->assertStatus(200);
        $organizerToken = $organizerLogin->json('data.token');

        $this->requestAs($organizerToken, 'GET', '/api/v1/dashboard/organizer')
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        // 3. Management login & read-only dashboard
        $mgmtLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'management@school.edu',
            'password' => 'Management@12345',
        ])->assertStatus(200);
        $mgmtToken = $mgmtLogin->json('data.token');

        $this->requestAs($mgmtToken, 'GET', '/api/v1/dashboard/management')
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        // 4. Admin login & dashboard (verifying 2 pending event approvals in review queue)
        $adminLogin = $this->postJson('/api/v1/auth/login', [
            'login' => 'admin@school.edu',
            'password' => 'Admin@12345',
        ])->assertStatus(200);
        $adminToken = $adminLogin->json('data.token');

        $this->requestAs($adminToken, 'GET', '/api/v1/dashboard/admin')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.stats.pending_event_approvals', 2);
    }
}
