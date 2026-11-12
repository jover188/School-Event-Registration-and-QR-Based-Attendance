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
        Schema::table('events', function (Blueprint $table) {
            $table->string('category', 50)->nullable()->default('General')->after('description');
            $table->string('cover_image_path', 255)->nullable()->after('category');
            $table->string('target_audience_type', 30)->default('all')->after('walk_in_allowed');
            $table->json('target_courses')->nullable()->after('target_audience_type');
            $table->json('target_year_levels')->nullable()->after('target_courses');
            $table->json('target_sections')->nullable()->after('target_year_levels');
            $table->json('target_rules')->nullable()->after('target_sections');
            $table->boolean('send_announcement')->default(true)->after('target_rules');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->dropColumn([
                'category',
                'cover_image_path',
                'target_audience_type',
                'target_courses',
                'target_year_levels',
                'target_sections',
                'target_rules',
                'send_announcement',
            ]);
        });
    }
};
