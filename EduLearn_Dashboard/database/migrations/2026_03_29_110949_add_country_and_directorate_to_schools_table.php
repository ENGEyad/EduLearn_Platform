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
            if (!Schema::hasColumn('schools', 'country')) {
                $table->string('country')->nullable()->after('website');
            }
            if (!Schema::hasColumn('schools', 'directorate')) {
                $table->string('directorate')->nullable()->after('city');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('schools', function (Blueprint $table) {
            $table->dropColumn(['country', 'directorate']);
        });
    }
};
