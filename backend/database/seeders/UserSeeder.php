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
     *
     * Simulates pre-provisioned institutional accounts and student records
     * synchronized from the school's registrar/enrollment database when live
     * school APIs are unavailable.
     */
    public function run(): void
    {
        // 1. System Administrator
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

        // 2. Event Organizers / Staff
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

        $coOrganizer = User::updateOrCreate(
            ['email' => 'cs.council@school.edu'],
            [
                'role_id' => 2,
                'password' => Hash::make('Organizer@12345'),
                'status' => 'active',
                'email_verified_at' => now(),
            ]
        );
        NotificationPreference::firstOrCreate(['user_id' => $coOrganizer->id]);

        // 3. School Management (Strictly Read-Only)
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

        // 4. Primary Demo Student (20260001)
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

        // Historical revoked QR token for demo student 20260001 (for Admin QR audit trail)
        StudentQR::updateOrCreate(
            [
                'student_id' => $studentProfile->id,
                'qr_token' => '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff',
            ],
            [
                'status' => 'revoked',
                'revoked_at' => now()->subDays(30),
            ]
        );

        // Active permanent 64-character hexadecimal QR token for demo student 20260001
        StudentQR::firstOrCreate(
            ['student_id' => $studentProfile->id, 'status' => 'active'],
            [
                'qr_token' => 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90',
                'status' => 'active',
            ]
        );

        // 5. Mock Institutional Student Directory (Simulated School Registrar Sync)
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
                'contact' => '+639181234561',
                'status' => 'active',
                'qr_token' => 'b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9001',
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
                'contact' => '+639191234562',
                'status' => 'active',
                'qr_token' => 'c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f900202',
            ],
            [
                'email' => 'elias.piloto@school.edu',
                'id_number' => '20269003',
                'first_name' => 'Elias',
                'middle_name' => 'Salome',
                'last_name' => 'Piloto',
                'course' => 'BS Computer Engineering',
                'year_level' => '3rd Year',
                'section' => 'CPE-3A',
                'department' => 'College of Engineering',
                'contact' => '+639171234563',
                'status' => 'active',
                'qr_token' => 'd4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90030303',
            ],
            [
                'email' => 'sisa.mercado@school.edu',
                'id_number' => '20269004',
                'first_name' => 'Narcisa',
                'middle_name' => 'Basilio',
                'last_name' => 'Mercado',
                'course' => 'BS Accountancy',
                'year_level' => '4th Year',
                'section' => 'BSA-4A',
                'department' => 'College of Business and Accountancy',
                'contact' => '+639171234564',
                'status' => 'active',
                'qr_token' => 'e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9004040404',
            ],
            [
                'email' => 'basilio.cruz@school.edu',
                'id_number' => '20269005',
                'first_name' => 'Basilio',
                'middle_name' => 'Sisa',
                'last_name' => 'Cruz',
                'course' => 'BS Nursing',
                'year_level' => '2nd Year',
                'section' => 'BSN-2A',
                'department' => 'College of Allied Health',
                'contact' => '+639171234565',
                'status' => 'active',
                'qr_token' => 'f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f900505050505',
            ],
            [
                'email' => 'isagani.florentino@school.edu',
                'id_number' => '20269006',
                'first_name' => 'Isagani',
                'middle_name' => 'Makaraig',
                'last_name' => 'Florentino',
                'course' => 'BS Information Systems',
                'year_level' => '1st Year',
                'section' => 'BSIS-1A',
                'department' => 'College of Computer Studies',
                'contact' => '+639171234566',
                'status' => 'active',
                'qr_token' => '0718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90060606060606',
            ],
            [
                'email' => 'paulita.gomez@school.edu',
                'id_number' => '20269007',
                'first_name' => 'Paulita',
                'middle_name' => 'Victorina',
                'last_name' => 'Gomez',
                'course' => 'BS Business Administration',
                'year_level' => '3rd Year',
                'section' => 'BSBA-3B',
                'department' => 'College of Business and Accountancy',
                'contact' => '+639171234568',
                'status' => 'active',
                'qr_token' => '18293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9007070707070707',
            ],
            [
                'email' => 'simoun.almario@school.edu',
                'id_number' => '20269008',
                'first_name' => 'Simoun',
                'middle_name' => 'Ibarra',
                'last_name' => 'Almario',
                'course' => 'BS Computer Science',
                'year_level' => '4th Year',
                'section' => 'CS-4A',
                'department' => 'College of Computer Studies',
                'contact' => '+639171234569',
                'status' => 'active',
                'qr_token' => '293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f900808080808080808',
            ],
            [
                'email' => 'juli.cabesang@school.edu',
                'id_number' => '20269009',
                'first_name' => 'Juliana',
                'middle_name' => 'Tales',
                'last_name' => 'Cabesang',
                'course' => 'BS Secondary Education',
                'year_level' => '1st Year',
                'section' => 'BSED-1A',
                'department' => 'College of Education',
                'contact' => '+639171234570',
                'status' => 'pending',
                'qr_token' => '3a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90090909090909090909',
            ],
        ];

        foreach ($students as $data) {
            $u = User::updateOrCreate(
                ['email' => $data['email']],
                [
                    'role_id' => 3,
                    'password' => Hash::make('Student@12345'),
                    'status' => $data['status'],
                    'email_verified_at' => $data['status'] === 'active' ? now() : null,
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
                    'qr_token' => $data['qr_token'] ?? bin2hex(random_bytes(32)),
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
                    'source' => 'mock_school_directory_seeder',
                    ],
                'ip_address' => '127.0.0.1',
                'user_agent' => 'Console/Seeder',
            ]
        );
    }
}
