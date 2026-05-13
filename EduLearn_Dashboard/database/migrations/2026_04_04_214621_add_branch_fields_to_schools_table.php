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
        Schema::table('schools', function (Blueprint $table) {
            // Self-referencing FK: links a branch to its parent school.
            // Must be nullable since main schools have no parent.
            $table->unsignedBigInteger('parent_school_id')
                ->nullable()
                ->after('id')
                ->comment('NULL = Main school. Populated = Branch school. References schools.id.');

            $table->foreign('parent_school_id')
                ->references('id')
                ->on('schools')
                ->onDelete('cascade'); // If parent is deleted, all branches are deleted too.
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('schools', function (Blueprint $table) {
            $table->dropForeign(['parent_school_id']);
            $table->dropColumn('parent_school_id');
        });
    }
};
