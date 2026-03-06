<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::connection('app_mysql')->hasTable('student_lesson_progress')) {
            return;
        }

        // 🔹 على قاعدة app_mysql (نفس قاعدة دروس التطبيق)
        Schema::connection('app_mysql')->create('student_lesson_progress', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('lesson_id');
            $table->unsignedBigInteger('student_id'); // من قاعدة edulearn_db (بدون FK رسمي)

            // draft = فتح الدرس ولم يُكمل، completed = أنهى الدرس
            $table->string('status')->default('draft');

            $table->timestamp('last_opened_at')->nullable();
            $table->timestamp('completed_at')->nullable();

            $table->timestamps();

            $table->unique(['lesson_id', 'student_id']);

            // FK على lessons في نفس القاعدة
            $table->foreign('lesson_id')
                ->references('id')
                ->on('lessons')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('student_lesson_progress');
    }
};
