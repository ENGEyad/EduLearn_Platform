<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

Schema::connection('app_mysql')->dropIfExists('lesson_exercise_options');
Schema::connection('app_mysql')->dropIfExists('lesson_exercise_questions');
Schema::connection('app_mysql')->dropIfExists('lesson_exercises');
DB::table('migrations')->where('migration', 'like', '%create_lesson_exercise%')->delete();
echo "Tables dropped and migrations removed.";
