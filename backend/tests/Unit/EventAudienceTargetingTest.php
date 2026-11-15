<?php

namespace Tests\Unit;

use App\Models\Event;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EventAudienceTargetingTest extends TestCase
{
    use RefreshDatabase;

    public function test_null_student_is_ineligible(): void
    {
        $event = new Event([
            'target_audience_type' => 'all',
        ]);

        $this->assertFalse($event->isStudentEligible(null));
    }

    public function test_all_audience_type_allows_any_student(): void
    {
        $event = new Event([
            'target_audience_type' => 'all',
        ]);

        $student = new Student([
            'course' => 'BS Information Technology',
            'year_level' => '1st Year',
            'section' => '1A',
        ]);

        $this->assertTrue($event->isStudentEligible($student));

        // When target_audience_type is null or empty, it defaults to eligible
        $eventDefault = new Event([]);
        $this->assertTrue($eventDefault->isStudentEligible($student));
    }

    public function test_course_targeting_matches_target_courses(): void
    {
        $event = new Event([
            'target_audience_type' => 'course',
            'target_courses' => ['BS Information Technology', 'BS Computer Science'],
        ]);

        $itStudent = new Student(['course' => 'BS Information Technology']);
        $csStudent = new Student(['course' => 'BS Computer Science']);
        $baStudent = new Student(['course' => 'BS Business Administration']);

        $this->assertTrue($event->isStudentEligible($itStudent));
        $this->assertTrue($event->isStudentEligible($csStudent));
        $this->assertFalse($event->isStudentEligible($baStudent));
    }

    public function test_year_level_targeting_matches_target_year_levels(): void
    {
        $event = new Event([
            'target_audience_type' => 'year_level',
            'target_year_levels' => ['1st Year', '2nd Year'],
        ]);

        $firstYear = new Student(['year_level' => '1st Year']);
        $secondYear = new Student(['year_level' => '2nd Year']);
        $thirdYear = new Student(['year_level' => '3rd Year']);

        $this->assertTrue($event->isStudentEligible($firstYear));
        $this->assertTrue($event->isStudentEligible($secondYear));
        $this->assertFalse($event->isStudentEligible($thirdYear));
    }

    public function test_custom_targeting_with_rules_matches_course_and_year_combinations(): void
    {
        $event = new Event([
            'target_audience_type' => 'custom',
            'target_rules' => [
                ['course' => 'BS Information Technology', 'year_level' => '1st Year'],
                ['course' => 'BS Business Administration', 'year_level' => '3rd Year'],
            ],
        ]);

        $it1 = new Student(['course' => 'BS Information Technology', 'year_level' => '1st Year']);
        $ba3 = new Student(['course' => 'BS Business Administration', 'year_level' => '3rd Year']);
        $it2 = new Student(['course' => 'BS Information Technology', 'year_level' => '2nd Year']);
        $ba1 = new Student(['course' => 'BS Business Administration', 'year_level' => '1st Year']);
        $cs1 = new Student(['course' => 'BS Computer Science', 'year_level' => '1st Year']);

        $this->assertTrue($event->isStudentEligible($it1));
        $this->assertTrue($event->isStudentEligible($ba3));
        $this->assertFalse($event->isStudentEligible($it2));
        $this->assertFalse($event->isStudentEligible($ba1));
        $this->assertFalse($event->isStudentEligible($cs1));
    }

    public function test_custom_targeting_with_wildcards_and_sections(): void
    {
        $event = new Event([
            'target_audience_type' => 'custom',
            'target_rules' => [
                ['course' => 'BS Information Technology', 'year_level' => null, 'section' => '1A'],
            ],
        ]);

        $match = new Student(['course' => 'BS Information Technology', 'year_level' => '3rd Year', 'section' => '1A']);
        $wrongSection = new Student(['course' => 'BS Information Technology', 'year_level' => '1st Year', 'section' => '1B']);

        $this->assertTrue($event->isStudentEligible($match));
        $this->assertFalse($event->isStudentEligible($wrongSection));
    }

    public function test_custom_targeting_with_arrays_fallback(): void
    {
        $event = new Event([
            'target_audience_type' => 'custom',
            'target_courses' => ['BS Information Technology'],
            'target_year_levels' => ['1st Year'],
            'target_rules' => [],
        ]);

        $it1 = new Student(['course' => 'BS Information Technology', 'year_level' => '1st Year']);
        $it2 = new Student(['course' => 'BS Information Technology', 'year_level' => '2nd Year']);

        $this->assertTrue($event->isStudentEligible($it1));
        $this->assertFalse($event->isStudentEligible($it2));
    }

    public function test_custom_targeting_with_department_in_rules(): void
    {
        $event = new Event([
            'target_audience_type' => 'custom',
            'target_rules' => [
                ['department' => 'CITE', 'year_level' => '1st Year'],
                ['department' => 'CBEA', 'course' => 'BS Accountancy'],
            ],
        ]);

        $cite1 = new Student(['department' => 'CITE', 'year_level' => '1st Year', 'course' => 'BS Information Technology']);
        $cbeaAccountancy = new Student(['department' => 'CBEA', 'course' => 'BS Accountancy', 'year_level' => '2nd Year']);
        $cite2 = new Student(['department' => 'CITE', 'year_level' => '2nd Year', 'course' => 'BS Information Technology']);
        $cbeaMarketing = new Student(['department' => 'CBEA', 'course' => 'BS Marketing', 'year_level' => '2nd Year']);
        $cas1 = new Student(['department' => 'CAS', 'year_level' => '1st Year', 'course' => 'BA Communication']);

        $this->assertTrue($event->isStudentEligible($cite1));
        $this->assertTrue($event->isStudentEligible($cbeaAccountancy));
        $this->assertFalse($event->isStudentEligible($cite2));
        $this->assertFalse($event->isStudentEligible($cbeaMarketing));
        $this->assertFalse($event->isStudentEligible($cas1));
    }

    public function test_custom_targeting_with_department_array_fallback(): void
    {
        $event = new Event([
            'target_audience_type' => 'custom',
            'target_departments' => ['CITE'],
            'target_courses' => ['BS Information Technology'],
            'target_rules' => [],
        ]);

        $citeIt = new Student(['department' => 'CITE', 'course' => 'BS Information Technology']);
        $cbeaIt = new Student(['department' => 'CBEA', 'course' => 'BS Information Technology']);
        $citeCs = new Student(['department' => 'CITE', 'course' => 'BS Computer Science']);

        $this->assertTrue($event->isStudentEligible($citeIt));
        $this->assertFalse($event->isStudentEligible($cbeaIt));
        $this->assertFalse($event->isStudentEligible($citeCs));
    }

    public function test_eligible_student_user_ids_returns_only_matching_active_students(): void
    {
        $this->seed();

        $activeIt1User = User::create([
            'role_id' => 3,
            'email' => 'active.it1@school.edu',
            'password' => bcrypt('password'),
            'status' => 'active',
        ]);
        Student::create([
            'user_id' => $activeIt1User->id,
            'student_id_number' => '2026-9001',
            'first_name' => 'Alice',
            'last_name' => 'IT1',
            'course' => 'BS Information Technology',
            'year_level' => '1st Year',
            'section' => '1A',
            'department' => 'CITE',
            'contact_number' => '09123456789',
        ]);

        $inactiveIt1User = User::create([
            'role_id' => 3,
            'email' => 'inactive.it1@school.edu',
            'password' => bcrypt('password'),
            'status' => 'pending', // inactive
        ]);
        Student::create([
            'user_id' => $inactiveIt1User->id,
            'student_id_number' => '2026-9002',
            'first_name' => 'Bob',
            'last_name' => 'IT1',
            'course' => 'BS Information Technology',
            'year_level' => '1st Year',
            'section' => '1A',
            'department' => 'CITE',
            'contact_number' => '09123456788',
        ]);

        $activeIt2User = User::create([
            'role_id' => 3,
            'email' => 'active.it2@school.edu',
            'password' => bcrypt('password'),
            'status' => 'active',
        ]);
        Student::create([
            'user_id' => $activeIt2User->id,
            'student_id_number' => '2026-9003',
            'first_name' => 'Charlie',
            'last_name' => 'IT2',
            'course' => 'BS Information Technology',
            'year_level' => '2nd Year',
            'section' => '2A',
            'department' => 'CITE',
            'contact_number' => '09123456787',
        ]);

        $event = new Event([
            'target_audience_type' => 'custom',
            'target_rules' => [
                ['course' => 'BS Information Technology', 'year_level' => '1st Year'],
            ],
        ]);

        $eligibleIds = $event->eligibleStudentUserIds();

        $this->assertTrue($eligibleIds->contains($activeIt1User->id));
        $this->assertFalse($eligibleIds->contains($inactiveIt1User->id));
        $this->assertFalse($eligibleIds->contains($activeIt2User->id));
    }
}
