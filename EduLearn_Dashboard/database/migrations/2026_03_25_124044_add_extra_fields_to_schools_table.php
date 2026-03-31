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
            if (!Schema::hasColumn('schools', 'academic_year')) {
                $table->string('academic_year')->nullable()->after('activation_code');
            }
            if (!Schema::hasColumn('schools', 'school_type')) {
                $table->string('school_type')->nullable()->after('academic_year');
            }
            if (!Schema::hasColumn('schools', 'city')) {
                $table->string('city')->nullable()->after('school_type');
            }
            if (!Schema::hasColumn('schools', 'website')) {
                $table->string('website')->nullable()->after('city');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('schools', function (Blueprint $table) {
            $table->dropColumn(['academic_year', 'school_type', 'city', 'website']);
        });
    }
};
