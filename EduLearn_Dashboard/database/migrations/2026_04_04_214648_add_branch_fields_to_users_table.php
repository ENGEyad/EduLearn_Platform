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
            // Flags whether the current password is temporary (requires forced change on first login).
            $table->boolean('is_temp_password')
                ->default(false)
                ->after('password')
                ->comment('TRUE = user must change password on next login.');

            // Tracks when the user last changed their password.
            $table->timestamp('last_password_change')
                ->nullable()
                ->after('is_temp_password')
                ->comment('Timestamp of last password change.');

            // Links a branch admin user directly to their branch school record.
            // Separate from school_id which points to the institution they belong to.
            $table->unsignedBigInteger('branch_id')
                ->nullable()
                ->after('school_id')
                ->comment('For branch_admin role: points to the branch (schools.id) they manage.');

            $table->foreign('branch_id')
                ->references('id')
                ->on('schools')
                ->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['branch_id']);
            $table->dropColumn(['is_temp_password', 'last_password_change', 'branch_id']);
        });
    }
};
