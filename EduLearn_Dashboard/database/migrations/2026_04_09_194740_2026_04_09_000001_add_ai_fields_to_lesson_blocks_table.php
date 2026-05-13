<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::connection('app_mysql')->hasTable('lesson_blocks')) {
            return;
        }

        Schema::connection('app_mysql')->table('lesson_blocks', function (Blueprint $table) {
            if (!Schema::connection('app_mysql')->hasColumn('lesson_blocks', 'stable_key')) {
                $table->string('stable_key')->nullable()->after('lesson_id');
                $table->index('stable_key', 'lesson_blocks_stable_key_index');
            }

            if (!Schema::connection('app_mysql')->hasColumn('lesson_blocks', 'created_origin')) {
                $table->enum('created_origin', ['manual', 'ai'])
                    ->default('manual')
                    ->after('position');
                $table->index('created_origin', 'lesson_blocks_created_origin_index');
            }

            if (!Schema::connection('app_mysql')->hasColumn('lesson_blocks', 'last_edit_origin')) {
                $table->enum('last_edit_origin', ['manual', 'ai'])
                    ->default('manual')
                    ->after('created_origin');
                $table->index('last_edit_origin', 'lesson_blocks_last_edit_origin_index');
            }

            if (!Schema::connection('app_mysql')->hasColumn('lesson_blocks', 'ai_source_id')) {
                $table->unsignedBigInteger('ai_source_id')->nullable()->after('last_edit_origin');
                $table->index('ai_source_id', 'lesson_blocks_ai_source_id_index');
            }

            if (!Schema::connection('app_mysql')->hasColumn('lesson_blocks', 'ai_last_run_id')) {
                $table->unsignedBigInteger('ai_last_run_id')->nullable()->after('ai_source_id');
                $table->index('ai_last_run_id', 'lesson_blocks_ai_last_run_id_index');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::connection('app_mysql')->hasTable('lesson_blocks')) {
            return;
        }

        Schema::connection('app_mysql')->table('lesson_blocks', function (Blueprint $table) {
            if (Schema::connection('app_mysql')->hasColumn('lesson_blocks', 'ai_last_run_id')) {
                $table->dropIndex('lesson_blocks_ai_last_run_id_index');
                $table->dropColumn('ai_last_run_id');
            }

            if (Schema::connection('app_mysql')->hasColumn('lesson_blocks', 'ai_source_id')) {
                $table->dropIndex('lesson_blocks_ai_source_id_index');
                $table->dropColumn('ai_source_id');
            }

            if (Schema::connection('app_mysql')->hasColumn('lesson_blocks', 'last_edit_origin')) {
                $table->dropIndex('lesson_blocks_last_edit_origin_index');
                $table->dropColumn('last_edit_origin');
            }

            if (Schema::connection('app_mysql')->hasColumn('lesson_blocks', 'created_origin')) {
                $table->dropIndex('lesson_blocks_created_origin_index');
                $table->dropColumn('created_origin');
            }

            if (Schema::connection('app_mysql')->hasColumn('lesson_blocks', 'stable_key')) {
                $table->dropIndex('lesson_blocks_stable_key_index');
                $table->dropColumn('stable_key');
            }
        });
    }
};
