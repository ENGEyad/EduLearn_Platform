<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (Schema::connection('app_mysql')->hasTable('lesson_topics')) {
            return;
        }

        Schema::connection('app_mysql')->create('lesson_topics', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('lesson_id');
            $table->unsignedBigInteger('module_id')->nullable(); // موضوع داخل موديول
            $table->string('title');
            $table->unsignedInteger('position')->default(0);
            $table->timestamps();

            $table->index(['lesson_id', 'module_id']);
        });
    }

    public function down(): void
    {
        Schema::connection('app_mysql')->dropIfExists('lesson_topics');
    }
};
