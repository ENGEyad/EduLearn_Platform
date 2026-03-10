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
        // 1. إضافة العمود لجدول students في القاعدة الافتراضية edulearn_db
        Schema::table('students', function (Blueprint $table) {
            $table->unsignedInteger('total_study_time_seconds')->default(0)->after('attendance_rate');
        });

        // 2. إضافة العمود لجدول student_lesson_progress في قاعدة app_mysql
        Schema::connection('app_mysql')->table('student_lesson_progress', function (Blueprint $table) {
            $table->unsignedInteger('time_spent_seconds')->default(0)->after('status');
        });
    }

    public function down(): void
    {
        Schema::table('students', function (Blueprint $table) {
            $table->dropColumn('total_study_time_seconds');
        });

        Schema::connection('app_mysql')->table('student_lesson_progress', function (Blueprint $table) {
            $table->dropColumn('time_spent_seconds');
        });
    }
};
