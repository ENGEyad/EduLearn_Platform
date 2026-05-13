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
        Schema::table('system_notifications', function (Blueprint $table) {
            $table->enum('priority', ['normal', 'high', 'urgent'])->default('normal')->after('target_role');
            $table->string('action_url')->nullable()->after('priority');
            $table->timestamp('scheduled_at')->nullable()->after('action_url');
            $table->integer('read_count')->default(0)->after('scheduled_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('system_notifications', function (Blueprint $table) {
            $table->dropColumn(['priority', 'action_url', 'scheduled_at', 'read_count']);
        });
    }
};
