<?php

use App\Models\Event;
use App\Models\EventRegistration;
use App\Models\Notification;
use Carbon\Carbon;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schedule;

// ── Dev utility ───────────────────────────────────────────────────────────────
Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote')->hourly();

// ── 1. Send 24-hour event reminders ──────────────────────────────────────────
//    Runs every 30 minutes; finds events starting in ~24 hours and notifies
//    all registered students who haven't yet received a 24h reminder.
Schedule::call(function () {
    $windowStart = Carbon::now()->addHours(23)->addMinutes(45);
    $windowEnd   = Carbon::now()->addHours(24)->addMinutes(15);

    $events = Event::where('status', 'published')
        ->whereDate('event_date', Carbon::today()->addDay())
        ->get()
        ->filter(function ($event) use ($windowStart, $windowEnd) {
            $startDt = Carbon::parse($event->event_date->format('Y-m-d') . ' ' . $event->start_time);
            return $startDt->between($windowStart, $windowEnd);
        });

    foreach ($events as $event) {
        $registrations = EventRegistration::with('student.user')
            ->where('event_id', $event->id)
            ->where('status', 'registered')
            ->get();

        foreach ($registrations as $reg) {
            $userId = $reg->student?->user?->id;
            if (! $userId) continue;

            // Avoid duplicate 24h reminders
            $alreadySent = Notification::where('user_id', $userId)
                ->where('type', 'event_reminder_24h')
                ->where('data->event_id', $event->id)
                ->exists();

            if (! $alreadySent) {
                Notification::create([
                    'user_id' => $userId,
                    'type'    => 'event_reminder_24h',
                    'title'   => '📅 Event Tomorrow: ' . $event->title,
                    'message' => "Reminder: \"{$event->title}\" is happening tomorrow at {$event->start_time} in {$event->venue}. Don't forget to bring your QR code!",
                    'data'    => ['event_id' => $event->id, 'event_date' => $event->event_date->format('Y-m-d')],
                ]);
            }
        }

        Log::info("[Scheduler] 24h reminder sent for event #{$event->id}: {$event->title}");
    }
})->everyThirtyMinutes()->name('event-reminder-24h')->withoutOverlapping();

// ── 2. Send 1-hour event reminders ───────────────────────────────────────────
//    Runs every 15 minutes; finds events starting in ~1 hour.
Schedule::call(function () {
    $windowStart = Carbon::now()->addMinutes(45);
    $windowEnd   = Carbon::now()->addMinutes(75);

    $events = Event::where('status', 'published')
        ->whereDate('event_date', Carbon::today())
        ->get()
        ->filter(function ($event) use ($windowStart, $windowEnd) {
            $startDt = Carbon::parse($event->event_date->format('Y-m-d') . ' ' . $event->start_time);
            return $startDt->between($windowStart, $windowEnd);
        });

    foreach ($events as $event) {
        $registrations = EventRegistration::with('student.user')
            ->where('event_id', $event->id)
            ->where('status', 'registered')
            ->get();

        foreach ($registrations as $reg) {
            $userId = $reg->student?->user?->id;
            if (! $userId) continue;

            $alreadySent = Notification::where('user_id', $userId)
                ->where('type', 'event_reminder_1h')
                ->where('data->event_id', $event->id)
                ->exists();

            if (! $alreadySent) {
                Notification::create([
                    'user_id' => $userId,
                    'type'    => 'event_reminder_1h',
                    'title'   => '⏰ Starting Soon: ' . $event->title,
                    'message' => "\"{$event->title}\" starts in about 1 hour at {$event->start_time} in {$event->venue}. Please make your way there!",
                    'data'    => ['event_id' => $event->id],
                ]);
            }
        }

        Log::info("[Scheduler] 1h reminder sent for event #{$event->id}: {$event->title}");
    }
})->everyFifteenMinutes()->name('event-reminder-1h')->withoutOverlapping();

// ── 3. Auto-close events past their end_time ─────────────────────────────────
//    Runs every 5 minutes. Marks published/ongoing events as 'completed'
//    once their end_time has passed.
Schedule::call(function () {
    $now = Carbon::now();

    $toClose = Event::whereIn('status', ['published', 'ongoing'])
        ->get()
        ->filter(function ($event) use ($now) {
            $endDt = Carbon::parse($event->event_date->format('Y-m-d') . ' ' . $event->end_time);
            return $now->greaterThan($endDt);
        });

    foreach ($toClose as $event) {
        $event->update(['status' => 'completed']);
        Log::info("[Scheduler] Event #{$event->id} '{$event->title}' auto-closed as completed.");
    }
})->everyFiveMinutes()->name('auto-close-events')->withoutOverlapping();

// ── 4. Purge old notifications (30-day retention) ────────────────────────────
//    Runs at midnight daily. Deletes read notifications older than 30 days
//    and unread notifications older than 60 days (safety net).
Schedule::call(function () {
    $readDeleted = Notification::whereNotNull('read_at')
        ->where('read_at', '<', Carbon::now()->subDays(30))
        ->delete();

    $unreadDeleted = Notification::whereNull('read_at')
        ->where('created_at', '<', Carbon::now()->subDays(60))
        ->delete();

    Log::info("[Scheduler] Notification purge: {$readDeleted} read, {$unreadDeleted} stale-unread notifications deleted.");
})->dailyAt('00:05')->name('purge-old-notifications')->withoutOverlapping();
