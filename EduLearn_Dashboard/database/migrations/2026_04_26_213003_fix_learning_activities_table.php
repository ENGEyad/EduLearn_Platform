<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * هذا الملف يعالج المشكلة الأساسية في جدول learning_activities.
     */
    public function up(): void
    {
        $connection = 'app_mysql';
        $tableName = 'learning_activities';

        if (!Schema::connection($connection)->hasTable($tableName)) {
            Schema::connection($connection)->create($tableName, function (Blueprint $table) {
                $table->id();

                $table->string('actor_type', 50)->default('system');
                $table->unsignedBigInteger('actor_id')->nullable();
                $table->string('actor_code', 100)->nullable();
                $table->string('actor_name')->nullable();

                $table->string('target_type', 50);
                $table->unsignedBigInteger('target_id')->nullable();
                $table->string('target_code', 100)->nullable();

                $table->unsignedBigInteger('class_section_id')->nullable();
                $table->unsignedBigInteger('subject_id')->nullable();
                $table->unsignedBigInteger('lesson_id')->nullable();
                $table->unsignedBigInteger('exercise_set_id')->nullable();
                $table->unsignedBigInteger('exercise_attempt_id')->nullable();

                $table->string('event_type', 100);
                $table->string('title');
                $table->text('body')->nullable();
                $table->json('meta')->nullable();
                $table->timestamp('read_at')->nullable();

                $table->timestamps();

                $table->index(['target_type', 'target_id']);
                $table->index(['target_type', 'target_code']);
                $table->index(['actor_type', 'actor_id']);
                $table->index('event_type');
                $table->index('class_section_id');
                $table->index('subject_id');
                $table->index('lesson_id');
                $table->index('exercise_set_id');
                $table->index('exercise_attempt_id');
                $table->index('read_at');
                $table->index('created_at');
            });

            return;
        }

        Schema::connection($connection)->table($tableName, function (Blueprint $table) use ($connection, $tableName) {
            if (!Schema::connection($connection)->hasColumn($tableName, 'actor_type')) {
                $table->string('actor_type', 50)->default('system')->after('id');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'actor_id')) {
                $table->unsignedBigInteger('actor_id')->nullable()->after('actor_type');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'actor_code')) {
                $table->string('actor_code', 100)->nullable()->after('actor_id');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'actor_name')) {
                $table->string('actor_name')->nullable()->after('actor_code');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'target_type')) {
                $table->string('target_type', 50)->after('actor_name');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'target_id')) {
                $table->unsignedBigInteger('target_id')->nullable()->after('target_type');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'target_code')) {
                $table->string('target_code', 100)->nullable()->after('target_id');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'class_section_id')) {
                $table->unsignedBigInteger('class_section_id')->nullable()->after('target_code');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'subject_id')) {
                $table->unsignedBigInteger('subject_id')->nullable()->after('class_section_id');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'lesson_id')) {
                $table->unsignedBigInteger('lesson_id')->nullable()->after('subject_id');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'exercise_set_id')) {
                $table->unsignedBigInteger('exercise_set_id')->nullable()->after('lesson_id');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'exercise_attempt_id')) {
                $table->unsignedBigInteger('exercise_attempt_id')->nullable()->after('exercise_set_id');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'event_type')) {
                $table->string('event_type', 100)->after('exercise_attempt_id');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'title')) {
                $table->string('title')->after('event_type');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'body')) {
                $table->text('body')->nullable()->after('title');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'meta')) {
                $table->json('meta')->nullable()->after('body');
            }
            if (!Schema::connection($connection)->hasColumn($tableName, 'read_at')) {
                $table->timestamp('read_at')->nullable()->after('meta');
            }
        });
    }

    public function down(): void
    {
    }
};
