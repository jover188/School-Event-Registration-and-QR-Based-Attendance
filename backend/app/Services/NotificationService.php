<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\NotificationPreference;

class NotificationService
{
    /**
     * Notification types that are mandatory per SRS NOTIF-004 and cannot be disabled.
     */
    public const MANDATORY_TYPES = [
        'event_cancellation',
        'attendance_recorded',
    ];

    /**
     * Maps notification_type strings to NotificationPreference boolean column names.
     */
    public const PREFERENCE_MAP = [
        'new_event_published'    => 'new_event_published',
        'registration_confirmed' => 'registration_confirmed',
        'waiting_list_joined'    => 'registration_confirmed',
        'event_reminder_24h'     => 'event_reminders',
        'event_reminder_1h'      => 'event_reminders',
        'event_reminders'        => 'event_reminders',
        'event_started'          => 'event_reminders',
        'event_ended'            => 'event_reminders',
        'event_updated'          => 'event_updates',
        'event_updates'          => 'event_updates',
        'waiting_list_promoted'  => 'waiting_list_promoted',
        'admin_announcement'     => 'admin_announcements',
        'admin_announcements'    => 'admin_announcements',
    ];

    /**
     * Send a single notification to a user, respecting their notification preferences
     * unless the notification type is mandatory.
     */
    public static function send(
        int $userId,
        string $title,
        string $message,
        string $type,
        array $payload = []
    ): ?Notification {
        if (!in_array($type, self::MANDATORY_TYPES, true) && isset(self::PREFERENCE_MAP[$type])) {
            $pref = NotificationPreference::where('user_id', $userId)->first();
            $column = self::PREFERENCE_MAP[$type];

            if ($pref && !$pref->{$column}) {
                return null;
            }
        }

        return Notification::create([
            'user_id'           => $userId,
            'title'             => $title,
            'message'           => $message,
            'notification_type' => $type,
            'payload'           => $payload,
        ]);
    }

    /**
     * Send a notification to multiple users, returning the number of notifications created.
     */
    public static function sendToMany(
        iterable $userIds,
        string $title,
        string $message,
        string $type,
        array $payload = []
    ): int {
        $sentCount = 0;

        foreach ($userIds as $userId) {
            if (self::send((int) $userId, $title, $message, $type, $payload) !== null) {
                $sentCount++;
            }
        }

        return $sentCount;
    }
}
