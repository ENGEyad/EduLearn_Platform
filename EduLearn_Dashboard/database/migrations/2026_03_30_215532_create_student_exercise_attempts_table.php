<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::connection('app_mysql')->create('student_exercise_attempts', function (Blueprint $table) {
            $table->bigIncrements('id');

            $table->unsignedBigInteger('exercise_set_id');
            $table->unsignedBigInteger('exercise_version_id');
            $table->unsignedBigInteger('lesson_id');
            $table->unsignedBigInteger('student_id');

            $table->enum('status', [
                'in_progress',
                'submitted',
                'graded',
            ])->default('in_progress');

            $table->decimal('score', 10, 2)->nullable();
            $table->decimal('total_points', 10, 2)->nullable();

            $table->unsignedInteger('correct_count')->default(0);
            $table->unsignedInteger('wrong_count')->default(0);

            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('graded_at')->nullable();

            $table->unsignedBigInteger('last_synced_version_id')->nullable();
            $table->boolean('has_pending_changes')->default(false);

            $table->timestamps();

            $table->index('exercise_set_id');
            $table->index('exercise_version_id');
            $table->index('lesson_id');
            $table->index('student_id');
            $table->index('status');
            $table->index('has_pending_changes');
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('student_exercise_attempts');
    }
};