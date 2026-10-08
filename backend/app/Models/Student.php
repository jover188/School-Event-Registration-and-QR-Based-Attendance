<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Facades\Storage;

class Student extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'student_id_number',
        'first_name',
        'middle_name',
        'last_name',
        'course',
        'year_level',
        'section',
        'department',
        'contact_number',
        'profile_photo_path',
    ];

    protected $appends = [
        'full_name',
        'profile_photo_url',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function qrs(): HasMany
    {
        return $this->hasMany(StudentQR::class);
    }

    public function activeQr(): HasOne
    {
        return $this->hasOne(StudentQR::class)->where('status', 'active');
    }

    public function eventRegistrations(): HasMany
    {
        return $this->hasMany(EventRegistration::class);
    }

    public function attendances(): HasMany
    {
        return $this->hasMany(Attendance::class);
    }

    protected function fullName(): Attribute
    {
        return Attribute::make(
            get: fn () => trim("{$this->first_name} {$this->middle_name} {$this->last_name}")
        );
    }

    protected function profilePhotoUrl(): Attribute
    {
        return Attribute::make(
            get: fn () => $this->profile_photo_path ? Storage::url($this->profile_photo_path) : null
        );
    }
}
