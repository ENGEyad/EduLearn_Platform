<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (Schema::connection('app_mysql')->hasTable('lesson_ai_sources')) {
            return;
        }

        Schema::connection('app_mysql')->create('lesson_ai_sources', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('lesson_id');
            $table->unsignedBigInteger('teacher_id');

            // text | pdf
            $table->enum('source_type', ['text', 'pdf']);

            // عند رفع PDF فقط
            $table->string('source_file_path')->nullable();
            $table->string('source_file_name')->nullable();
            $table->string('source_file_mime')->nullable();
            $table->unsignedBigInteger('source_file_size')->nullable();

            // عند الإدخال النصي فقط
            $table->longText('source_text')->nullable();

            // النص المستخرج النهائي المستخدم من الذكاء
            $table->longText('extracted_text');

            // لتفادي تكرار نفس المصدر مستقبلاً عند الحاجة
            $table->string('content_hash', 64)->nullable();

            // مصدر نشط واحد للدرس غالباً
            $table->boolean('is_active')->default(true);

            $table->timestamps();

            $table->index('lesson_id');
            $table->index('teacher_id');
            $table->index(['lesson_id', 'is_active']);
            $table->index('source_type');
            $table->index('content_hash');
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('lesson_ai_sources');
    }
};
