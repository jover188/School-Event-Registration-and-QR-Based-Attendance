<?php

namespace Database\Seeders;

use App\Models\ActivityLog;
use App\Models\NotificationPreference;
use App\Models\Student;
use App\Models\StudentQR;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Initial Administrator
        $admin = User::updateOrCreate(
            ['email' => 'admin@school.edu'],
            [
                'role_id' => 1,
                'password' => Hash::make('Admin@12345'),
                'status' => 'active',
                'email_verified_at' => now(),
            ]
        );
        NotificationPreference::firstOrCreate(['user_id' => $admin->id]);

        // 2. Demo Event Organizer
        $organizer = User::updateOrCreate(
            ['email' => 'organizer@school.edu'],
            [
                'role_id' => 2,
                'password' => Hash::make('Organizer@12345'),
                'status' => 'active',
                'email_verified_at' => now(),
            ]
        );
        NotificationPreference::firstOrCreate(['user_id' => $organizer->id]);

        // 3. Demo School Management
        $management = User::updateOrCreate(
            ['email' => 'management@school.edu'],
            [
                'role_id' => 4,
                'password' => Hash::make('Management@12345'),
                'status' => 'active',
                'email_verified_at' => now(),
            ]
        );
        NotificationPreference::firstOrCreate(['user_id' => $management->id]);

        // 4. Demo Student
        $studentUser = User::updateOrCreate(
            ['email' => 'student@school.edu'],
            [
                'role_id' => 3,
                'password' => Hash::make('Student@12345'),
                'status' => 'active',
                'email_verified_at' => now(),
            ]
        );
        NotificationPreference::firstOrCreate(['user_id' => $studentUser->id]);

        $studentProfile = Student::updateOrCreate(
            ['user_id' => $studentUser->id],
            [
                'student_id_number' => '20260001',
                'first_name' => 'Juan',
                'middle_name' => 'Protacio',
                'last_name' => 'Dela Cruz',
                'course' => 'BS Computer Science',
                'year_level' => '3rd Year',
                'section' => 'CS-3A',
                'department' => 'College of Computer Studies',
                'contact_number' => '+639171234567',
                'profile_photo_path' => null,
            ]
        );

        // Generate permanent 64-character hexadecimal QR token for demo student 1
        StudentQR::firstOrCreate(
            ['student_id' => $studentProfile->id, 'status' => 'active'],
            [
                'qr_token' => bin2hex(random_bytes(32)), // 64 hex characters
                'status' => 'active',
            ]
        );

        // 5. Additional Institutional Pre-Seeded Students (Demonstrating school database sync/middleware capability)
        $students = [
            [
                'email' => 'maria.santos@school.edu',
                'id_number' => '20269001',
                'first_name' => 'Maria',
                'middle_name' => 'Clara',
                'last_name' => 'Santos',
                'course' => 'BS Information Technology',
                'year_level' => '2nd Year',
                'section' => 'IT-2B',
                'department' => 'College of Computer Studies',
                'contact' => '+639181234567',
            ],
            [
                'email' => 'crisostomo.ibarra@school.edu',
                'id_number' => '20269002',
                'first_name' => 'Crisostomo',
                'middle_name' => 'Magsalin',
                'last_name' => 'Ibarra',
                'course' => 'BS Civil Engineering',
                'year_level' => '4th Year',
                'section' => 'CE-4A',
                'department' => 'College of Engineering',
                'contact' => '+639191234567',
            ],
        ];

        foreach ($students as $data) {
            $u = User::updateOrCreate(
                ['email' => $data['email']],
                [
                    'role_id' => 3,
                    'password' => Hash::make('Student@12345'),
                    'status' => 'active',
                    'email_verified_at' => now(),
                ]
            );
            NotificationPreference::firstOrCreate(['user_id' => $u->id]);

            $sp = Student::updateOrCreate(
                ['user_id' => $u->id],
                [
                    'student_id_number' => $data['id_number'],
                    'first_name' => $data['first_name'],
                    'middle_name' => $data['middle_name'],
                    'last_name' => $data['last_name'],
                    'course' => $data['course'],
                    'year_level' => $data['year_level'],
                    'section' => $data['section'],
                    'department' => $data['department'],
                    'contact_number' => $data['contact'],
                    'profile_photo_path' => null,
                ]
            );

            StudentQR::firstOrCreate(
                ['student_id' => $sp->id, 'status' => 'active'],
                [
                    'qr_token' => bin2hex(random_bytes(32)),
                    'status' => 'active',
                ]
            );
        }

        // System Initialization Log
        ActivityLog::firstOrCreate(
            ['action' => 'system_initialized'],
            [
                'user_id' => $admin->id,
                'module' => 'system',
                'record_id' => $admin->id,
                'metadata' => [
                    'version' => '1.1',
                    'action' => 'seed_initial_users',
                ],
                'ip_address' => '127.0.0.1',
                'user_agent' => 'Console/Seeder',
            ]
        );
    }
}
