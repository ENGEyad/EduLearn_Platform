<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::connection('app_mysql')->create('messages', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('conversation_id');

            $table->string('sender_type'); // teacher | student
            $table->unsignedBigInteger('sender_id');

            $table->text('body');

            $table->timestamp('sent_at')->nullable();
            $table->timestamp('read_at')->nullable();

            $table->timestamps();

            $table->index('conversation_id');
            $table->index(['sender_type', 'sender_id']);
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('messages');
    }
};
