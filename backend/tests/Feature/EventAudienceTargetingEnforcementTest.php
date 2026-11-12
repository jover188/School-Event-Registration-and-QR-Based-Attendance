<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\Student;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EventAudienceTargetingEnforcementTest extends TestCase
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
            'first_name' => 'Test',
            'last_name' => 'Student',
            'course' => $course,
            'year_level' => $yearLevel,
            'section' => '1A',
            'department' => 'CITE',
            'contact_number' => '09123456789',
        ]);

        return $user;
    }

    public function test_student_event_listing_and_detail_enforces_audience_targeting(): void
    {
        $organizer = User::where('email', 'organizer@school.edu')->first();

        // 1. BSIT 1st Year Event
        $bsit1Event = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'BSIT Freshmen Welcome',
            'description' => 'Orientation for 1st Year IT',
            'venue' => 'Room 101',
            'event_date' => now()->addDays(5)->toDateString(),
            'start_time' => '09:00:00',
            'end_time' => '12:00:00',
            'registration_start' => now()->subDay()->toDateTimeString(),
            'registration_end' => now()->addDays(4)->toDateTimeString(),
            'max_participants' => 50,
            'status' => 'published',
            'target_audience_type' => 'custom',
            'target_rules' => [
                ['course' => 'BS Information Technology', 'year_level' => '1st Year'],
            ],
        ]);

        // 2. All Students Event
        $allEvent = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'Campus General Assembly',
            'description' => 'Open to everyone',
            'venue' => 'Gymnasium',
            'event_date' => now()->addDays(10)->toDateString(),
            'start_time' => '13:00:00',
            'end_time' => '17:00:00',
            'registration_start' => now()->subDay()->toDateTimeString(),
            'registration_end' => now()->addDays(9)->toDateTimeString(),
            'max_participants' => 500,
            'status' => 'published',
            'target_audience_type' => 'all',
        ]);

        // Create Students
        $it1User = $this->createStudentUser('student.it1@school.edu', 'BS Information Technology', '1st Year', '20261101');
        $it2User = $this->createStudentUser('student.it2@school.edu', 'BS Information Technology', '2nd Year', '20261102');
        $baUser  = $this->createStudentUser('student.ba@school.edu', 'BS Business Administration', '1st Year', '20261103');

        $it1Token = $this->tokenFor('student.it1@school.edu', 'Password@123');
        $it2Token = $this->tokenFor('student.it2@school.edu', 'Password@123');
        $baToken  = $this->tokenFor('student.ba@school.edu', 'Password@123');

        // BSIT 1st Year student sees both BSIT 1st Year and All Students event
        $resIt1 = $this->requestAs($it1Token, 'GET', '/api/v1/events');
        $resIt1->assertStatus(200);
        $it1EventIds = collect($resIt1->json('data'))->pluck('id')->toArray();
        $this->assertContains($bsit1Event->id, $it1EventIds);
        $this->assertContains($allEvent->id, $it1EventIds);

        // BSIT 2nd Year student cannot see BSIT 1st Year event, but sees All Students event
        $resIt2 = $this->requestAs($it2Token, 'GET', '/api/v1/events');
        $resIt2->assertStatus(200);
        $it2EventIds = collect($resIt2->json('data'))->pluck('id')->toArray();
        $this->assertNotContains($bsit1Event->id, $it2EventIds);
        $this->assertContains($allEvent->id, $it2EventIds);

        // BSBA student cannot see BSIT 1st Year event
        $resBa = $this->requestAs($baToken, 'GET', '/api/v1/events');
        $resBa->assertStatus(200);
        $baEventIds = collect($resBa->json('data'))->pluck('id')->toArray();
        $this->assertNotContains($bsit1Event->id, $baEventIds);

        // Detail check: BSIT 1st Year can view BSIT 1st Year event
        $showOk = $this->requestAs($it1Token, 'GET', "/api/v1/events/{$bsit1Event->id}");
        $showOk->assertStatus(200);

        // Detail check: BSBA student receives 403 ERR_AUDIENCE_INELIGIBLE
        $showForbidden = $this->requestAs($baToken, 'GET', "/api/v1/events/{$bsit1Event->id}");
        $showForbidden->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'ERR_AUDIENCE_INELIGIBLE',
            ]);

        // Registration check: BSBA student cannot register (403 ERR_AUDIENCE_INELIGIBLE)
        $regForbidden = $this->requestAs($baToken, 'POST', "/api/v1/events/{$bsit1Event->id}/register");
        $regForbidden->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'ERR_AUDIENCE_INELIGIBLE',
            ]);

        // Registration check: BSIT 2nd Year student cannot register (403 ERR_AUDIENCE_INELIGIBLE)
        $regIt2Forbidden = $this->requestAs($it2Token, 'POST', "/api/v1/events/{$bsit1Event->id}/register");
        $regIt2Forbidden->assertStatus(403)
            ->assertJson([
                'success' => false,
                'error_code' => 'ERR_AUDIENCE_INELIGIBLE',
            ]);

        // Registration check: BSIT 1st Year student can register successfully (201 Created)
        $regOk = $this->requestAs($it1Token, 'POST', "/api/v1/events/{$bsit1Event->id}/register");
        $regOk->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'registered',
                ],
            ]);
    }
}
