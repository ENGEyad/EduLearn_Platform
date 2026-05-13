<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration 
{
    public function up(): void
    {
        // ================================
        // students (قاعدة mysql)
        // ================================
        if (Schema::hasTable('students')) {
            if (!Schema::hasColumn('students', 'total_study_time_seconds')) {
                Schema::table('students', function (Blueprint $table) {
                    $table->unsignedInteger('total_study_time_seconds')
                          ->default(0)
                          ->after('attendance_rate');
                });
            }
        }

        // ================================
        // student_lesson_progress (app_mysql)
        // ================================
        if (Schema::connection('app_mysql')->hasTable('student_lesson_progress')) {
            if (!Schema::connection('app_mysql')->hasColumn('student_lesson_progress', 'time_spent_seconds')) {
                Schema::connection('app_mysql')->table('student_lesson_progress', function (Blueprint $table) {
                    $table->unsignedInteger('time_spent_seconds')
                          ->default(0)
                          ->after('status');
                });
            }

            if (!Schema::connection('app_mysql')->hasColumn('student_lesson_progress', 'last_opened_at')) {
                Schema::connection('app_mysql')->table('student_lesson_progress', function (Blueprint $table) {
                    $table->timestamp('last_opened_at')
                          ->nullable()
                          ->after('time_spent_seconds');
                });
            }

            if (!Schema::connection('app_mysql')->hasColumn('student_lesson_progress', 'completed_at')) {
                Schema::connection('app_mysql')->table('student_lesson_progress', function (Blueprint $table) {
                    $table->timestamp('completed_at')
                          ->nullable()
                          ->after('last_opened_at');
                });
            }
        }
    }

    public function down(): void
    {
        // ================================
        // students
        // ================================
        if (Schema::hasTable('students') &&
            Schema::hasColumn('students', 'total_study_time_seconds')) {
            Schema::table('students', function (Blueprint $table) {
                $table->dropColumn('total_study_time_seconds');
            });
        }

        // ================================
        // student_lesson_progress
        // ================================
        if (Schema::connection('app_mysql')->hasTable('student_lesson_progress')) {

            $columnsToDrop = [];

            if (Schema::connection('app_mysql')->hasColumn('student_lesson_progress', 'time_spent_seconds')) {
                $columnsToDrop[] = 'time_spent_seconds';
            }

            if (Schema::connection('app_mysql')->hasColumn('student_lesson_progress', 'last_opened_at')) {
                $columnsToDrop[] = 'last_opened_at';
            }

            if (Schema::connection('app_mysql')->hasColumn('student_lesson_progress', 'completed_at')) {
                $columnsToDrop[] = 'completed_at';
            }

            if (!empty($columnsToDrop)) {
                Schema::connection('app_mysql')->table('student_lesson_progress', function (Blueprint $table) use ($columnsToDrop) {
                    $table->dropColumn($columnsToDrop);
                });
            }
        }
    }
};