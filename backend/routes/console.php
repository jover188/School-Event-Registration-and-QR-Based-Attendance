<?php

use App\Models\Event;
use App\Models\Notification;
use App\Services\EventNotificationService;
use Carbon\Carbon;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schedule;

// ── Dev utility ───────────────────────────────────────────────────────────────
Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote')->hourly();

// ── 1–2. Event reminders & lifecycle notifications ───────────────────────────
//    Every event-specific notification below is delivered by
//    EventNotificationService, which targets ONLY students holding a
//    'registered' row in event_registrations for that exact event (no
//    waitlisted, cancelled, non-student, or other-event users), skips cancelled
//    events, de-duplicates per (user, type, event, scheduled instant), and
//    never back-fills reminders for students who register after the window.
Schedule::call(function () {
    EventNotificationService::send24HourReminders();
})->everyThirtyMinutes()->name('event-reminder-24h')->withoutOverlapping();

Schedule::call(function () {
    EventNotificationService::send1HourReminders();
})->everyFifteenMinutes()->name('event-reminder-1h')->withoutOverlapping();

Schedule::call(function () {
    EventNotificationService::sendStartNotifications();
})->everyFiveMinutes()->name('event-start-notification')->withoutOverlapping();

Schedule::call(function () {
    EventNotificationService::sendEndNotifications();
})->everyFiveMinutes()->name('event-end-notification')->withoutOverlapping();

// ── 3. Auto-transition ongoing events & auto-close events past their end_time ─
//    Runs every 5 minutes. Marks published events as 'ongoing' when start_time
//    has been reached today, and marks published/ongoing events as 'completed'
//    once their end_time has passed.
Schedule::call(function () {
    $now = Carbon::now();

    $toOngoing = Event::where('status', 'published')
        ->whereDate('event_date', Carbon::today())
        ->get()
        ->filter(function ($event) use ($now) {
            $startDt = Carbon::parse($event->event_date->format('Y-m-d') . ' ' . $event->start_time);
            $endDt   = Carbon::parse($event->event_date->format('Y-m-d') . ' ' . $event->end_time);
            return $now->greaterThanOrEqualTo($startDt) && $now->lessThan($endDt);
        });

    foreach ($toOngoing as $event) {
        $event->update(['status' => 'ongoing']);
        Log::info("[Scheduler] Event #{$event->id} '{$event->title}' transitioned to ongoing.");
    }

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
//    Runs at midnight daily. Deletes notifications older than 30 days.
Schedule::call(function () {
    $deleted = Notification::where('created_at', '<', Carbon::now()->subDays(30))
        ->delete();

    Log::info("[Scheduler] Notification purge: {$deleted} notifications older than 30 days deleted.");
})->dailyAt('00:05')->name('purge-old-notifications')->withoutOverlapping();
