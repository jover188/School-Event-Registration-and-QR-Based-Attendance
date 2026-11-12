<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EventAudienceOptionsAndValidationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
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

    public function test_authenticated_user_can_fetch_audience_options(): void
    {
        $token = $this->tokenFor('organizer@school.edu', 'Organizer@12345');

        $response = $this->requestAs($token, 'GET', '/api/v1/events/audience-options');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'courses',
                    'year_levels',
                    'sections',
                    'categories',
                ],
            ]);

        $courses = $response->json('data.courses');
        $this->assertContains('BS Information Technology', $courses);
        $this->assertContains('BS Computer Science', $courses);

        $yearLevels = $response->json('data.year_levels');
        $this->assertContains('1st Year', $yearLevels);
        $this->assertContains('4th Year', $yearLevels);

        $categories = $response->json('data.categories');
        $this->assertContains('Academic', $categories);
        $this->assertContains('Workshop', $categories);
    }

    public function test_organizer_can_create_event_with_audience_targeting(): void
    {
        $token = $this->tokenFor('organizer@school.edu', 'Organizer@12345');

        $payload = [
            'title' => 'Tech Summit 2026',
            'description' => 'Annual conference for IT freshmen',
            'category' => 'Workshop',
            'venue' => 'Main Auditorium',
            'event_date' => now()->addDays(7)->toDateString(),
            'start_time' => '09:00',
            'end_time' => '17:00',
            'registration_start' => now()->subDay()->toDateTimeString(),
            'registration_end' => now()->addDays(6)->toDateTimeString(),
            'max_participants' => 100,
            'target_audience_type' => 'custom',
            'target_courses' => ['BS Information Technology'],
            'target_year_levels' => ['1st Year'],
            'target_rules' => [
                ['course' => 'BS Information Technology', 'year_level' => '1st Year'],
            ],
            'send_announcement' => true,
        ];

        $response = $this->requestAs($token, 'POST', '/api/v1/events', $payload);

        $response->assertStatus(201);
        $eventId = $response->json('data.id');

        $this->assertDatabaseHas('events', [
            'id' => $eventId,
            'category' => 'Workshop',
            'target_audience_type' => 'custom',
            'send_announcement' => 1,
        ]);

        $event = Event::find($eventId);
        $this->assertEquals(['BS Information Technology'], $event->target_courses);
        $this->assertEquals(['1st Year'], $event->target_year_levels);
        $this->assertEquals([['course' => 'BS Information Technology', 'year_level' => '1st Year']], $event->target_rules);
    }

    public function test_event_creation_rejects_invalid_target_audience_type(): void
    {
        $token = $this->tokenFor('organizer@school.edu', 'Organizer@12345');

        $payload = [
            'title' => 'Invalid Targeting Summit',
            'description' => 'Test event',
            'venue' => 'Main Auditorium',
            'event_date' => now()->addDays(7)->toDateString(),
            'start_time' => '09:00',
            'end_time' => '17:00',
            'registration_start' => now()->subDay()->toDateTimeString(),
            'registration_end' => now()->addDays(6)->toDateTimeString(),
            'target_audience_type' => 'alien_species', // Invalid
        ];

        $response = $this->requestAs($token, 'POST', '/api/v1/events', $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['target_audience_type']);
    }

    public function test_organizer_can_update_event_audience_targeting(): void
    {
        $token = $this->tokenFor('organizer@school.edu', 'Organizer@12345');
        $organizer = User::where('email', 'organizer@school.edu')->first();

        $event = Event::create([
            'organizer_id' => $organizer->id,
            'title' => 'Initial Event',
            'description' => 'Initial description',
            'venue' => 'Room 101',
            'event_date' => now()->addDays(5)->toDateString(),
            'start_time' => '10:00:00',
            'end_time' => '12:00:00',
            'registration_start' => now()->subDay()->toDateTimeString(),
            'registration_end' => now()->addDays(4)->toDateTimeString(),
            'target_audience_type' => 'all',
            'status' => 'draft',
        ]);

        $updatePayload = [
            'category' => 'Seminar',
            'target_audience_type' => 'course',
            'target_courses' => ['BS Computer Science'],
            'send_announcement' => false,
        ];

        $response = $this->requestAs($token, 'PUT', "/api/v1/events/{$event->id}", $updatePayload);

        $response->assertStatus(200);

        $this->assertDatabaseHas('events', [
            'id' => $event->id,
            'category' => 'Seminar',
            'target_audience_type' => 'course',
            'send_announcement' => 0,
        ]);
    }
}
