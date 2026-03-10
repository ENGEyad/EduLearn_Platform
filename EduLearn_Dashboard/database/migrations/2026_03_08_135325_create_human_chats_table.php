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
        Schema::connection('app_mysql')->create('human_chats', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('sender_id');
            $table->string('sender_type'); // 'teacher' or 'student'

            // للحوار الخاص (Teacher <-> Student)
            $table->unsignedBigInteger('receiver_id')->nullable();

            // للحوار الجماعي (بناءً على الفصل)
            $table->unsignedBigInteger('class_section_id')->nullable();

            $table->text('message');
            $table->string('type')->default('text'); // text, image, file
            $table->boolean('is_group')->default(false);

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('human_chats');
    }
};
