<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use App\Models\Notification;
use App\Models\NotificationPreference;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Get In-App Notification Inbox
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = Notification::where('user_id', $user->id)
            ->orderBy('id', 'desc');

        if ($request->filled('after_id')) {
            $query->where('id', '>', (int) $request->query('after_id'));
        }

        if ($request->boolean('unread_only')) {
            $query->where('is_read', false);
        }

        $notifications = $query->paginate($request->query('per_page', 20));

        $unreadCount = Notification::where('user_id', $user->id)
            ->where('is_read', false)
            ->count();

        $latestId = Notification::where('user_id', $user->id)
            ->max('id') ?? 0;

        return response()->json([
            'success' => true,
            'data' => $notifications->items(),
            'unread_count' => $unreadCount,
            'latest_id' => $latestId,
            'meta' => [
                'current_page' => $notifications->currentPage(),
                'last_page' => $notifications->lastPage(),
                'total' => $notifications->total(),
            ],
        ]);
    }

    /**
     * Get Lightweight Unread Notification Count & Latest ID
     */
    public function unreadCount(Request $request): JsonResponse
    {
        $user = $request->user();

        $unreadCount = Notification::where('user_id', $user->id)
            ->where('is_read', false)
            ->count();

        $latestId = Notification::where('user_id', $user->id)
            ->max('id') ?? 0;

        return response()->json([
            'success' => true,
            'unread_count' => $unreadCount,
            'latest_id' => $latestId,
        ]);
    }

    /**
     * Mark Single Notification as Read
     */
    public function markAsRead(int $id, Request $request): JsonResponse
    {
        $notification = Notification::where('user_id', $request->user()->id)
            ->findOrFail($id);

        $notification->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Notification marked as read.',
        ]);
    }

    /**
     * Mark All Notifications as Read
     */
    public function markAllAsRead(Request $request): JsonResponse
    {
        Notification::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'message' => 'All notifications marked as read.',
        ]);
    }

    /**
     * Get User Notification Preferences
     */
    public function getPreferences(Request $request): JsonResponse
    {
        $preferences = NotificationPreference::firstOrCreate([
            'user_id' => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'data' => $preferences,
        ]);
    }

    /**
     * Update Notification Preferences
     */
    public function updatePreferences(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'new_event_published' => ['sometimes', 'boolean'],
            'registration_confirmed' => ['sometimes', 'boolean'],
            'event_reminders' => ['sometimes', 'boolean'],
            'event_updates' => ['sometimes', 'boolean'],
            'waiting_list_promoted' => ['sometimes', 'boolean'],
            'admin_announcements' => ['sometimes', 'boolean'],
        ]);

        $preferences = NotificationPreference::firstOrCreate([
            'user_id' => $request->user()->id,
        ]);

        $preferences->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Notification preferences updated.',
            'data' => $preferences,
        ]);
    }

    /**
     * Register Device FCM Token
     */
    public function storeDeviceToken(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'fcm_token' => ['required', 'string'],
            'platform' => ['required', 'in:android,ios,web'],
        ]);

        $user = $request->user();

        DeviceToken::updateOrCreate(
            ['fcm_token' => $validated['fcm_token']],
            [
                'user_id' => $user->id,
                'platform' => $validated['platform'],
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Device token registered successfully for push notifications.',
        ]);
    }

    /**
     * Deregister Device FCM Token (on logout)
     */
    public function destroyDeviceToken(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'fcm_token' => ['required', 'string'],
        ]);

        $user = $request->user();

        DeviceToken::where('fcm_token', $validated['fcm_token'])
            ->where('user_id', $user->id)
            ->delete();

        return response()->json([
            'success' => true,
            'message' => 'Device token removed.',
        ]);
    }

    /**
     * Diagnostic report for Firebase credentials and device token status (Admin only)
     */
    public function diagnostic(): JsonResponse
    {
        $credentials = \App\Services\NotificationService::getFirebaseCredentials();
        $secretFiles = @glob('/etc/secrets/*') ?: [];
        $secretFileDetails = [];
        foreach ($secretFiles as $file) {
            $secretFileDetails[] = [
                'path' => $file,
                'readable' => is_readable($file),
                'size' => @filesize($file),
            ];
        }

        $deviceTokenCount = DeviceToken::count();
        $recentTokens = DeviceToken::with('user:id,email')
            ->latest()
            ->take(10)
            ->get()
            ->map(function ($token) {
                return [
                    'id' => $token->id,
                    'user_id' => $token->user_id,
                    'email' => $token->user?->email,
                    'platform' => $token->platform,
                    'token_preview' => substr($token->fcm_token, 0, 15) . '...',
                    'created_at' => $token->created_at?->toIso8601String(),
                ];
            });

        return response()->json([
            'success' => true,
            'data' => [
                'firebase_credentials_resolved' => $credentials !== null,
                'project_id' => $credentials['project_id'] ?? null,
                'client_email' => $credentials['client_email'] ?? null,
                'env_has_credentials_json' => !empty(env('FIREBASE_CREDENTIALS_JSON')),
                'config_has_credentials_json' => !empty(config('services.firebase.credentials_json')),
                'secret_files' => $secretFileDetails,
                'device_tokens_total' => $deviceTokenCount,
                'recent_device_tokens' => $recentTokens,
            ],
        ]);
    }
}
