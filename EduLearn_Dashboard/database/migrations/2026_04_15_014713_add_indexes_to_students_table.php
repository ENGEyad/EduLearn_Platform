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
        Schema::table('students', function (Blueprint $table) {
            // Index for grouping by grade and class_section
            $table->index(['grade', 'class_section']);

            // Indexes for searching
            $table->index('full_name');
            $table->index('academic_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('students', function (Blueprint $table) {
            $table->dropIndex(['grade', 'class_section']);
            $table->dropIndex(['full_name']);
            $table->dropIndex(['academic_id']);
        });
    }
};
