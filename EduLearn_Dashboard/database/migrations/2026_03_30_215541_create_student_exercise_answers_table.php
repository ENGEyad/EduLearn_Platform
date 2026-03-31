<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::connection('app_mysql')->create('student_exercise_answers', function (Blueprint $table) {
            $table->bigIncrements('id');

            $table->unsignedBigInteger('attempt_id');
            $table->unsignedBigInteger('version_item_id');

            $table->uuid('stable_question_key');

            $table->unsignedBigInteger('selected_option_id')->nullable();
            $table->longText('answer_text')->nullable();

            $table->boolean('is_correct')->nullable();
            $table->decimal('awarded_points', 10, 2)->nullable();

            $table->timestamp('checked_at')->nullable();

            $table->json('feedback_snapshot')->nullable();

            $table->enum('answer_state', [
                'active',
                'needs_reanswer',
                'deleted_question',
                'readonly_history',
            ])->default('active');

            $table->timestamps();

            $table->index('attempt_id');
            $table->index('version_item_id');
            $table->index('stable_question_key');
            $table->index('selected_option_id');
            $table->index('answer_state');

            $table->unique(['attempt_id', 'version_item_id'], 'uq_attempt_version_item_answer');
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('student_exercise_answers');
    }
};