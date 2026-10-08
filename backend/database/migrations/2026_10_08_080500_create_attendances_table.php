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
        Schema::create('attendances', function (Blueprint $table) {
            $table->id();
            $table->foreignId('event_id')->constrained('events')->cascadeOnUpdate()->cascadeOnDelete();
            $table->foreignId('student_id')->constrained('students')->cascadeOnUpdate()->cascadeOnDelete();
            $table->foreignId('event_registration_id')->constrained('event_registrations')->cascadeOnUpdate()->cascadeOnDelete();
            $table->dateTime('check_in_time')->useCurrent();
            $table->dateTime('check_out_time')->nullable();
            $table->enum('status', ['present', 'absent', 'late', 'excused', 'walk_in'])->default('present');
            $table->foreignId('scanner_id')->nullable()->constrained('users')->cascadeOnUpdate()->nullOnDelete();
            $table->timestamps();

            $table->unique(['event_id', 'student_id']);
            $table->index('student_id');
            $table->index('event_registration_id');
            $table->index('scanner_id');
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attendances');
    }
};
