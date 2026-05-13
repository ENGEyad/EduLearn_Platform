<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::connection('app_mysql')->hasTable('messages')) {
            return;
        }

        if (Schema::connection('app_mysql')->hasColumn('messages', 'delivered_at')) {
            return;
        }

        Schema::connection('app_mysql')->table('messages', function (Blueprint $table) {
            $table->timestamp('delivered_at')->nullable()->after('sent_at');
            $table->index('delivered_at');
        });
    }

    public function down(): void
    {
        if (!Schema::connection('app_mysql')->hasTable('messages')) {
            return;
        }

        if (!Schema::connection('app_mysql')->hasColumn('messages', 'delivered_at')) {
            return;
        }

        Schema::connection('app_mysql')->table('messages', function (Blueprint $table) {
            $table->dropIndex(['delivered_at']);
            $table->dropColumn('delivered_at');
        });
    }
};
