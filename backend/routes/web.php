<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    $indexPath = public_path('index.html');
    if (file_exists($indexPath)) {
        return response()->file($indexPath);
    }
    return view('welcome');
});

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
        return response()->file($indexPath);
    }
    return response()->json([
        'success' => false,
        'error_code' => 'ERR_NOT_FOUND',
        'message' => 'The requested resource was not found.',
    ], 404);
});
