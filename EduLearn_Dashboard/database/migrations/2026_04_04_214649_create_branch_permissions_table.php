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
        Schema::create('branch_permissions', function (Blueprint $table) {
            $table->id();

            // The branch admin user for whom this permission applies.
            $table->foreignId('user_id')
                ->constrained('users')
                ->onDelete('cascade')
                ->comment('The branch admin user ID.');

            // The branch school this permission is scoped to.
            $table->foreignId('branch_id')
                ->constrained('schools')
                ->onDelete('cascade')
                ->comment('The branch school this permission applies to.');

            // The permission key (e.g. manage_students, view_reports, manage_teachers).
            $table->string('permission', 100)
                ->comment('Permission key, e.g. manage_students, view_reports, manage_classes.');

            // Whether they have this permission (true) or are explicitly denied (false).
            $table->boolean('granted')->default(true);

            $table->timestamps();

            // A user can only have one record per permission per branch.
            $table->unique(['user_id', 'branch_id', 'permission'], 'unique_branch_permission');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('branch_permissions');
    }
};
