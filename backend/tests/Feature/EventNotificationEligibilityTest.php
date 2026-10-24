<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\EventRegistration;
use App\Models\Notification;
use App\Models\NotificationPreference;
use App\Models\Student;
use App\Models\User;
use App\Services\EventNotificationService;
use Carbon\Carbon;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Every event-specific notification must be filtered, on the backend, by a
 * valid ('registered') student registration for that exact event.
 */
class EventNotificationEligibilityTest extends TestCase
{
    use RefreshDatabase;

    private const NOW = '2026-11-10 09:00:00';

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

    private function requestAs(string $token, string $method, string $uri, array $data = [])
    {
        app('auth')->forgetGuards();

        return $this->withHeader('Authorization', "Bearer {$token}")->json($method, $uri, $data);
    }

    private function tokenFor(string $login, string $password): string
    {
        app('auth')->forgetGuards();

        return $this->postJson('/api/v1/auth/login', ['login' => $login, 'password' => $password])
            ->assertStatus(200)
            ->json('data.token');
    }

    /** @return Student[] */
    private function students(int $count): array
    {
        return Student::with('user')->whereHas('user', fn ($q) => $q->where('status', 'active'))
            ->orderBy('id')->take($count)->get()->all();
    }

    private function makeEvent(string $startAt, string $title = 'Reminder Event', array $overrides = []): Event
    {
        $start = Carbon::parse($startAt);

        return Event::create(array_merge([
            'organizer_id' => User::where('role_id', 2)->first()->id,
            'title' => $title,
            'description' => 'desc',
            'venue' => 'Main Hall',
            'event_date' => $start->toDateString(),
            'start_time' => $start->format('H:i:s'),
            'end_time' => $start->copy()->addHours(3)->format('H:i:s'),
            'registration_start' => Carbon::now()->subDays(3),
            'registration_end' => $start->copy()->subHour(),
            'max_participants' => 50,
            'late_grace_period_minutes' => 15,
            'walk_in_allowed' => false,
            'status' => 'published',
        ], $overrides));
    }

    private function register(Event $event, Student $student, string $status = 'registered'): EventRegistration
    {
        return EventRegistration::create([
            'event_id' => $event->id,
            'student_id' => $student->id,
            'status' => $status,
            'waiting_list_position' => $status === 'waiting_list' ? 1 : null,
            'registered_at' => now(),
            'cancelled_at' => $status === 'cancelled' ? now() : null,
        ]);
    }

    private function notificationsFor(User $user, string $type, ?Event $event = null)
    {
        $query = Notification::where('user_id', $user->id)->where('notification_type', $type);
        if ($event) {
            $query->where('payload->event_id', $event->id);
        }

        return $query;
    }

    public function test_registered_student_receives_24h_and_1h_reminders(): void
    {
        [$student] = $this->students(1);

        $in24h = $this->makeEvent('2026-11-11 09:00:00', 'Tomorrow Event');
        $in1h = $this->makeEvent('2026-11-10 10:00:00', 'Soon Event');
        $this->register($in24h, $student);
        $this->register($in1h, $student);

        $this->assertSame(1, EventNotificationService::send24HourReminders());
        $this->assertSame(1, EventNotificationService::send1HourReminders());

        $this->assertSame(1, $this->notificationsFor($student->user, 'event_reminder_24h', $in24h)->count());
        $this->assertSame(1, $this->notificationsFor($student->user, 'event_reminder_1h', $in1h)->count());
    }

    public function test_unregistered_student_receives_no_notification_for_event(): void
    {
        [$registered, $unregistered] = $this->students(2);
        $event = $this->makeEvent('2026-11-11 09:00:00');
        $this->register($event, $registered);

        EventNotificationService::send24HourReminders();

        $this->assertSame(1, $this->notificationsFor($registered->user, 'event_reminder_24h', $event)->count());
        $this->assertSame(0, Notification::where('user_id', $unregistered->user_id)->count());
    }

    public function test_student_registered_for_event_a_gets_no_reminder_for_event_b(): void
    {
        [$student] = $this->students(1);
        $eventA = $this->makeEvent('2026-11-11 09:00:00', 'Event A');
        $eventB = $this->makeEvent('2026-11-11 09:00:00', 'Event B');
        $this->register($eventA, $student);

        EventNotificationService::send24HourReminders();

        $this->assertSame(1, $this->notificationsFor($student->user, 'event_reminder_24h', $eventA)->count());
        $this->assertSame(0, $this->notificationsFor($student->user, 'event_reminder_24h', $eventB)->count());
    }

    public function test_cancelled_waitlisted_and_other_non_active_registrations_get_nothing(): void
    {
        [$active, $cancelled, $waitlisted] = $this->students(3);
        $event = $this->makeEvent('2026-11-11 09:00:00');
        $this->register($event, $active);
        $this->register($event, $cancelled, 'cancelled');
        $this->register($event, $waitlisted, 'waiting_list');

        EventNotificationService::send24HourReminders();

        $this->assertSame(1, $this->notificationsFor($active->user, 'event_reminder_24h', $event)->count());
        $this->assertSame(0, Notification::where('user_id', $cancelled->user_id)->count());
        $this->assertSame(0, Notification::where('user_id', $waitlisted->user_id)->count());
    }

    public function test_student_who_cancels_via_api_gets_no_future_reminders(): void
    {
        $event = $this->makeEvent('2026-11-11 09:00:00');
        $token = $this->tokenFor('20260001', 'Student@12345');
        $student = Student::where('student_id_number', '20260001')->first();

        $this->requestAs($token, 'POST', "/api/v1/events/{$event->id}/register")->assertStatus(201);
        $this->requestAs($token, 'DELETE', "/api/v1/events/{$event->id}/cancel-registration")->assertStatus(200);

        Notification::query()->delete(); // ignore registration/cancellation confirmations

        EventNotificationService::send24HourReminders();
        Carbon::setTestNow('2026-11-11 08:00:00');
        EventNotificationService::send1HourReminders();
        Carbon::setTestNow('2026-11-11 09:00:00');
        EventNotificationService::sendStartNotifications();
        Carbon::setTestNow('2026-11-11 12:00:00');
        EventNotificationService::sendEndNotifications();

        $this->assertSame(0, Notification::where('user_id', $student->user_id)->count());
    }

    public function test_student_registering_via_api_is_included_in_future_reminders(): void
    {
        $event = $this->makeEvent('2026-11-11 09:00:00');
        $token = $this->tokenFor('20260001', 'Student@12345');
        $student = Student::where('student_id_number', '20260001')->first();

        $this->requestAs($token, 'POST', "/api/v1/events/{$event->id}/register")->assertStatus(201);

        EventNotificationService::send24HourReminders();

        $this->assertSame(1, $this->notificationsFor($student->user, 'event_reminder_24h', $event)->count());
    }

    public function test_waitlisted_student_is_eligible_only_after_promotion(): void
    {
        $event = $this->makeEvent('2026-11-11 09:00:00', 'Capped', ['max_participants' => 1]);
        $tokenA = $this->tokenFor('20260001', 'Student@12345');
        $studentA = Student::where('student_id_number', '20260001')->first();
        $other = Student::where('student_id_number', '20269001')->first();
        $tokenB = $this->tokenFor('maria.santos@school.edu', 'Student@12345');

        $this->requestAs($tokenA, 'POST', "/api/v1/events/{$event->id}/register")->assertStatus(201);
        $this->requestAs($tokenB, 'POST', "/api/v1/events/{$event->id}/register");
        $this->assertSame('waiting_list', EventRegistration::where('event_id', $event->id)
            ->where('student_id', $other->id)->value('status'));

        Notification::query()->delete();
        EventNotificationService::send24HourReminders();
        $this->assertSame(0, Notification::where('user_id', $other->user_id)->count(), 'waitlisted must not be reminded');

        $this->requestAs($tokenA, 'DELETE', "/api/v1/events/{$event->id}/cancel-registration")->assertStatus(200);
        $this->assertSame('registered', EventRegistration::where('event_id', $event->id)
            ->where('student_id', $other->id)->value('status'));

        Notification::query()->delete();
        EventNotificationService::send24HourReminders();
        $this->assertSame(1, $this->notificationsFor($other->user, 'event_reminder_24h', $event)->count());
        $this->assertSame(0, Notification::where('user_id', $studentA->user_id)->count());
    }

    public function test_duplicate_registration_is_rejected_and_reruns_do_not_duplicate_notifications(): void
    {
        [$student] = $this->students(1);
        $event = $this->makeEvent('2026-11-11 09:00:00');
        $this->register($event, $student);

        try {
            $this->register($event, $student);
            $this->fail('A second registration row for the same (event, student) must be rejected.');
        } catch (QueryException $e) {
            $this->assertTrue(true);
        }

        EventNotificationService::send24HourReminders();
        EventNotificationService::send24HourReminders();
        $this->assertSame(1, $this->notificationsFor($student->user, 'event_reminder_24h', $event)->count());
    }

    public function test_non_student_roles_never_receive_student_event_reminders(): void
    {
        $event = $this->makeEvent('2026-11-11 09:00:00');
        $staffUsers = User::whereIn('role_id', [1, 2, 4])->get();
        $this->assertGreaterThanOrEqual(3, $staffUsers->count());

        // Even if a staff account somehow has a student profile + 'registered' row.
        foreach ($staffUsers as $i => $staff) {
            $profile = Student::create([
                'user_id' => $staff->id,
                'student_id_number' => 'STAFF'.$i,
                'first_name' => 'Staff',
                'last_name' => 'User'.$i,
                'course' => 'N/A',
                'year_level' => 'N/A',
                'section' => 'N/A',
                'department' => 'N/A',
                'contact_number' => '+639000000000',
            ]);
            $this->register($event, $profile);
        }
        [$student] = $this->students(1);
        $this->register($event, $student);

        EventNotificationService::send24HourReminders();

        foreach ($staffUsers as $staff) {
            $this->assertSame(0, Notification::where('user_id', $staff->id)->count());
        }
        $this->assertSame(1, $this->notificationsFor($student->user, 'event_reminder_24h', $event)->count());
    }

    public function test_start_and_end_notifications_follow_the_same_eligibility_rules(): void
    {
        [$registered, $unregistered, $cancelled] = $this->students(3);
        $event = $this->makeEvent('2026-11-10 09:00:00', 'Starting Now', ['status' => 'ongoing']);
        $this->register($event, $registered);
        $this->register($event, $cancelled, 'cancelled');

        $this->assertSame(1, EventNotificationService::sendStartNotifications());
        $this->assertSame(1, $this->notificationsFor($registered->user, 'event_started', $event)->count());

        Carbon::setTestNow('2026-11-10 12:00:00');
        $this->assertSame(1, EventNotificationService::sendEndNotifications());
        $this->assertSame(1, $this->notificationsFor($registered->user, 'event_ended', $event)->count());

        foreach ([$unregistered, $cancelled] as $excluded) {
            $this->assertSame(0, Notification::where('user_id', $excluded->user_id)->count());
        }
    }

    public function test_cancelled_event_sends_no_scheduled_reminders(): void
    {
        [$student] = $this->students(1);
        $event = $this->makeEvent('2026-11-11 09:00:00', 'Cancelled Event', ['status' => 'cancelled']);
        $this->register($event, $student);

        $this->assertSame(0, EventNotificationService::send24HourReminders());
        $this->assertSame(0, Notification::where('user_id', $student->user_id)->count());
    }

    public function test_student_registering_after_reminder_window_gets_no_missed_reminder(): void
    {
        [$student] = $this->students(1);
        $event = $this->makeEvent('2026-11-11 09:00:00');

        EventNotificationService::send24HourReminders(); // window passes with nobody registered

        Carbon::setTestNow('2026-11-10 12:00:00'); // student registers late
        $this->register($event, $student);

        EventNotificationService::send24HourReminders();

        $this->assertSame(0, Notification::where('user_id', $student->user_id)->count());
    }

    public function test_changing_event_time_recalculates_reminder_schedule(): void
    {
        [$student] = $this->students(1);
        $event = $this->makeEvent('2026-11-11 09:00:00');
        $this->register($event, $student);

        EventNotificationService::send24HourReminders();
        $this->assertSame(1, $this->notificationsFor($student->user, 'event_reminder_24h', $event)->count());

        // Organizer moves the event one day later; the new schedule must be honoured.
        $event->update(['event_date' => '2026-11-12']);
        Carbon::setTestNow('2026-11-11 09:00:00');
        EventNotificationService::send24HourReminders();

        $this->assertSame(2, $this->notificationsFor($student->user, 'event_reminder_24h', $event)->count());
    }

    public function test_reminders_respect_notification_preferences(): void
    {
        [$student] = $this->students(1);
        $event = $this->makeEvent('2026-11-11 09:00:00');
        $this->register($event, $student);
        NotificationPreference::updateOrCreate(['user_id' => $student->user_id], ['event_reminders' => false]);

        EventNotificationService::send24HourReminders();

        $this->assertSame(0, Notification::where('user_id', $student->user_id)->count());
    }

    public function test_event_update_and_cancellation_notices_only_reach_registered_students(): void
    {
        [$registered, $unregistered, $waitlisted] = $this->students(3);
        $event = $this->makeEvent('2026-11-20 09:00:00', 'Notice Event');
        $this->register($event, $registered);
        $this->register($event, $waitlisted, 'waiting_list');

        // A non-student account with a stray 'registered' row must still be excluded.
        $organizer = User::where('role_id', 2)->first();
        $this->register($event, Student::create([
            'user_id' => $organizer->id,
            'student_id_number' => 'STAFFX',
            'first_name' => 'Staff',
            'last_name' => 'Anomaly',
            'course' => 'N/A',
            'year_level' => 'N/A',
            'section' => 'N/A',
            'department' => 'N/A',
            'contact_number' => '+639000000001',
        ]));

        $adminToken = $this->tokenFor('admin@school.edu', 'Admin@12345');

        $this->requestAs($adminToken, 'PUT', "/api/v1/events/{$event->id}", ['venue' => 'New Venue'])->assertStatus(200);
        $this->requestAs($adminToken, 'POST', "/api/v1/admin/events/{$event->id}/review-cancellation", [
            'action' => 'approved',
        ])->assertStatus(200);

        $this->assertSame(1, $this->notificationsFor($registered->user, 'event_updates', $event)->count());
        $this->assertSame(1, $this->notificationsFor($registered->user, 'event_cancellation', $event)->count());
        $this->assertSame(0, Notification::where('user_id', $unregistered->user_id)->count());
        $this->assertSame(0, Notification::where('user_id', $waitlisted->user_id)->count());
        $this->assertSame(0, $this->notificationsFor($organizer, 'event_updates', $event)->count());
        $this->assertSame(0, $this->notificationsFor($organizer, 'event_cancellation', $event)->count());
    }
}
