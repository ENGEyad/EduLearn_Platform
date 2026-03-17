<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::connection('app_mysql')->create('lesson_exercises', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('lesson_id')->unique();
            $table->integer('version')->default(1);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            // Assuming lessons table is also on app_mysql
            $table->foreign('lesson_id')->references('id')->on('lessons')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('lesson_exercises');
    }
};
