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
        Schema::create('event_approvals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('event_id')->constrained('events')->cascadeOnUpdate()->cascadeOnDelete();
            $table->foreignId('admin_id')->constrained('users')->cascadeOnUpdate()->restrictOnDelete();
            $table->enum('approval_type', ['publish', 'cancellation']);
            $table->enum('status', ['approved', 'rejected']);
            $table->text('remarks')->nullable();
            $table->timestamps();

            $table->index('event_id');
            $table->index('admin_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('event_approvals');
    }
};
