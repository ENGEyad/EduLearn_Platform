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
        Schema::table('students', function (Blueprint $table) {
            // Using longblob for MySQL if needed, binary() is usually sufficient for medium blobs
            // For Laravel 10/11, binary works well.
            $table->binary('photo_data')->nullable()->after('photo_path');
            $table->string('photo_mime')->nullable()->after('photo_data');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('students', function (Blueprint $table) {
            $table->dropColumn(['photo_data', 'photo_mime']);
        });
    }
};
