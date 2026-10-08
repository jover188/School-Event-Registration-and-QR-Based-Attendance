<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     * @param  string  ...$roles
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_UNAUTHENTICATED',
                'message' => 'Unauthenticated access.',
            ], 401);
        }

        $userRoleSlug = $user->role?->slug;

        if (!in_array($userRoleSlug, $roles)) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_FORBIDDEN',
                'message' => 'You do not have permission to access this resource.',
            ], 403);
        }

        return $next($request);
    }
}
