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
        Schema::create('events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organizer_id')->constrained('users')->cascadeOnUpdate()->restrictOnDelete();
            $table->string('title', 200);
            $table->text('description');
            $table->string('venue', 200);
            $table->date('event_date');
            $table->time('start_time');
            $table->time('end_time');
            $table->dateTime('registration_start');
            $table->dateTime('registration_end');
            $table->unsignedInteger('max_participants')->nullable();
            $table->unsignedInteger('late_grace_period_minutes')->default(15);
            $table->boolean('walk_in_allowed')->default(false);
            $table->enum('status', ['draft', 'pending_approval', 'published', 'ongoing', 'completed', 'cancelled'])->default('draft');
            $table->timestamps();

            $table->index('organizer_id');
            $table->index(['status', 'event_date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('events');
    }
};
