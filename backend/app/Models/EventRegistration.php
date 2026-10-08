<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class EventRegistration extends Model
{
    use HasFactory;

    protected $fillable = [
        'event_id',
        'student_id',
        'status',
        'waiting_list_position',
        'registered_at',
        'cancelled_at',
    ];

    protected function casts(): array
    {
        return [
            'registered_at' => 'datetime',
            'cancelled_at' => 'datetime',
            'waiting_list_position' => 'integer',
        ];
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function attendance(): HasOne
    {
        return $this->hasOne(Attendance::class);
    }
}
