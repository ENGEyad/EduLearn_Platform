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
        Schema::table('dashboard_notifications', function (Blueprint $table) {
            // Optimized index for header notifications:
            // 1. latest notifications: where school_id = ? order by created_at desc
            // 2. unread count: where school_id = ? and is_read = false
            $table->index(['school_id', 'is_read', 'created_at'], 'idx_notifications_perf');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('dashboard_notifications', function (Blueprint $table) {
            $table->dropIndex('idx_notifications_perf');
        });
    }
};
