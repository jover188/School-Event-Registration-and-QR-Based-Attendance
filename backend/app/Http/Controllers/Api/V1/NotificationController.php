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

        $notifications = Notification::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->paginate($request->query('per_page', 20));

        $unreadCount = Notification::where('user_id', $user->id)
            ->where('is_read', false)
            ->count();

        return response()->json([
            'success' => true,
            'data' => $notifications->items(),
            'unread_count' => $unreadCount,
            'meta' => [
                'current_page' => $notifications->currentPage(),
                'last_page' => $notifications->lastPage(),
                'total' => $notifications->total(),
            ],
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
            'platform' => ['required', 'in:android,ios'],
        ]);

        DeviceToken::updateOrCreate(
            ['fcm_token' => $validated['fcm_token']],
            [
                'user_id' => $request->user()->id,
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

        DeviceToken::where('fcm_token', $validated['fcm_token'])
            ->where('user_id', $request->user()->id)
            ->delete();

        return response()->json([
            'success' => true,
            'message' => 'Device token removed.',
        ]);
    }
}
