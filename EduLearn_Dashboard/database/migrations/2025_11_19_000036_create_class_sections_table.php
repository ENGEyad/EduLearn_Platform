<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('class_sections', function (Blueprint $table) {
            $table->id();
            $table->string('grade');      // مثال: 2, 3, 9
            $table->string('section');    // مثال: A, B, 1, 2
            $table->string('name');       // مثال: Grade 2 - A
            $table->string('stage')->nullable(); // ابتدائي، متوسط، ثانوي
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('class_sections');
    }
};
