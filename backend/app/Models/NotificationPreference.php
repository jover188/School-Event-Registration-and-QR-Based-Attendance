<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationPreference extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'new_event_published',
        'registration_confirmed',
        'event_reminders',
        'event_updates',
        'waiting_list_promoted',
        'admin_announcements',
    ];

    protected function casts(): array
    {
        return [
            'new_event_published' => 'boolean',
            'registration_confirmed' => 'boolean',
            'event_reminders' => 'boolean',
            'event_updates' => 'boolean',
            'waiting_list_promoted' => 'boolean',
            'admin_announcements' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
