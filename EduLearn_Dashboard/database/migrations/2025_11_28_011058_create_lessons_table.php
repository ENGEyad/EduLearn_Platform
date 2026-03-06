<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {

        if (Schema::connection('app_mysql')->hasTable('lessons')) {
        return;
    }
        Schema::connection('app_mysql')->create('lessons', function (Blueprint $table) {
            $table->id();

            // 🔗 من قاعدة edulearn_db
            $table->unsignedBigInteger('teacher_id');
            $table->unsignedBigInteger('assignment_id')->nullable(); // teacher_class_subjects.id
             $table->unsignedBigInteger('class_module_id')->nullable(); // 👈 تضيفه هنا
            $table->unsignedBigInteger('class_section_id')->nullable();
            $table->unsignedBigInteger('subject_id')->nullable();

            $table->string('title');

            // draft / published
            $table->enum('status', ['draft', 'published'])->default('draft');
            $table->timestamp('published_at')->nullable();

            // إعدادات إضافية إن احتجناها
            $table->json('meta')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('lessons');
    }
};
