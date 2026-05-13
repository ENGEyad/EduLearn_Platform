<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Add school_id foreign key to students, teachers, and class_sections
     * for multi-tenancy support. Nullable to preserve existing data.
     */
    public function up(): void
    {
        // Add school_id to students
        if (!Schema::hasColumn('students', 'school_id')) {
            Schema::table('students', function (Blueprint $table) {
                $table->foreignId('school_id')
                    ->nullable()
                    ->after('id')
                    ->constrained('schools')
                    ->onDelete('cascade');
            });
        }

        // Add school_id to teachers
        if (!Schema::hasColumn('teachers', 'school_id')) {
            Schema::table('teachers', function (Blueprint $table) {
                $table->foreignId('school_id')
                    ->nullable()
                    ->after('id')
                    ->constrained('schools')
                    ->onDelete('cascade');
            });
        }

        // Add school_id to class_sections
        if (!Schema::hasColumn('class_sections', 'school_id')) {
            Schema::table('class_sections', function (Blueprint $table) {
                $table->foreignId('school_id')
                    ->nullable()
                    ->after('id')
                    ->constrained('schools')
                    ->onDelete('cascade');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $tables = ['students', 'teachers', 'class_sections'];

        foreach ($tables as $tableName) {
            if (Schema::hasColumn($tableName, 'school_id')) {
                Schema::table($tableName, function (Blueprint $table) {
                    $table->dropForeign(['school_id']);
                    $table->dropColumn('school_id');
                });
            }
        }
    }
};
