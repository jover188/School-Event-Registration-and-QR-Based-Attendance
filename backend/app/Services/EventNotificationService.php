<?php

namespace App\Services;

use App\Models\Event;
use App\Models\Notification;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Log;

/**
 * Single backend gate for event-specific notifications.
 *
 * Only students holding an active ('registered') row in event_registrations for
 * the exact event are ever targeted. Waitlisted, cancelled, walk-in-only and
 * non-student accounts are excluded, and Flutter is never trusted to filter.
 */
class EventNotificationService
{
    /** Registration status the project treats as an active, confirmed participant. */
    public const ACTIVE_REGISTRATION_STATUS = 'registered';

    /**
     * User IDs of students validly registered for this exact event.
     *
     * @return Collection<int, int>
     */
    public static function eligibleRecipientUserIds(Event $event): Collection
    {
        return User::query()
            ->where('status', 'active')
            ->whereHas('role', fn ($q) => $q->where('slug', 'student'))
            ->whereHas('student.eventRegistrations', function ($q) use ($event) {
                $q->where('event_id', $event->id)
                    ->where('status', self::ACTIVE_REGISTRATION_STATUS);
            })
            ->pluck('id');
    }

    /**
     * Send an event-specific notification to eligible registered students only.
     * Preference handling (and mandatory types) stay in NotificationService.
     */
    public static function notifyRegistered(
        Event $event,
        string $title,
        string $message,
        string $type,
        array $payload = []
    ): int {
        return NotificationService::sendToMany(
            self::eligibleRecipientUserIds($event),
            $title,
            $message,
            $type,
            array_merge(['event_id' => $event->id], $payload)
        );
    }

    /** 24-hour reminder: event starts 24h from now (±15 min). */
    public static function send24HourReminders(?Carbon $now = null): int
    {
        $now ??= Carbon::now();

        return self::dispatchScheduled(
            ['published'],
            'start',
            $now->copy()->addHours(23)->addMinutes(45),
            $now->copy()->addHours(24)->addMinutes(15),
            'event_reminder_24h',
            fn (Event $e) => ['📅 Event Tomorrow: '.$e->title,
                "Reminder: \"{$e->title}\" is happening tomorrow at {$e->start_time} in {$e->venue}. Don't forget to bring your QR code!"]
        );
    }

    /** 1-hour reminder: event starts in about an hour (45–75 min). */
    public static function send1HourReminders(?Carbon $now = null): int
    {
        $now ??= Carbon::now();

        return self::dispatchScheduled(
            ['published'],
            'start',
            $now->copy()->addMinutes(45),
            $now->copy()->addMinutes(75),
            'event_reminder_1h',
            fn (Event $e) => ['⏰ Starting Soon: '.$e->title,
                "\"{$e->title}\" starts in about 1 hour at {$e->start_time} in {$e->venue}. Please make your way there!"]
        );
    }

    /** Event-start notification: start time reached within the last ~10 minutes. */
    public static function sendStartNotifications(?Carbon $now = null): int
    {
        $now ??= Carbon::now();

        return self::dispatchScheduled(
            ['published', 'ongoing'],
            'start',
            $now->copy()->subMinutes(10),
            $now->copy()->addMinute(),
            'event_started',
            fn (Event $e) => ['🚀 Event Started: '.$e->title,
                "\"{$e->title}\" has started at {$e->venue}. Have your QR code ready for check-in."]
        );
    }

    /** Event-end notification: end time reached within the last ~10 minutes. */
    public static function sendEndNotifications(?Carbon $now = null): int
    {
        $now ??= Carbon::now();

        return self::dispatchScheduled(
            ['published', 'ongoing', 'completed'],
            'end',
            $now->copy()->subMinutes(10),
            $now->copy()->addMinute(),
            'event_ended',
            fn (Event $e) => ['🏁 Event Ended: '.$e->title,
                "\"{$e->title}\" has ended. Remember to check out if you haven't yet. Thank you for participating!"]
        );
    }

    /**
     * Shared pipeline for every scheduled event notification: find events whose
     * start/end instant falls in the window, then deliver one notification per
     * eligible student. De-duplication is keyed on (user, type, event, scheduled
     * instant) so a rescheduled event is re-notified for its new time, while
     * repeated scheduler runs and late registrants never create duplicates or
     * catch-up sends.
     *
     * @param  list<string>  $statuses
     * @param  'start'|'end'  $field
     * @param  callable(Event): array{0: string, 1: string}  $content
     */
    private static function dispatchScheduled(
        array $statuses,
        string $field,
        Carbon $from,
        Carbon $to,
        string $type,
        callable $content
    ): int {
        $events = Event::whereIn('status', $statuses)
            ->whereBetween('event_date', [
                $from->copy()->subDay()->toDateString(),
                $to->copy()->addDay()->toDateString(),
            ])
            ->get()
            ->filter(function (Event $event) use ($field, $from, $to) {
                return self::scheduledInstant($event, $field)->between($from, $to);
            });

        $created = 0;

        foreach ($events as $event) {
            $scheduledFor = self::scheduledInstant($event, $field)->format('Y-m-d H:i:s');
            [$title, $message] = $content($event);
            $eventCount = 0;

            foreach (self::eligibleRecipientUserIds($event) as $userId) {
                $alreadySent = Notification::where('user_id', $userId)
                    ->where('notification_type', $type)
                    ->where('payload->event_id', $event->id)
                    ->where('payload->scheduled_for', $scheduledFor)
                    ->exists();

                if ($alreadySent) {
                    continue;
                }

                $sent = NotificationService::send($userId, $title, $message, $type, [
                    'event_id' => $event->id,
                    'event_date' => $event->event_date->format('Y-m-d'),
                    'scheduled_for' => $scheduledFor,
                ]);

                if ($sent !== null) {
                    $eventCount++;
                }
            }

            $created += $eventCount;
            Log::info("[Scheduler] {$type} sent to {$eventCount} registered student(s) for event #{$event->id}: {$event->title}");
        }

        return $created;
    }

    private static function scheduledInstant(Event $event, string $field): Carbon
    {
        $time = $field === 'end' ? $event->end_time : $event->start_time;

        return Carbon::parse($event->event_date->format('Y-m-d').' '.$time);
    }
}
