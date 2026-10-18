<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            RoleSeeder::class,
            UserSeeder::class,
        ]);

        // In local/development/staging environments (when live school APIs are unavailable),
        // automatically populate realistic school events, registrations, waitlists,
        // QR attendance logs, corrections, notifications, and audit trails.
        if (! app()->environment('testing')) {
            $this->call([
                DemoSchoolDataSeeder::class,
            ]);
        }
    }
}
