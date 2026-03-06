<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (Schema::connection('app_mysql')->hasTable('lesson_blocks')) {
            return;
        }

        Schema::connection('app_mysql')->create('lesson_blocks', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('lesson_id');

            // روابط الهيكلة
            $table->unsignedBigInteger('module_id')->nullable();
            $table->unsignedBigInteger('topic_id')->nullable();
            $table->unsignedBigInteger('subtopic_id')->nullable();

            // text / image / video / audio
            $table->string('type', 20);

            // للنص + الكابتشن
            $table->longText('body')->nullable();      // النص الرئيسي
            $table->string('caption')->nullable();     // كابشن بخط صغير أسفل العنصر

            // العناصر الإعلامية
            $table->string('media_path')->nullable();  // storage/app/...
            $table->string('media_url')->nullable();   // asset('storage/...')
            $table->string('media_mime')->nullable();
            $table->unsignedInteger('media_size')->nullable(); // KB
            $table->unsignedInteger('media_duration')->nullable(); // للصوت/الفيديو بالثواني

            $table->unsignedInteger('position')->default(0); // ترتيب العنصر داخل الدرس

            // خصائص إضافية (حجم الخط، تنسيقات...)
            $table->json('meta')->nullable();

            $table->timestamps();

            $table->index(['lesson_id', 'module_id', 'topic_id', 'subtopic_id']);
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('lesson_blocks');
    }
};
