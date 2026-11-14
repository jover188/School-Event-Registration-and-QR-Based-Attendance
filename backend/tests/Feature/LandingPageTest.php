<?php

namespace Tests\Feature;

use Tests\TestCase;

class LandingPageTest extends TestCase
{
    /**
     * Test that root '/' renders the landing page with HTTP 200.
     */
    public function test_landing_page_renders_successfully(): void
    {
        $response = $this->get('/');

        $response->assertStatus(200);
        $response->assertSee('Attendify');
        $response->assertSee('Smarter Events');
        $response->assertSee('Seamless Attendance');
    }

    /**
     * Test that '/landing' route also renders the landing page.
     */
    public function test_landing_alias_route_renders_successfully(): void
    {
        $response = $this->get('/landing');

        $response->assertStatus(200);
        $response->assertSee('Attendify');
    }

    /**
     * Test that the landing page contains all required sections.
     */
    public function test_landing_page_contains_all_core_sections(): void
    {
        $response = $this->get('/');

        $response->assertStatus(200);

        // Required Sections
        $response->assertSee('About Attendify');
        $response->assertSee('System Capabilities');
        $response->assertSee('Event Management');
        $response->assertSee('QR Code Attendance');
        $response->assertSee('Event Registration & Waiting List');
        $response->assertSee('Real-Time Attendance Monitoring');
        $response->assertSee('Audible & Push Notifications');
        $response->assertSee('Student Management');
        $response->assertSee('Calendar &amp; Event Scheduling', false);
        $response->assertSee('How Attendify Works in 5 Simple Steps');
        $response->assertSee('Application Preview');
        $response->assertSee('Download Attendify APK');

        // Assets
        $response->assertSee('css/landing.css');
        $response->assertSee('js/landing.js');
    }

    /**
     * Test that '/app' route serves the Flutter web client.
     */
    public function test_app_route_serves_flutter_web(): void
    {
        $response = $this->get('/app');

        // Should return 200 if index.html exists
        $response->assertStatus(200);
    }

    /**
     * Test that '/download/apk' redirects to the GitHub release asset.
     */
    public function test_apk_download_route_redirects(): void
    {
        $response = $this->get('/download/apk');

        $response->assertRedirect('https://github.com/jover188/School-Event-Registration-and-QR-Based-Attendance/releases/download/v1.1.0/attendify-release.apk');
    }

    /**
     * Test that API routes remain completely untouched and return standard JSON.
     */
    public function test_api_routes_and_fallback_remain_unaffected(): void
    {
        // Unauthenticated access to /api/v1/profile should return 401
        $response = $this->getJson('/api/v1/profile');
        $response->assertStatus(401);

        // Unknown API route should hit fallback and return 404 JSON envelope
        $notFoundResponse = $this->getJson('/api/v1/nonexistent-endpoint');
        $notFoundResponse->assertStatus(404);
        $notFoundResponse->assertJson([
            'success' => false,
            'error_code' => 'ERR_NOT_FOUND',
        ]);
    }
}
