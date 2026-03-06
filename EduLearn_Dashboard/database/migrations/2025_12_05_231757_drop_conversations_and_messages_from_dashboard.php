<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // هنا نشتغل على قاعدة الداشبورد، نفترض اسمها mysql
        Schema::connection('mysql')->dropIfExists('messages');
        Schema::connection('mysql')->dropIfExists('conversations');
    }

    public function down(): void
    {
        // بإمكانك تركه فاضي لأننا ما نحتاج نرجّع الجداول
        // أو لو حاب تبنيها من جديد تقدر تكتب create هنا
    }
};
