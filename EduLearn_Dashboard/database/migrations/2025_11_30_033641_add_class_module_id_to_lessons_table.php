<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // لو جدول lessons أصلاً مش موجود على app_mysql ما في شيء نعمله
        if (! Schema::connection('app_mysql')->hasTable('lessons')) {
            return;
        }

        // لو العمود أصلاً موجود، لا تضيفه مرة ثانية
        if (! Schema::connection('app_mysql')->hasColumn('lessons', 'class_module_id')) {
            Schema::connection('app_mysql')->table('lessons', function (Blueprint $table) {
                $table->unsignedBigInteger('class_module_id')->nullable()->after('assignment_id');

                // (اختياري) لو حاب تربط بـ class_modules كـ foreign key:
                // $table->foreign('class_module_id')
                //       ->references('id')
                //       ->on('class_modules')
                //       ->onDelete('set null');
            });
        }
    }

    public function down(): void
    {
        // لو الجدول مش موجود ما في داعي نكمل
        if (! Schema::connection('app_mysql')->hasTable('lessons')) {
            return;
        }

        if (Schema::connection('app_mysql')->hasColumn('lessons', 'class_module_id')) {
            Schema::connection('app_mysql')->table('lessons', function (Blueprint $table) {
                // لو كنت مفعّل الـ FK فوق لازم تحذفه هنا:
                // $table->dropForeign(['class_module_id']);

                $table->dropColumn('class_module_id');
            });
        }
    }
};
