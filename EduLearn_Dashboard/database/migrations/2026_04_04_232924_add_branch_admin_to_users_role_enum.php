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
        Schema::table('users', function (Blueprint $table) {
            // Changing enum to string is more flexible as Laravel handles enums better in logic.
            // We set school_admin as default as it's the most common role for non-super admins.
            $table->string('role', 50)->default('school_admin')->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->enum('role', ['super_admin', 'school_admin'])->default('school_admin')->change();
        });
    }
};
