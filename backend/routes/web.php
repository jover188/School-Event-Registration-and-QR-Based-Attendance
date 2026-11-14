<?php

use Illuminate\Support\Facades\Route;

/**
 * Public Landing Page (SaaS Black & White Minimalist Edition)
 */
Route::get('/', function () {
    return view('landing');
})->name('landing');

Route::get('/landing', function () {
    return view('landing');
});

/**
 * Direct APK Download Route (Downloads APK directly or redirects to GitHub Release binary)
 */
Route::get('/download/apk', function () {
    $localApk = public_path('downloads/attendify-release.apk');
    if (file_exists($localApk)) {
        return response()->download($localApk, 'attendify-release.apk', [
            'Content-Type' => 'application/vnd.android.package-archive',
            'Content-Disposition' => 'attachment; filename="attendify-release.apk"',
        ]);
    }
    // Direct binary download link from GitHub Release
    return redirect('https://github.com/jover188/School-Event-Registration-and-QR-Based-Attendance/releases/download/v1.1.0/attendify-release.apk');
})->name('download.apk');

/**
 * Attendify Web Application Portal (Flutter Web Client)
 */
Route::get('/app', function () {
    $indexPath = public_path('index.html');
    if (file_exists($indexPath)) {
        return response()->file($indexPath, [
            'Content-Type' => 'text/html; charset=utf-8',
        ]);
    }
    return redirect()->route('landing');
})->name('app');

/**
 * Catch-All Web Fallback:
 * - API requests return standard 404 JSON envelope.
 * - Non-API web requests fall back to Flutter Web index.html (for client-side routing)
 *   or 404 JSON envelope if index.html is missing.
 */
Route::fallback(function (\Illuminate\Http\Request $request) {
    if ($request->is('api/*')) {
        return response()->json([
            'success' => false,
            'error_code' => 'ERR_NOT_FOUND',
            'message' => 'The requested API route was not found.',
        ], 404);
    }

    $indexPath = public_path('index.html');
    if (file_exists($indexPath)) {
        return response()->file($indexPath, [
            'Content-Type' => 'text/html; charset=utf-8',
        ]);
    }

    return response()->json([
        'success' => false,
        'error_code' => 'ERR_NOT_FOUND',
        'message' => 'The requested resource was not found.',
    ], 404);
});
