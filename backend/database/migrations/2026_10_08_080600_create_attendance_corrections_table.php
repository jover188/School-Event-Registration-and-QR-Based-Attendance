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
        Schema::create('attendance_corrections', function (Blueprint $table) {
            $table->id();
            $table->foreignId('attendance_id')->constrained('attendances')->cascadeOnUpdate()->cascadeOnDelete();
            $table->foreignId('corrected_by')->constrained('users')->cascadeOnUpdate()->restrictOnDelete();
            $table->enum('original_status', ['present', 'absent', 'late', 'excused', 'walk_in']);
            $table->enum('new_status', ['present', 'absent', 'late', 'excused', 'walk_in']);
            $table->text('reason');
            $table->timestamps();

            $table->index('attendance_id');
            $table->index('corrected_by');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attendance_corrections');
    }
};
