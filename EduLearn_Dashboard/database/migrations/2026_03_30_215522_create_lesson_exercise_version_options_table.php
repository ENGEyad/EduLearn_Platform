<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::connection('app_mysql')->create('lesson_exercise_version_options', function (Blueprint $table) {
            $table->bigIncrements('id');

            $table->unsignedBigInteger('version_item_id');

            $table->uuid('stable_option_key');

            $table->longText('option_text');
            $table->boolean('is_correct')->default(false);

            $table->unsignedInteger('position')->default(1);

            $table->timestamps();

            $table->index('version_item_id');
            $table->index('stable_option_key');
            $table->index('position');

            $table->unique(['version_item_id', 'stable_option_key'], 'uq_version_option_stable_key');
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('lesson_exercise_version_options');
    }
};