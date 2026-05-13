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
        Schema::connection('app_mysql')->table('student_exercise_attempts', function (Blueprint $table) {
            if (!Schema::connection('app_mysql')->hasColumn('student_exercise_attempts', 'time_spent_seconds')) {
                $table->unsignedInteger('time_spent_seconds')->default(0)->after('status');
            }
            if (!Schema::connection('app_mysql')->hasColumn('student_exercise_attempts', 'question_count')) {
                $table->unsignedInteger('question_count')->default(0)->after('time_spent_seconds');
            }
            if (!Schema::connection('app_mysql')->hasColumn('student_exercise_attempts', 'answered_count')) {
                $table->unsignedInteger('answered_count')->default(0)->after('question_count');
            }
            if (!Schema::connection('app_mysql')->hasColumn('student_exercise_attempts', 'unanswered_count')) {
                $table->unsignedInteger('unanswered_count')->default(0)->after('answered_count');
            }
            if (!Schema::connection('app_mysql')->hasColumn('student_exercise_attempts', 'completion_rate')) {
                $table->decimal('completion_rate', 5, 2)->default(0)->after('unanswered_count');
            }
            if (!Schema::connection('app_mysql')->hasColumn('student_exercise_attempts', 'accuracy_rate')) {
                $table->decimal('accuracy_rate', 5, 2)->nullable()->after('completion_rate');
            }
            if (!Schema::connection('app_mysql')->hasColumn('student_exercise_attempts', 'last_saved_at')) {
                $table->timestamp('last_saved_at')->nullable()->after('accuracy_rate');
            }
            if (!Schema::connection('app_mysql')->hasColumn('student_exercise_attempts', 'submit_count')) {
                $table->unsignedInteger('submit_count')->default(0)->after('last_saved_at');
            }

            // $table->index('status');
            // $table->index('submitted_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('app_mysql')->table('student_exercise_attempts', function (Blueprint $table) {
            $table->dropColumn([
                'time_spent_seconds', 
                'question_count', 
                'answered_count', 
                'unanswered_count', 
                'completion_rate', 
                'accuracy_rate', 
                'last_saved_at',
                'submit_count'
            ]);
        });
    }
};
