<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('notification_preferences', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnUpdate()->cascadeOnDelete();
            $table->boolean('new_event_published')->default(true);
            $table->boolean('registration_confirmed')->default(true);
            $table->boolean('event_reminders')->default(true);
            $table->boolean('event_updates')->default(true);
            $table->boolean('waiting_list_promoted')->default(true);
            $table->boolean('admin_announcements')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notification_preferences');
    }
};
