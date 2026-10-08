<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Authorization & Role Enforcement Tests
 *
 * Verifies that every role can ONLY access the endpoints it is permitted to.
 * Tests are scoped to HTTP status codes so they remain stable as the API evolves.
 *
 * Actual route list (php artisan route:list):
 *  GET  /api/v1/profile
 *  GET  /api/v1/admin/users
 *  GET  /api/v1/admin/logs
 *  GET  /api/v1/student/qr                  (student only)
 *  POST /api/v1/events                       (organizer only)
 *  POST /api/v1/events/{id}/attendance/scan  (organizer/admin)
 *  GET  /api/v1/reports/participation-summary (management/admin)
 *  POST /api/v1/admin/events/{id}/review      (admin only)
 *  GET  /api/v1/dashboard/*
 */
class AuthorizationPolicyTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * Perform an authenticated request, resetting auth guards each time.
     * Routes GET/DELETE (no body) separately from POST/PUT/PATCH (with body).
     */
    private function actAs(User $user, string $method, string $uri, array $data = []): \Illuminate\Testing\TestResponse
    {
        app('auth')->forgetGuards();
        $client  = $this->actingAs($user, 'sanctum');
        $headers = ['Accept' => 'application/json'];

        return match (strtolower($method)) {
            'get', 'delete' => $client->{$method . 'Json'}($uri, $headers),
            default         => $client->{$method . 'Json'}($uri, $data, $headers),
        };
    }

    private function student(): User
    {
        return User::where('role_id', Role::where('slug', 'student')->value('id'))->firstOrFail();
    }

    private function organizer(): User
    {
        return User::where('role_id', Role::where('slug', 'organizer')->value('id'))->firstOrFail();
    }

    private function management(): User
    {
        return User::where('role_id', Role::where('slug', 'management')->value('id'))->firstOrFail();
    }

    private function admin(): User
    {
        // RoleSeeder slug is 'administrator'
        return User::where('role_id', Role::where('slug', 'administrator')->value('id'))->firstOrFail();
    }

    // ── 1. Unauthenticated access ─────────────────────────────────────────────

    /** @test */
    public function unauthenticated_request_returns_401(): void
    {
        $this->getJson('/api/v1/profile')->assertStatus(401);
    }

    // ── 2. Admin-only: user management ───────────────────────────────────────

    /** @test */
    public function student_cannot_access_admin_user_list(): void
    {
        $this->actAs($this->student(), 'get', '/api/v1/admin/users')->assertStatus(403);
    }

    /** @test */
    public function organizer_cannot_access_admin_user_list(): void
    {
        $this->actAs($this->organizer(), 'get', '/api/v1/admin/users')->assertStatus(403);
    }

    /** @test */
    public function management_cannot_access_admin_user_list(): void
    {
        $this->actAs($this->management(), 'get', '/api/v1/admin/users')->assertStatus(403);
    }

    /** @test */
    public function admin_can_access_admin_user_list(): void
    {
        $this->actAs($this->admin(), 'get', '/api/v1/admin/users')
             ->assertStatus(200)
             ->assertJsonStructure(['success', 'data']);
    }

    // ── 3. Organizer-only: event creation ─────────────────────────────────────

    /** @test */
    public function student_cannot_create_event(): void
    {
        $this->actAs($this->student(), 'post', '/api/v1/events', [
            'title'              => 'Hacked Event',
            'venue'              => 'Hallway',
            'event_date'         => now()->addDays(7)->format('Y-m-d'),
            'start_time'         => '09:00',
            'end_time'           => '12:00',
            'registration_start' => now()->format('Y-m-d H:i:s'),
            'registration_end'   => now()->addDays(6)->format('Y-m-d H:i:s'),
        ])->assertStatus(403);
    }

    /** @test */
    public function management_cannot_create_event(): void
    {
        $this->actAs($this->management(), 'post', '/api/v1/events', [
            'title'              => 'Unauthorized Event',
            'venue'              => 'Board Room',
            'event_date'         => now()->addDays(5)->format('Y-m-d'),
            'start_time'         => '10:00',
            'end_time'           => '13:00',
            'registration_start' => now()->format('Y-m-d H:i:s'),
            'registration_end'   => now()->addDays(4)->format('Y-m-d H:i:s'),
        ])->assertStatus(403);
    }

    /** @test */
    public function organizer_can_create_event(): void
    {
        $this->actAs($this->organizer(), 'post', '/api/v1/events', [
            'title'              => 'Legit Organizer Event',
            'description'        => 'An event created by an organizer for testing.',
            'venue'              => 'Auditorium',
            'event_date'         => now()->addDays(10)->format('Y-m-d'),
            'start_time'         => '08:00',
            'end_time'           => '17:00',
            'registration_start' => now()->format('Y-m-d H:i:s'),
            'registration_end'   => now()->addDays(9)->format('Y-m-d H:i:s'),
        ])->assertStatus(201)
          ->assertJsonPath('success', true);
    }

    // ── 4. QR scan — organizer/admin only ─────────────────────────────────────

    /** @test */
    public function student_cannot_scan_qr(): void
    {
        // Route: POST /api/v1/events/{id}/attendance/scan
        $this->actAs($this->student(), 'post', '/api/v1/events/1/attendance/scan', [
            'qr_token' => 'fake_token_12345',
        ])->assertStatus(403);
    }

    /** @test */
    public function management_cannot_scan_qr(): void
    {
        $this->actAs($this->management(), 'post', '/api/v1/events/1/attendance/scan', [
            'qr_token' => 'fake_token_12345',
        ])->assertStatus(403);
    }

    // ── 5. Reports — organizer/management/admin only (student blocked) ────────

    /** @test */
    public function student_cannot_access_participation_report(): void
    {
        $this->actAs($this->student(), 'get', '/api/v1/reports/participation-summary')
             ->assertStatus(403);
    }

    /** @test */
    public function organizer_can_access_participation_report(): void
    {
        // Organizer is included in role:administrator,organizer,management group
        $this->actAs($this->organizer(), 'get', '/api/v1/reports/participation-summary')
             ->assertStatus(200)
             ->assertJsonPath('success', true);
    }

    /** @test */
    public function management_can_access_participation_report(): void
    {
        $this->actAs($this->management(), 'get', '/api/v1/reports/participation-summary')
             ->assertStatus(200)
             ->assertJsonPath('success', true);
    }

    /** @test */
    public function admin_can_access_participation_report(): void
    {
        $this->actAs($this->admin(), 'get', '/api/v1/reports/participation-summary')
             ->assertStatus(200)
             ->assertJsonPath('success', true);
    }

    // ── 6. Student QR — student only ──────────────────────────────────────────

    /** @test */
    public function organizer_cannot_access_student_qr_endpoint(): void
    {
        // Route: GET /api/v1/student/qr
        $this->actAs($this->organizer(), 'get', '/api/v1/student/qr')->assertStatus(403);
    }

    /** @test */
    public function admin_cannot_access_student_qr_endpoint(): void
    {
        $this->actAs($this->admin(), 'get', '/api/v1/student/qr')->assertStatus(403);
    }

    /** @test */
    public function student_can_access_own_qr(): void
    {
        $this->actAs($this->student(), 'get', '/api/v1/student/qr')
             ->assertStatus(200)
             ->assertJsonPath('success', true);
    }

    // ── 7. Event approval — admin only ────────────────────────────────────────

    /** @test */
    public function organizer_cannot_approve_events(): void
    {
        $organizer = $this->organizer();
        $event = Event::create([
            'organizer_id'       => $organizer->id,
            'title'              => 'Pending Event',
            'description'        => 'A pending event for approval authorization testing.',
            'venue'              => 'Hall A',
            'event_date'         => now()->addDays(14)->format('Y-m-d'),
            'start_time'         => '09:00:00',
            'end_time'           => '12:00:00',
            'registration_start' => now(),
            'registration_end'   => now()->addDays(13),
            'status'             => 'pending_approval',
        ]);

        // Route: POST /api/v1/admin/events/{id}/review
        $this->actAs($organizer, 'post', "/api/v1/admin/events/{$event->id}/review", [
            'action' => 'approved',
        ])->assertStatus(403);
    }

    /** @test */
    public function student_cannot_approve_events(): void
    {
        $event = Event::create([
            'organizer_id'       => $this->organizer()->id,
            'title'              => 'Pending Event 2',
            'description'        => 'Another pending event for testing.',
            'venue'              => 'Hall B',
            'event_date'         => now()->addDays(14)->format('Y-m-d'),
            'start_time'         => '09:00:00',
            'end_time'           => '12:00:00',
            'registration_start' => now(),
            'registration_end'   => now()->addDays(13),
            'status'             => 'pending_approval',
        ]);

        $this->actAs($this->student(), 'post', "/api/v1/admin/events/{$event->id}/review", [
            'action' => 'approved',
        ])->assertStatus(403);
    }

    // ── 8. Activity log — admin only ──────────────────────────────────────────

    /** @test */
    public function non_admin_cannot_view_activity_logs(): void
    {
        // Route: GET /api/v1/admin/logs
        foreach ([$this->student(), $this->organizer(), $this->management()] as $user) {
            $this->actAs($user, 'get', '/api/v1/admin/logs')->assertStatus(403);
        }
    }

    /** @test */
    public function admin_can_view_activity_logs(): void
    {
        $this->actAs($this->admin(), 'get', '/api/v1/admin/logs')
             ->assertStatus(200)
             ->assertJsonStructure(['success', 'data']);
    }

    // ── 9. Dashboard role isolation ───────────────────────────────────────────

    /** @test */
    public function each_role_sees_only_its_own_dashboard(): void
    {
        // Student → own dashboard 200, others 403
        $this->actAs($this->student(), 'get', '/api/v1/dashboard/student')->assertStatus(200);
        $this->actAs($this->student(), 'get', '/api/v1/dashboard/organizer')->assertStatus(403);
        $this->actAs($this->student(), 'get', '/api/v1/dashboard/management')->assertStatus(403);
        $this->actAs($this->student(), 'get', '/api/v1/dashboard/admin')->assertStatus(403);

        // Organizer → own dashboard 200
        $this->actAs($this->organizer(), 'get', '/api/v1/dashboard/organizer')->assertStatus(200);
        $this->actAs($this->organizer(), 'get', '/api/v1/dashboard/student')->assertStatus(403);

        // Management → own dashboard 200
        $this->actAs($this->management(), 'get', '/api/v1/dashboard/management')->assertStatus(200);
        $this->actAs($this->management(), 'get', '/api/v1/dashboard/admin')->assertStatus(403);

        // Admin → own dashboard 200
        $this->actAs($this->admin(), 'get', '/api/v1/dashboard/admin')->assertStatus(200);
    }
}
