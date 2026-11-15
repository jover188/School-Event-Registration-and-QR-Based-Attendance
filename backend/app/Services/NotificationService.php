<?php

namespace App\Services;

use App\Models\DeviceToken;
use App\Models\Notification;
use App\Models\NotificationPreference;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

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
     * Official notification sound resource for important announcements and events.
     */
    public const SOUND_CHIME_07 = 'sfxmint_ready_chime_07';

    /**
     * Notification channel ID matching Android NotificationChannel configuration.
     */
    public const NOTIFICATION_CHANNEL_ID = 'attendify_important_v1';

    /**
     * Notification categories that play the audible Notification Chime 07:
     * 1. New event announcements
     * 2. Admin broadcast announcements
     * 3. Event reminders (24h and 1h)
     * 4. Event cancellation announcements
     */
    public const SOUND_ENABLED_TYPES = [
        'new_event_published',
        'admin_announcement',
        'admin_announcements',
        'event_reminder_24h',
        'event_reminder_1h',
        'event_cancellation',
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

        if (in_array($type, self::SOUND_ENABLED_TYPES, true)) {
            $payload = array_merge([
                'sound' => self::SOUND_CHIME_07,
                'channel_id' => self::NOTIFICATION_CHANNEL_ID,
            ], $payload);
        }

        $notification = Notification::create([
            'user_id'           => $userId,
            'title'             => $title,
            'message'           => $message,
            'notification_type' => $type,
            'payload'           => $payload,
        ]);

        self::dispatchFcm($notification);

        return $notification;
    }

    /**
     * Dispatch push notification to registered devices via FCM.
     * Prefers FCM HTTP v1 API with Google Service Account credentials,
     * falling back to legacy FCM server key if configured.
     * Prunes invalid or unregistered tokens automatically.
     */
    public static function dispatchFcm(Notification $notification): void
    {
        try {
            $deviceTokens = DeviceToken::where('user_id', $notification->user_id)->get();
            if ($deviceTokens->isEmpty()) {
                return;
            }

            $credentials = self::getFirebaseCredentials();
            if ($credentials !== null) {
                self::dispatchFcmV1($notification, $deviceTokens, $credentials);
                return;
            }

            $serverKey = config('services.fcm.server_key') ?: env('FCM_SERVER_KEY');
            if (!empty($serverKey)) {
                self::dispatchFcmLegacy($notification, $deviceTokens, $serverKey);
                return;
            }

            Log::info("FCM push omitted for notification #{$notification->id}: FCM credentials not configured.");
        } catch (\Throwable $e) {
            Log::warning("FCM dispatch failed for notification #{$notification->id}: " . $e->getMessage());
        }
    }

    /**
     * Dispatch push notification via FCM HTTP v1 API using Google Cloud Service Account credentials.
     */
    protected static function dispatchFcmV1(Notification $notification, iterable $deviceTokens, array $credentials): void
    {
        $accessToken = self::getGoogleAccessToken($credentials);
        if (empty($accessToken)) {
            Log::warning("FCM HTTP v1: Unable to obtain Google OAuth access token for notification #{$notification->id}.");
            return;
        }

        $projectId = $credentials['project_id'];
        $endpoint = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

        $eventId = isset($notification->payload['event_id']) ? (string) $notification->payload['event_id'] : '';
        $dataPayload = [
            'notification_id' => (string) $notification->id,
            'notification_type' => (string) $notification->notification_type,
            'title' => (string) $notification->title,
            'message' => (string) $notification->message,
            'event_id' => $eventId,
        ];

        if (is_array($notification->payload)) {
            foreach ($notification->payload as $k => $v) {
                $key = (string) $k;
                if (!array_key_exists($key, $dataPayload)) {
                    $dataPayload[$key] = is_scalar($v) ? (string) $v : (is_null($v) ? '' : json_encode($v));
                }
            }
        }

        foreach ($deviceTokens as $deviceToken) {
            $messagePayload = [
                'message' => [
                    'token' => $deviceToken->fcm_token,
                    'notification' => [
                        'title' => (string) $notification->title,
                        'body' => (string) $notification->message,
                    ],
                    'android' => [
                        'priority' => 'HIGH',
                        'notification' => [
                            'channel_id' => self::NOTIFICATION_CHANNEL_ID,
                            'sound' => self::SOUND_CHIME_07,
                            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                            'notification_priority' => 'PRIORITY_MAX',
                            'default_vibrate_timings' => true,
                            'visibility' => 'PUBLIC',
                        ],
                    ],
                    'data' => $dataPayload,
                ],
            ];

            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $accessToken,
                'Content-Type' => 'application/json',
            ])->timeout(5)->post($endpoint, $messagePayload);

            if ($response->successful()) {
                Log::debug("FCM HTTP v1 delivered to token {$deviceToken->fcm_token} for notification #{$notification->id}");
            } else {
                $status = $response->status();
                $body = $response->json() ?? [];

                if (self::isUnregisteredOrNotFound($body, $status)) {
                    DeviceToken::where('fcm_token', $deviceToken->fcm_token)->delete();
                    Log::info("Pruned unregistered FCM device token (HTTP v1): {$deviceToken->fcm_token}");
                } else {
                    Log::warning("FCM HTTP v1 delivery returned status {$status} for token {$deviceToken->fcm_token}: " . $response->body());
                }
            }
        }
    }

    /**
     * Dispatch push notification via legacy FCM endpoint (https://fcm.googleapis.com/fcm/send).
     */
    protected static function dispatchFcmLegacy(Notification $notification, iterable $deviceTokens, string $serverKey): void
    {
        $registrationIds = collect($deviceTokens)->pluck('fcm_token')->values()->all();
        $dataPayload = [
            'notification_id' => (string) $notification->id,
            'notification_type' => (string) $notification->notification_type,
            'title' => (string) $notification->title,
            'message' => (string) $notification->message,
            'sound' => self::SOUND_CHIME_07,
            'channel_id' => self::NOTIFICATION_CHANNEL_ID,
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
        ];

        if (is_array($notification->payload)) {
            foreach ($notification->payload as $k => $v) {
                $dataPayload[(string) $k] = is_scalar($v) ? (string) $v : (is_null($v) ? '' : json_encode($v));
            }
        }

        $payload = [
            'registration_ids' => $registrationIds,
            'notification' => [
                'title' => $notification->title,
                'body' => $notification->message,
                'sound' => self::SOUND_CHIME_07,
                'channel_id' => self::NOTIFICATION_CHANNEL_ID,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                'priority' => 'high',
            ],
            'data' => $dataPayload,
            'priority' => 'high',
        ];

        $response = Http::withHeaders([
            'Authorization' => 'key=' . $serverKey,
            'Content-Type' => 'application/json',
        ])->timeout(5)->post('https://fcm.googleapis.com/fcm/send', $payload);

        if ($response->successful()) {
            $body = $response->json();
            if (isset($body['results']) && is_array($body['results'])) {
                foreach ($body['results'] as $idx => $result) {
                    if (isset($result['error']) && in_array($result['error'], ['NotRegistered', 'InvalidRegistration', 'MismatchSenderId'], true)) {
                        $staleToken = $registrationIds[$idx] ?? null;
                        if ($staleToken) {
                            DeviceToken::where('fcm_token', $staleToken)->delete();
                            Log::info("Pruned expired FCM device token: {$staleToken}");
                        }
                    }
                }
            }
        } else {
            Log::warning("FCM delivery returned status {$response->status()} for notification #{$notification->id}: " . $response->body());
        }
    }

    /**
     * Resolve Firebase Service Account credentials from JSON file or individual config / environment variables.
     */
    protected static function getFirebaseCredentials(): ?array
    {
        $credentialsPath = config('services.firebase.credentials_path') ?: env('FIREBASE_CREDENTIALS');
        if (!empty($credentialsPath) && file_exists($credentialsPath)) {
            $json = @json_decode(file_get_contents($credentialsPath), true);
            if (is_array($json) && !empty($json['project_id']) && !empty($json['client_email']) && !empty($json['private_key'])) {
                return [
                    'project_id' => (string) $json['project_id'],
                    'client_email' => (string) $json['client_email'],
                    'private_key' => str_replace(["\\n", '\n'], "\n", (string) $json['private_key']),
                ];
            }
        }

        $projectId = config('services.firebase.project_id') ?: env('FIREBASE_PROJECT_ID');
        $clientEmail = config('services.firebase.client_email') ?: env('FIREBASE_CLIENT_EMAIL');
        $privateKey = config('services.firebase.private_key') ?: env('FIREBASE_PRIVATE_KEY');

        if (!empty($projectId) && !empty($clientEmail) && !empty($privateKey)) {
            return [
                'project_id' => (string) $projectId,
                'client_email' => (string) $clientEmail,
                'private_key' => str_replace(["\\n", '\n'], "\n", (string) $privateKey),
            ];
        }

        return null;
    }

    /**
     * Retrieve or cache Google OAuth 2.0 access token using Service Account assertion.
     */
    protected static function getGoogleAccessToken(array $credentials): ?string
    {
        $token = Cache::remember('fcm_v1_access_token', now()->addMinutes(50), function () use ($credentials) {
            $jwt = self::generateJwtAssertion($credentials['client_email'], $credentials['private_key']);
            if (!$jwt) {
                return null;
            }

            $response = Http::asForm()->timeout(10)->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]);

            if ($response->successful()) {
                return $response->json('access_token');
            }

            Log::warning('FCM HTTP v1: OAuth token request failed: ' . $response->body());
            return null;
        });

        if (empty($token)) {
            Cache::forget('fcm_v1_access_token');
            return null;
        }

        return $token;
    }

    /**
     * Generate an OAuth 2.0 JWT assertion signed with RS256 using openssl_sign.
     */
    protected static function generateJwtAssertion(string $clientEmail, string $privateKey): ?string
    {
        $header = [
            'alg' => 'RS256',
            'typ' => 'JWT',
        ];

        $now = time();
        $claims = [
            'iss' => $clientEmail,
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token',
            'exp' => $now + 3600,
            'iat' => $now,
        ];

        $encodedHeader = self::base64UrlEncode(json_encode($header, JSON_UNESCAPED_SLASHES));
        $encodedClaims = self::base64UrlEncode(json_encode($claims, JSON_UNESCAPED_SLASHES));
        $signingInput = $encodedHeader . '.' . $encodedClaims;

        $binaryKey = openssl_pkey_get_private($privateKey);
        if (!$binaryKey) {
            Log::warning("FCM HTTP v1: Failed to parse private key for {$clientEmail}");
            return null;
        }

        $signature = '';
        $success = openssl_sign($signingInput, $signature, $binaryKey, OPENSSL_ALGO_SHA256);
        if (!$success) {
            Log::warning("FCM HTTP v1: Failed to sign JWT assertion for {$clientEmail}");
            return null;
        }

        return $signingInput . '.' . self::base64UrlEncode($signature);
    }

    /**
     * Base64Url encoding helper per RFC 7515.
     */
    protected static function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Check if FCM HTTP v1 error indicates an unregistered or not found token.
     */
    protected static function isUnregisteredOrNotFound(array $errorBody, int $httpStatus = 0): bool
    {
        if ($httpStatus === 404) {
            return true;
        }

        $error = $errorBody['error'] ?? $errorBody;
        $status = $error['status'] ?? '';

        if (in_array($status, ['NOT_FOUND', 'UNREGISTERED'], true)) {
            return true;
        }

        if (($error['errorCode'] ?? '') === 'UNREGISTERED') {
            return true;
        }

        if (!empty($error['details']) && is_array($error['details'])) {
            foreach ($error['details'] as $detail) {
                if (($detail['errorCode'] ?? '') === 'UNREGISTERED') {
                    return true;
                }
            }
        }

        return false;
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
