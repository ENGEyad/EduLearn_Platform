<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('system_notification_reads', function (Blueprint $table) {
            $table->id();
            $table->foreignId('system_notification_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->timestamp('read_at')->useCurrent();
            $table->boolean('interacted')->default(false); // If they clicked the action URL
            $table->timestamps();
            
            // To prevent duplicate read logs for the same user on the same notification
            $table->unique(['system_notification_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('system_notification_reads');
    }
};
