<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('teachers', function (Blueprint $table) {
            $table->id();
            $table->string('full_name');
            $table->string('teacher_code')->nullable(); // T-2025-101
            $table->string('email')->nullable();
            $table->string('phone')->nullable();

            // Personal
            $table->string('birth_governorate')->nullable();
            $table->date('birthdate')->nullable();
            $table->unsignedInteger('age')->nullable();

            // Academic & job
            $table->string('qualification')->nullable();
            $table->date('qualification_date')->nullable();
            $table->string('current_school')->nullable();
            $table->date('join_date')->nullable();
            $table->string('current_role')->nullable();
            $table->unsignedInteger('weekly_load')->nullable();
            $table->unsignedBigInteger('salary')->nullable();

            // Duty & attendance
            $table->string('shift')->nullable();
            $table->string('national_id')->nullable();

            // Social & address
            $table->string('marital_status')->nullable();
            $table->unsignedInteger('children')->nullable();
            $table->string('district')->nullable();
            $table->string('neighborhood')->nullable();
            $table->string('street')->nullable();

            // Teaching assignment
            $table->string('stage')->nullable(); // basic / secondary
            $table->json('subjects')->nullable();
            $table->json('grades')->nullable();

            // Single experience
            $table->unsignedInteger('experience_years')->nullable();
            $table->string('experience_place')->nullable();

            // Dashboard-ish info
            $table->string('status')->default('Active');
            $table->unsignedInteger('students_count')->default(0);

            // أداء وحضور من تطبيق الأستاذ
            $table->decimal('avg_student_score', 5, 2)->nullable(); // e.g. 90.50
            $table->decimal('attendance_rate', 5, 2)->nullable();   // e.g. 98.00

            // مسار صورة الأستاذ (مثل الطلاب)
            $table->string('photo_path')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('teachers');
    }
};
