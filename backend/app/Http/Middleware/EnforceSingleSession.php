<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Laravel\Sanctum\PersonalAccessToken;
use Symfony\Component\HttpFoundation\Response;

class EnforceSingleSession
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user) {
            if ($user->status !== 'active') {
                $user->currentAccessToken()?->delete();

                return response()->json([
                    'success' => false,
                    'error_code' => 'ERR_ACCOUNT_INACTIVE',
                    'message' => 'Your account has been deactivated. Please contact an administrator.',
                ], 403);
            }

            $currentToken = $user->currentAccessToken();

            if ($currentToken instanceof PersonalAccessToken) {
                if (!$user->active_session_id || $currentToken->name !== "session-{$user->active_session_id}") {
                    $currentToken->delete();

                    return response()->json([
                        'success' => false,
                        'error_code' => 'ERR_SESSION_TERMINATED',
                        'message' => 'Your session has been terminated because your account was logged into from another device.',
                    ], 401);
                }
            }
        }

        return $next($request);
    }
}
