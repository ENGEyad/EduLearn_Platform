<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::connection('app_mysql')->create('lesson_exercise_versions', function (Blueprint $table) {
            $table->bigIncrements('id');

            $table->unsignedBigInteger('exercise_set_id');
            $table->unsignedInteger('version_no');
            $table->unsignedBigInteger('previous_version_id')->nullable();

            $table->unsignedBigInteger('published_by_teacher_id')->nullable();

            $table->timestamp('published_at')->nullable();

            $table->string('content_hash', 120)->nullable();

            $table->boolean('is_active')->default(false);

            $table->json('change_summary_json')->nullable();
            $table->json('meta')->nullable();

            $table->timestamps();

            $table->index('exercise_set_id');
            $table->index('previous_version_id');
            $table->index('published_by_teacher_id');
            $table->index('is_active');

            $table->unique(['exercise_set_id', 'version_no'], 'uq_exercise_set_version_no');
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('lesson_exercise_versions');
    }
};