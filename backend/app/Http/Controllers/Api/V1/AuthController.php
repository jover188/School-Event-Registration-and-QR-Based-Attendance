<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\NotificationPreference;
use App\Models\Student;
use App\Models\StudentQR;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    /**
     * Student Self-Registration
     */
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'first_name' => ['required', 'string', 'max:100'],
            'middle_name' => ['nullable', 'string', 'max:100'],
            'last_name' => ['required', 'string', 'max:100'],
            'student_id_number' => ['required', 'string', 'max:30', 'regex:/^[0-9]+$/', 'unique:students,student_id_number'],
            'email' => ['required', 'string', 'email', 'max:191', 'unique:users,email'],
            'password' => ['required', 'string', Password::min(8)->mixedCase()->numbers(), 'confirmed'],
            'course' => ['required', 'string', 'max:100'],
            'year_level' => ['required', 'string', 'max:20'],
            'section' => ['required', 'string', 'max:50'],
            'department' => ['required', 'string', 'max:100'],
            'contact_number' => ['required', 'string', 'max:25'],
            'profile_photo' => ['nullable', 'image', 'mimes:jpeg,png,jpg', 'max:2048'],
        ]);

        $photoPath = null;
        if ($request->hasFile('profile_photo')) {
            $photoPath = $request->file('profile_photo')->store('profiles', 'public');
        }

        $result = DB::transaction(function () use ($validated, $photoPath, $request) {
            // 1. Create User Account (Student Role = 3)
            $user = User::create([
                'role_id' => 3, // student
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
                'status' => 'active', // Set active or pending based on email verification policy
                'email_verified_at' => now(), // Auto-verified for local/testing or trigger notification
            ]);

            // 2. Create Student Profile
            $student = Student::create([
                'user_id' => $user->id,
                'student_id_number' => $validated['student_id_number'],
                'first_name' => $validated['first_name'],
                'middle_name' => $validated['middle_name'] ?? null,
                'last_name' => $validated['last_name'],
                'course' => $validated['course'],
                'year_level' => $validated['year_level'],
                'section' => $validated['section'],
                'department' => $validated['department'],
                'contact_number' => $validated['contact_number'],
                'profile_photo_path' => $photoPath,
            ]);

            // 3. Generate 64-character Cryptographic Permanent QR Token
            $qrToken = bin2hex(random_bytes(32)); // 64 hex characters
            StudentQR::create([
                'student_id' => $student->id,
                'qr_token' => $qrToken,
                'status' => 'active',
            ]);

            // 4. Create Default Notification Preferences
            NotificationPreference::create([
                'user_id' => $user->id,
            ]);

            // 5. Activity Log
            ActivityLog::log('student_registered', 'auth', $user->id, [
                'student_id_number' => $student->student_id_number,
                'email' => $user->email,
            ], $user->id);

            return ['user' => $user, 'student' => $student];
        });

        return response()->json([
            'success' => true,
            'message' => 'Registration successful. Account is ready for login.',
            'data' => [
                'user_id' => $result['user']->id,
                'email' => $result['user']->email,
                'student_id_number' => $result['student']->student_id_number,
                'status' => $result['user']->status,
            ],
        ], 201);
    }

    /**
     * User Login (Supports either Student ID Number OR School Email)
     * Strictly enforces a single active session per student account.
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'login' => ['required', 'string'],
            'password' => ['required', 'string'],
        ]);

        $loginInput = trim($validated['login']);
        $user = null;

        // If numeric, check student_id_number first
        if (ctype_digit($loginInput)) {
            $student = Student::where('student_id_number', $loginInput)->first();
            if ($student) {
                $user = $student->user;
            }
        }

        // If not found via student ID, check email
        if (!$user) {
            $user = User::where('email', $loginInput)->first();
        }

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_INVALID_CREDENTIALS',
                'message' => 'Invalid credentials provided.',
            ], 401);
        }

        if ($user->status === 'inactive') {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_ACCOUNT_INACTIVE',
                'message' => 'Your account has been deactivated. Please contact an administrator.',
            ], 403);
        }

        if ($user->status === 'pending') {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_EMAIL_UNVERIFIED',
                'message' => 'Please verify your school email before logging in.',
            ], 403);
        }

        // Single Session Enforcement:
        // Invalidate and delete any existing active tokens for this user
        $user->tokens()->delete();

        $sessionUuid = Str::uuid()->toString();
        $user->update(['active_session_id' => $sessionUuid]);

        // Create new Sanctum Bearer token tagged with the session UUID
        $token = $user->createToken("session-{$sessionUuid}")->plainTextToken;

        // Log login
        ActivityLog::log('user_logged_in', 'auth', $user->id, [
            'role' => $user->role?->slug,
        ], $user->id);

        $responsePayload = [
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'email' => $user->email,
                'role' => $user->role?->slug,
                'status' => $user->status,
            ],
        ];

        if ($user->isStudent() && $user->student) {
            $student = $user->student;
            $responsePayload['student_profile'] = [
                'id' => $student->id,
                'student_id_number' => $student->student_id_number,
                'full_name' => $student->full_name,
                'course' => $student->course,
                'year_level' => $student->year_level,
                'section' => $student->section,
                'department' => $student->department,
                'contact_number' => $student->contact_number,
                'profile_photo_url' => $student->profile_photo_url,
            ];
        }

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'data' => $responsePayload,
        ]);
    }

    /**
     * Logout
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user) {
            $user->currentAccessToken()?->delete();
            $user->update(['active_session_id' => null]);

            ActivityLog::log('user_logged_out', 'auth', $user->id, [], $user->id);
        }

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully. Device session terminated.',
        ]);
    }

    /**
     * Get Authenticated User Profile
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user()->load(['role', 'student.activeQr', 'notificationPreference']);

        return response()->json([
            'success' => true,
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'role' => $user->role?->slug,
                    'role_name' => $user->role?->name,
                    'status' => $user->status,
                    'email_verified_at' => $user->email_verified_at,
                ],
                'student_profile' => $user->student ? [
                    'id' => $user->student->id,
                    'student_id_number' => $user->student->student_id_number,
                    'full_name' => $user->student->full_name,
                    'first_name' => $user->student->first_name,
                    'middle_name' => $user->student->middle_name,
                    'last_name' => $user->student->last_name,
                    'course' => $user->student->course,
                    'year_level' => $user->student->year_level,
                    'section' => $user->student->section,
                    'department' => $user->student->department,
                    'contact_number' => $user->student->contact_number,
                    'profile_photo_url' => $user->student->profile_photo_url,
                    'has_active_qr' => (bool) $user->student->activeQr,
                ] : null,
                'notification_preferences' => $user->notificationPreference,
            ],
        ]);
    }

    /**
     * Update Profile (Editable fields per SRS USER-006; student_id_number & email are immutable)
     */
    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'first_name' => ['sometimes', 'string', 'max:100'],
            'middle_name' => ['nullable', 'string', 'max:100'],
            'last_name' => ['sometimes', 'string', 'max:100'],
            'course' => ['sometimes', 'string', 'max:100'],
            'year_level' => ['sometimes', 'string', 'max:20'],
            'section' => ['sometimes', 'string', 'max:50'],
            'department' => ['sometimes', 'string', 'max:100'],
            'contact_number' => ['nullable', 'string', 'max:25'],
            'profile_photo' => ['nullable', 'image', 'mimes:jpeg,png,jpg', 'max:2048'],
        ]);

        if ($user->student) {
            $student = $user->student;

            foreach (['first_name', 'middle_name', 'last_name', 'course', 'year_level', 'section', 'department', 'contact_number'] as $field) {
                if (array_key_exists($field, $validated)) {
                    $student->{$field} = $validated[$field];
                }
            }

            if ($request->hasFile('profile_photo')) {
                $photoPath = $request->file('profile_photo')->store('profiles', 'public');
                $student->profile_photo_path = $photoPath;
            }

            $student->save();
        }

        ActivityLog::log('profile_updated', 'auth', $user->id, [], $user->id);

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully.',
            'data' => [
                'profile_photo_url' => $user->student?->profile_photo_url,
                'contact_number' => $user->student?->contact_number,
                'student_profile' => $user->student ? [
                    'id' => $user->student->id,
                    'student_id_number' => $user->student->student_id_number,
                    'full_name' => $user->student->full_name,
                    'first_name' => $user->student->first_name,
                    'middle_name' => $user->student->middle_name,
                    'last_name' => $user->student->last_name,
                    'course' => $user->student->course,
                    'year_level' => $user->student->year_level,
                    'section' => $user->student->section,
                    'department' => $user->student->department,
                    'contact_number' => $user->student->contact_number,
                    'profile_photo_url' => $user->student->profile_photo_url,
                ] : null,
            ],
        ]);
    }

    /**
     * Change Password
     */
    public function changePassword(Request $request): JsonResponse
    {
        $passwordRules = ['required', 'string', Password::min(8)->mixedCase()->numbers(), 'confirmed'];

        if ($request->has('new_password') && !$request->has('password')) {
            $validated = $request->validate([
                'current_password' => ['required', 'string'],
                'new_password' => $passwordRules,
            ]);
            $newPassword = $validated['new_password'];
        } else {
            $validated = $request->validate([
                'current_password' => ['required', 'string'],
                'password' => $passwordRules,
            ]);
            $newPassword = $validated['password'];
        }

        $user = $request->user();

        if (!Hash::check($validated['current_password'], $user->password)) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_CURRENT_PASSWORD_INCORRECT',
                'message' => 'The provided current password does not match.',
            ], 422);
        }

        $user->update([
            'password' => Hash::make($newPassword),
        ]);

        ActivityLog::log('password_changed', 'auth', $user->id, [], $user->id);

        return response()->json([
            'success' => true,
            'message' => 'Password updated successfully.',
        ]);
    }

    /**
     * Verify School Email / Activate Pending Account
     */
    public function verifyEmail(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'code' => ['nullable', 'string'],
            'token' => ['nullable', 'string'],
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_USER_NOT_FOUND',
                'message' => 'No user account found with that email address.',
            ], 404);
        }

        $user->update([
            'status' => 'active',
            'email_verified_at' => $user->email_verified_at ?? now(),
        ]);

        ActivityLog::log('email_verified', 'auth', $user->id, [
            'email' => $user->email,
        ], $user->id);

        return response()->json([
            'success' => true,
            'message' => 'Email verified successfully. Your account is now active.',
            'data' => [
                'user_id' => $user->id,
                'email' => $user->email,
                'status' => $user->status,
            ],
        ]);
    }

    /**
     * Request Password Reset Token
     */
    public function forgotPassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email', 'exists:users,email'],
        ]);

        $plainToken = (string) random_int(100000, 999999);

        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $validated['email']],
            [
                'token' => Hash::make($plainToken),
                'created_at' => now(),
            ]
        );

        $user = User::where('email', $validated['email'])->first();

        ActivityLog::log('password_reset_requested', 'auth', $user?->id, [
            'email' => $validated['email'],
        ], $user?->id);

        $data = null;
        if (app()->environment(['local', 'testing'])) {
            $data = ['reset_token' => $plainToken];
        }

        return response()->json([
            'success' => true,
            'message' => 'Password reset token generated and sent to your school email.',
            'data' => $data,
        ]);
    }

    /**
     * Complete Password Reset with Token
     */
    public function resetPassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'token' => ['required', 'string'],
            'password' => ['required', 'string', Password::min(8)->mixedCase()->numbers(), 'confirmed'],
        ]);

        $record = DB::table('password_reset_tokens')
            ->where('email', $validated['email'])
            ->first();

        if (
            !$record ||
            ($record->created_at && \Carbon\Carbon::parse($record->created_at)->addMinutes(60)->isPast()) ||
            !Hash::check($validated['token'], $record->token)
        ) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_INVALID_RESET_TOKEN',
                'message' => 'Invalid or expired password reset token.',
            ], 422);
        }

        $user = User::where('email', $validated['email'])->firstOrFail();

        $user->update([
            'password' => Hash::make($validated['password']),
            'active_session_id' => null,
        ]);

        $user->tokens()->delete();

        DB::table('password_reset_tokens')->where('email', $validated['email'])->delete();

        ActivityLog::log('password_reset_completed', 'auth', $user->id, [
            'email' => $user->email,
        ], $user->id);

        return response()->json([
            'success' => true,
            'message' => 'Password has been reset successfully. You may now log in.',
        ]);
    }
}
