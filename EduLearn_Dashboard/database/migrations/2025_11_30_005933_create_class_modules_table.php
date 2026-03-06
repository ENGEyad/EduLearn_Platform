<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::connection('app_mysql')->hasTable('class_modules')) {
            return;
        }

        Schema::connection('app_mysql')->create('class_modules', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('teacher_id');
            $table->unsignedBigInteger('assignment_id');
            $table->unsignedBigInteger('class_section_id');
            $table->unsignedBigInteger('subject_id');
            $table->string('title');
            $table->integer('position')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('class_modules');
    }
};
