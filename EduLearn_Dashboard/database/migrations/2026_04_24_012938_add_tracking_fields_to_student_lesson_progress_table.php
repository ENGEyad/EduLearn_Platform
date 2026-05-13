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
        Schema::connection('app_mysql')->table('student_lesson_progress', function (Blueprint $table) {
            if (!Schema::connection('app_mysql')->hasColumn('student_lesson_progress', 'time_spent_seconds')) {
                $table->unsignedInteger('time_spent_seconds')->default(0)->after('status');
            }
            if (!Schema::connection('app_mysql')->hasColumn('student_lesson_progress', 'last_opened_at')) {
                $table->timestamp('last_opened_at')->nullable()->after('time_spent_seconds');
            }
            
            $table->index('status');
            $table->index('last_opened_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('app_mysql')->table('student_lesson_progress', function (Blueprint $table) {
            $table->dropColumn(['time_spent_seconds', 'last_opened_at']);
        });
    }
};
