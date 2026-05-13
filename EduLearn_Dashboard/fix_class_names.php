<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\ClassSection;

echo "Fixing Class Names for all schools...\n";

$sectionMap = ['أ' => 'A', 'ب' => 'B', 'ج' => 'C', 'د' => 'D'];
$classes = ClassSection::all();

foreach ($classes as $class) {
    $engLetter = $sectionMap[$class->section] ?? $class->section;
    $class->name_en = "Grade {$class->grade} - {$engLetter}";
    $class->name_ar = "الصف {$class->grade} - {$class->section}";
    $class->name = $class->name_en; // Default
    $class->save();
}

echo "Finished. Fixed " . $classes->count() . " classes.\n";
