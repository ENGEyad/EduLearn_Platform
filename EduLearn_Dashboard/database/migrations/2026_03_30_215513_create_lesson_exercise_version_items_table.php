<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::connection('app_mysql')->create('lesson_exercise_version_items', function (Blueprint $table) {
            $table->bigIncrements('id');

            $table->unsignedBigInteger('version_id');

            $table->uuid('stable_question_key');

            $table->enum('origin', [
                'manual',
                'ai',
                'mixed',
            ])->default('manual');

            $table->enum('type', [
                'true_false',
                'multiple_choice',
                'short_answer',
            ]);

            $table->longText('question_text');
            $table->longText('correct_text_answer')->nullable();
            $table->longText('explanation')->nullable();

            $table->decimal('points', 8, 2)->default(1);

            $table->unsignedInteger('position')->default(1);

            $table->boolean('is_active')->default(true);

            $table->enum('change_status_from_previous', [
                'new',
                'updated',
                'deleted',
                'restored',
                'unchanged',
            ])->default('new');

            $table->json('meta')->nullable();

            $table->timestamps();

            $table->index('version_id');
            $table->index('stable_question_key');
            $table->index('type');
            $table->index('position');
            $table->index('change_status_from_previous');

            $table->unique(['version_id', 'stable_question_key'], 'uq_version_item_stable_key');
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('lesson_exercise_version_items');
    }
};