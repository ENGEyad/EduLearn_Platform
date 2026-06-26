<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // هنا نشتغل على قاعدة الداشبورد، نفترض اسمها mysql
        $connection = config('database.default') === 'sqlite' ? 'sqlite' : 'mysql';
        Schema::connection($connection)->dropIfExists('messages');
        Schema::connection($connection)->dropIfExists('conversations');
    }

    public function down(): void
    {
        // بإمكانك تركه فاضي لأننا ما نحتاج نرجّع الجداول
        // أو لو حاب تبنيها من جديد تقدر تكتب create هنا
    }
};
