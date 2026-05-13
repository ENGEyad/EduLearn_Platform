<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::connection('app_mysql')->create('lesson_exercise_sets', function (Blueprint $table) {
            $table->bigIncrements('id');

            $table->unsignedBigInteger('lesson_id');
            $table->unsignedBigInteger('teacher_id');

            $table->string('title')->nullable();

            $table->enum('status', [
                'draft',
                'published',
                'archived',
                'needs_review',
            ])->default('draft');

            $table->enum('generation_source', [
                'manual',
                'ai',
                'mixed',
            ])->default('manual');

            $table->unsignedInteger('current_draft_no')->default(1);
            $table->unsignedBigInteger('current_published_version_id')->nullable();

            $table->boolean('needs_review')->default(false);

            $table->timestamp('published_at')->nullable();
            $table->timestamp('archived_at')->nullable();

            $table->json('meta')->nullable();

            $table->timestamps();

            $table->index('lesson_id');
            $table->index('teacher_id');
            $table->index('status');

            $table->unique('lesson_id', 'uq_exercise_set_per_lesson');
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('lesson_exercise_sets');
    }
};