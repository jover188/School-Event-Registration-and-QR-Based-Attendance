<?php

namespace Database\Seeders;

use App\Models\Role;
use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $roles = [
            [
                'id' => 1,
                'name' => 'Administrator',
                'slug' => 'administrator',
                'description' => 'Full system control, event approvals, user management, audit logs',
            ],
            [
                'id' => 2,
                'name' => 'Event Organizer / Staff',
                'slug' => 'organizer',
                'description' => 'Event creation, attendee management, QR scanning, report export',
            ],
            [
                'id' => 3,
                'name' => 'Student',
                'slug' => 'student',
                'description' => 'Event discovery, registration, permanent QR access, attendance history',
            ],
            [
                'id' => 4,
                'name' => 'School Management',
                'slug' => 'management',
                'description' => 'Strictly Read-Only access to dashboards, events, attendance, and reports',
            ],
        ];

        foreach ($roles as $role) {
            Role::updateOrCreate(['id' => $role['id']], $role);
        }
    }
}
