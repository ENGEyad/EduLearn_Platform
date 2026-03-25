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
        Schema::connection('app_mysql')->create('lesson_exercise_questions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('exercise_id');
            $table->enum('type', ['mcq', 'true_false', 'text']);
            $table->longText('question_text');
            $table->integer('position')->default(0);
            $table->tinyInteger('correct_bool')->nullable(); // Only for true_false types
            $table->timestamps();

            $table->foreign('exercise_id')->references('id')->on('lesson_exercises')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('lesson_exercise_questions');
    }
};
