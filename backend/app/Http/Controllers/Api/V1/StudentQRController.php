<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Student;
use App\Models\StudentQR;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StudentQRController extends Controller
{
    /**
     * Get the authenticated student's permanent active QR code
     */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        $student = $user->student;

        if (!$student) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_STUDENT_PROFILE_NOT_FOUND',
                'message' => 'Student profile not found for this user.',
            ], 404);
        }

        $activeQr = $student->activeQr;

        if (!$activeQr) {
            // Generate if not present
            $activeQr = StudentQR::create([
                'student_id' => $student->id,
                'qr_token' => bin2hex(random_bytes(32)),
                'status' => 'active',
            ]);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'student_id_number' => $student->student_id_number,
                'full_name' => $student->full_name,
                'qr_token' => $activeQr->qr_token,
                'status' => $activeQr->status,
                'issued_at' => $activeQr->created_at->toIso8601String(),
            ],
        ]);
    }

    /**
     * Student Self-Service QR Reissue
     * Immediately revokes the current QR token and issues a fresh 64-character token.
     */
    public function reissue(Request $request): JsonResponse
    {
        $user = $request->user();
        $student = $user->student;

        if (!$student) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_STUDENT_PROFILE_NOT_FOUND',
                'message' => 'Student profile not found.',
            ], 404);
        }

        $newQr = DB::transaction(function () use ($student, $user) {
            // 1. Revoke existing active QR
            StudentQR::where('student_id', $student->id)
                ->where('status', 'active')
                ->update([
                    'status' => 'revoked',
                    'revoked_at' => now(),
                ]);

            // 2. Generate new 64-char cryptographic token
            $newToken = bin2hex(random_bytes(32));
            $createdQr = StudentQR::create([
                'student_id' => $student->id,
                'qr_token' => $newToken,
                'status' => 'active',
            ]);

            // 3. Log audit event
            ActivityLog::log('qr_token_reissued', 'qr', $createdQr->id, [
                'student_id' => $student->id,
                'student_id_number' => $student->student_id_number,
            ], $user->id);

            return $createdQr;
        });

        return response()->json([
            'success' => true,
            'message' => 'A new permanent QR code has been generated. Your previous QR code has been revoked.',
            'data' => [
                'student_id_number' => $student->student_id_number,
                'full_name' => $student->full_name,
                'new_qr_token' => $newQr->qr_token,
                'status' => $newQr->status,
                'issued_at' => $newQr->created_at->toIso8601String(),
            ],
        ]);
    }

    /**
     * Admin/Staff View Student QR Status & History
     */
    public function inspect(int $studentId): JsonResponse
    {
        $student = Student::with(['qrs' => function ($q) {
            $q->orderBy('created_at', 'desc');
        }])->findOrFail($studentId);

        return response()->json([
            'success' => true,
            'data' => [
                'student_id' => $student->id,
                'student_id_number' => $student->student_id_number,
                'full_name' => $student->full_name,
                'active_qr' => $student->activeQr,
                'qr_history' => $student->qrs,
            ],
        ]);
    }
}
