<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
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
            $currentToken = $user->currentAccessToken();

            if ($currentToken && $user->active_session_id) {
                // If token name does not match the user's active session, it was superseded by another login
                if (!str_contains($currentToken->name, (string) $user->active_session_id)) {
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
