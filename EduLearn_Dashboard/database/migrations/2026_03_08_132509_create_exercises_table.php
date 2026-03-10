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
        // جدول التمارين المولدة بواسطة الذكاء الاصطناعي
        Schema::connection('app_mysql')->create('exercises', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('lesson_id');
            $table->text('question');
            $table->string('type')->default('multiple_choice'); // multiple_choice, true_false
            $table->json('options')->nullable();
            $table->string('correct_answer');
            $table->text('explanation')->nullable();
            $table->string('difficulty')->default('medium');
            $table->timestamps();

            $table->foreign('lesson_id')->references('id')->on('lessons')->onDelete('cascade');
        });

        // جدول إجابات الطلاب للتحليل
        Schema::connection('app_mysql')->create('student_responses', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('student_id')->index(); // من قاعدة edulearn_db (بدون FK رسمي)
            $table->unsignedBigInteger('exercise_id');
            $table->string('student_answer');
            $table->boolean('is_correct');
            $table->float('time_taken')->nullable(); // بالثواني
            $table->timestamps();

            $table->foreign('exercise_id')->references('id')->on('exercises')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('student_responses');
        Schema::connection('app_mysql')->dropIfExists('exercises');
    }
};
