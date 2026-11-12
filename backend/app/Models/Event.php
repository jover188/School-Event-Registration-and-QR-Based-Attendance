<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Event extends Model
{
    use HasFactory;

    protected $fillable = [
        'organizer_id',
        'title',
        'description',
        'category',
        'cover_image_path',
        'venue',
        'event_date',
        'start_time',
        'end_time',
        'registration_start',
        'registration_end',
        'max_participants',
        'late_grace_period_minutes',
        'walk_in_allowed',
        'target_audience_type',
        'target_courses',
        'target_year_levels',
        'target_sections',
        'target_rules',
        'send_announcement',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'event_date' => 'date',
            'registration_start' => 'datetime',
            'registration_end' => 'datetime',
            'walk_in_allowed' => 'boolean',
            'max_participants' => 'integer',
            'late_grace_period_minutes' => 'integer',
            'target_courses' => 'array',
            'target_year_levels' => 'array',
            'target_sections' => 'array',
            'target_rules' => 'array',
            'send_announcement' => 'boolean',
        ];
    }

    public function organizer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'organizer_id');
    }

    public function approvals(): HasMany
    {
        return $this->hasMany(EventApproval::class);
    }

    public function registrations(): HasMany
    {
        return $this->hasMany(EventRegistration::class);
    }

    public function attendances(): HasMany
    {
        return $this->hasMany(Attendance::class);
    }

    public function activeRegistrations(): HasMany
    {
        return $this->hasMany(EventRegistration::class)->where('status', 'registered');
    }

    public function waitingList(): HasMany
    {
        return $this->hasMany(EventRegistration::class)
            ->where('status', 'waiting_list')
            ->orderBy('waiting_list_position', 'asc');
    }

    public function isRegistrationOpen(): bool
    {
        $now = now();
        return $this->status === 'published' &&
               $now->between($this->registration_start, $this->registration_end);
    }

    public function isCapacityFull(): bool
    {
        if (is_null($this->max_participants)) {
            return false;
        }

        return $this->activeRegistrations()->count() >= $this->max_participants;
    }

    public function remainingSlots(): ?int
    {
        if (is_null($this->max_participants)) {
            return null;
        }

        $remaining = $this->max_participants - $this->activeRegistrations()->count();
        return max(0, $remaining);
    }

    public function isStudentEligible(?Student $student): bool
    {
        if (!$student) {
            return false;
        }

        $type = $this->target_audience_type ?? 'all';

        if ($type === 'all' || empty($type)) {
            return true;
        }

        if ($type === 'course') {
            return in_array($student->course, $this->target_courses ?? [], true);
        }

        if ($type === 'year_level') {
            return in_array($student->year_level, $this->target_year_levels ?? [], true);
        }

        if ($type === 'custom') {
            if (!empty($this->target_rules)) {
                foreach ($this->target_rules as $rule) {
                    $matchesCourse = empty($rule['course']) || $rule['course'] === $student->course;
                    $matchesYear = empty($rule['year_level']) || $rule['year_level'] === $student->year_level;
                    $matchesSection = empty($rule['section']) || $rule['section'] === $student->section;

                    if ($matchesCourse && $matchesYear && $matchesSection) {
                        return true;
                    }
                }
                return false;
            }

            if (!empty($this->target_courses) || !empty($this->target_year_levels) || !empty($this->target_sections)) {
                $matchesCourse = empty($this->target_courses) || in_array($student->course, $this->target_courses, true);
                $matchesYear = empty($this->target_year_levels) || in_array($student->year_level, $this->target_year_levels, true);
                $matchesSection = empty($this->target_sections) || in_array($student->section, $this->target_sections, true);

                return $matchesCourse && $matchesYear && $matchesSection;
            }

            return false;
        }

        return false;
    }

    public function eligibleStudentUserIds(): \Illuminate\Support\Collection
    {
        return User::where('role_id', 3)
            ->where('status', 'active')
            ->whereHas('student')
            ->with('student')
            ->get()
            ->filter(function (User $user) {
                return $this->isStudentEligible($user->student);
            })
            ->pluck('id')
            ->values();
    }
}
