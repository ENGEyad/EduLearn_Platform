<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('students', function (Blueprint $table) {
            $table->id();
            $table->string('full_name');
            $table->string('academic_id')->unique()->nullable();
            $table->string('gender')->nullable();
            $table->date('birthdate')->nullable();
            $table->string('email')->nullable();
            $table->string('status')->default('Active');
            $table->string('grade')->nullable();
            $table->string('class_section')->nullable();
            // address parts
            $table->string('address_governorate')->nullable();
            $table->string('address_city')->nullable();
            $table->string('address_street')->nullable();
            // guardian
            $table->string('guardian_name')->nullable();
            $table->string('guardian_relation')->nullable();
            $table->string('guardian_relation_other')->nullable();
            $table->string('guardian_phone')->nullable();
            // performance
            $table->decimal('performance_avg', 5, 2)->nullable();
            $table->decimal('attendance_rate', 5, 2)->nullable();
            // optional photo path
            $table->string('photo_path')->nullable();
            // optional multiple phones
            $table->json('guardian_phones')->nullable();
            // notes
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('students');
    }
};
