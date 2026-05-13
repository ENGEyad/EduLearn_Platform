<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (Schema::connection('app_mysql')->hasTable('lesson_ai_runs')) {
            return;
        }

        Schema::connection('app_mysql')->create('lesson_ai_runs', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('lesson_id');
            $table->unsignedBigInteger('teacher_id');
            $table->unsignedBigInteger('ai_source_id')->nullable();

            $table->enum('action_type', [
                'generate_append_blocks',
                'rewrite_block',
                'simplify_block',
                'shorten_block',
                'expand_block',
                'clarify_block',
            ]);

            // stable_key للبلوك المستهدف في عمليات التعديل فقط
            $table->string('target_stable_key')->nullable();

            // اسم الأمر المختار من المعلم
            $table->string('instruction_key')->nullable();

            // لو احتجنا تخزين وصف إضافي مستقبلاً
            $table->text('instruction_text')->nullable();

            $table->enum('status', ['processing', 'completed', 'failed'])
                ->default('processing');

            // snapshot للمدخلات والمخرجات من أجل التتبع والتطوير لاحقاً
            $table->json('input_snapshot')->nullable();
            $table->json('output_snapshot')->nullable();

            $table->text('error_message')->nullable();

            $table->timestamps();

            $table->index('lesson_id');
            $table->index('teacher_id');
            $table->index('ai_source_id');
            $table->index('action_type');
            $table->index('status');
            $table->index('target_stable_key');
            $table->index(['lesson_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('lesson_ai_runs');
    }
};
