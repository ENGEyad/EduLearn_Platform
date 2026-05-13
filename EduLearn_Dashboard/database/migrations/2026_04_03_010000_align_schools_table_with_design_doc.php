<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Align the schools table with the updated design document.
     * Adds missing fields: section, admin_name, num_students,
     * rejection_reason, is_initialized, and a 'rejected' status.
     */
    public function up(): void
    {
        Schema::table('schools', function (Blueprint $table) {
            if (!Schema::hasColumn('schools', 'section')) {
                $table->string('section')->nullable()->after('school_type')
                    ->comment('Scientific, Literary, Scientific/Literary');
            }

            if (!Schema::hasColumn('schools', 'admin_name')) {
                $table->string('admin_name')->nullable()->after('address');
            }

            if (!Schema::hasColumn('schools', 'num_students')) {
                $table->unsignedInteger('num_students')->nullable()->after('admin_name')
                    ->comment('Number of students the school plans to register');
            }

            if (!Schema::hasColumn('schools', 'rejection_reason')) {
                $table->text('rejection_reason')->nullable()->after('status');
            }

            if (!Schema::hasColumn('schools', 'is_initialized')) {
                $table->boolean('is_initialized')->default(false)->after('rejection_reason')
                    ->comment('Whether the school has completed the system initialization wizard');
            }
        });

        // Update status enum to include 'rejected' — safe for MySQL
        // The existing values (pending, active, suspended) are kept.
        // We change the column to a string to be more flexible
        // (Laravel enums are tricky to alter).
        if (Schema::hasColumn('schools', 'status')) {
            Schema::table('schools', function (Blueprint $table) {
                $table->string('status', 50)->default('pending')->change();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('schools', function (Blueprint $table) {
            $columns = ['section', 'admin_name', 'num_students', 'rejection_reason', 'is_initialized'];
            foreach ($columns as $col) {
                if (Schema::hasColumn('schools', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
