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
        'venue',
        'event_date',
        'start_time',
        'end_time',
        'registration_start',
        'registration_end',
        'max_participants',
        'late_grace_period_minutes',
        'walk_in_allowed',
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
}
