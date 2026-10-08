<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\NotificationPreference;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;

class AdminController extends Controller
{
    /**
     * List Users with Role/Status Filters
     */
    public function listUsers(Request $request): JsonResponse
    {
        $query = User::with(['role', 'student']);

        if ($request->filled('role')) {
            $roleSlug = $request->query('role');
            $query->whereHas('role', function ($q) use ($roleSlug) {
                $q->where('slug', $roleSlug);
            });
        }

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('search')) {
            $search = $request->query('search');
            $query->where(function ($q) use ($search) {
                $q->where('email', 'like', "%{$search}%")
                  ->orWhereHas('student', function ($sq) use ($search) {
                      $sq->where('first_name', 'like', "%{$search}%")
                         ->orWhere('last_name', 'like', "%{$search}%")
                         ->orWhere('student_id_number', 'like', "%{$search}%");
                  });
            });
        }

        $users = $query->orderBy('created_at', 'desc')->paginate($request->query('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $users->items(),
            'meta' => [
                'current_page' => $users->currentPage(),
                'last_page' => $users->lastPage(),
                'total' => $users->total(),
            ],
        ]);
    }

    /**
     * Create Organizer or School Management User Account
     */
    public function createUser(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email', 'max:191', 'unique:users,email'],
            'password' => ['required', 'string', Password::min(8)],
            'role_id' => ['required', 'integer', 'in:1,2,4'], // Admin, Organizer, Management
        ]);

        $user = User::create([
            'role_id' => $validated['role_id'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'status' => 'active',
            'email_verified_at' => now(),
        ]);

        NotificationPreference::create(['user_id' => $user->id]);

        ActivityLog::log('user_created_by_admin', 'admin', $user->id, [
            'email' => $user->email,
            'role_id' => $user->role_id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'User account created successfully.',
            'data' => $user->load('role'),
        ], 201);
    }

    /**
     * Toggle Account Active/Inactive Status
     */
    public function toggleStatus(int $id, Request $request): JsonResponse
    {
        $user = User::findOrFail($id);

        if ($user->id === $request->user()->id) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_CANNOT_DEACTIVATE_SELF',
                'message' => 'You cannot deactivate your own administrative account.',
            ], 422);
        }

        $newStatus = $user->status === 'active' ? 'inactive' : 'active';
        $user->update(['status' => $newStatus]);

        if ($newStatus === 'inactive') {
            // Invalidate all tokens
            $user->tokens()->delete();
            $user->update(['active_session_id' => null]);
        }

        ActivityLog::log('user_status_changed', 'admin', $user->id, [
            'new_status' => $newStatus,
        ]);

        return response()->json([
            'success' => true,
            'message' => "User status updated to {$newStatus}.",
            'data' => ['status' => $user->status],
        ]);
    }

    /**
     * Admin Manual Password Reset
     */
    public function resetPassword(int $id, Request $request): JsonResponse
    {
        $validated = $request->validate([
            'password' => ['required', 'string', Password::min(8)],
        ]);

        $user = User::findOrFail($id);
        $user->update([
            'password' => Hash::make($validated['password']),
        ]);

        // Revoke active sessions for security
        $user->tokens()->delete();
        $user->update(['active_session_id' => null]);

        ActivityLog::log('admin_password_reset', 'admin', $user->id, [
            'email' => $user->email,
        ]);

        return response()->json([
            'success' => true,
            'message' => "Password reset successfully for {$user->email}. Prior sessions terminated.",
        ]);
    }

    /**
     * Query System Activity Logs
     */
    public function activityLogs(Request $request): JsonResponse
    {
        $query = ActivityLog::with('user:id,email');

        if ($request->filled('module')) {
            $query->where('module', $request->query('module'));
        }

        if ($request->filled('action')) {
            $query->where('action', $request->query('action'));
        }

        if ($request->filled('user_id')) {
            $query->where('user_id', $request->query('user_id'));
        }

        $logs = $query->orderBy('created_at', 'desc')->paginate($request->query('per_page', 25));

        return response()->json([
            'success' => true,
            'data' => $logs->items(),
            'meta' => [
                'current_page' => $logs->currentPage(),
                'last_page' => $logs->lastPage(),
                'total' => $logs->total(),
            ],
        ]);
    }
}
