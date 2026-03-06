<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::connection('app_mysql')->create('conversations', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('teacher_id');
            $table->unsignedBigInteger('student_id');

            $table->unsignedBigInteger('class_section_id')->nullable();
            $table->unsignedBigInteger('subject_id')->nullable();

            $table->text('last_message')->nullable();
            $table->timestamp('last_message_at')->nullable();

            $table->unsignedInteger('unread_for_teacher')->default(0);
            $table->unsignedInteger('unread_for_student')->default(0);

            $table->timestamps();

            $table->index(['teacher_id', 'student_id']);
            $table->index(['class_section_id', 'subject_id']);
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('conversations');
    }
};
