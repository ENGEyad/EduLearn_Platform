<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('class_section_subjects', function (Blueprint $table) {
            $table->id();

            $table->foreignId('class_section_id')
                ->constrained('class_sections')
                ->onDelete('cascade');

            $table->foreignId('subject_id')
                ->constrained('subjects')
                ->onDelete('cascade');

            $table->boolean('is_active')->default(true);

            $table->timestamps();

            $table->unique(['class_section_id', 'subject_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('class_section_subjects');
    }
};
