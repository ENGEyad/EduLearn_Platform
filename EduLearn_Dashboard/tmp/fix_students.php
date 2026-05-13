<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\School;
use App\Models\ClassSection;
use App\Models\Student;
use Illuminate\Support\Facades\DB;

$schoolId = 5;

echo "=== Wiping Students for School: $schoolId ===\n";
DB::statement('SET FOREIGN_KEY_CHECKS=0;');
Student::where('school_id', $schoolId)->delete();
DB::statement('SET FOREIGN_KEY_CHECKS=1;');

// Naming Resources
$firstNamesM = ['أحمد', 'عبدالله', 'محمد', 'علي', 'حسين', 'حسن', 'يحيى', 'قاسم', 'إبراهيم', 'سليمان', 'فؤاد', 'صالح', 'فارس', 'وليد'];
$firstNamesF = ['سارة', 'فاطمة', 'عائشة', 'ريم', 'أمل', 'هدى', 'منى', 'ليلى', 'زينب', 'بلقيس', 'أروى', 'يسرى', 'خلود', 'عبير'];
$lastNames = ['الحاشدي', 'البكاري', 'الذيفاني', 'السفياني', 'اليدومي', 'الإرياني', 'الجبري', 'المؤيد', 'الخميسي', 'القرشي', 'الأهجري'];

function generateName($isFemale = false) {
    global $firstNamesM, $firstNamesF, $lastNames;
    $first = $isFemale ? $firstNamesF[array_rand($firstNamesF)] : $firstNamesM[array_rand($firstNamesM)];
    $father = $firstNamesM[array_rand($firstNamesM)];
    $last = $lastNames[array_rand($lastNames)];
    return "{$first} {$father} {$last}";
}

$classes = ClassSection::where('school_id', $schoolId)->get();

if ($classes->isEmpty()) {
    die("No classes found. Please import classes first.\n");
}

$studentsToCreate = [];
$seqId = 10001; // Start sequence

foreach ($classes as $class) {
    for ($i = 1; $i <= 50; $i++) {
        $isF = rand(0, 1) == 1;
        $name = generateName($isF);
        
        $studentsToCreate[] = [
            'school_id' => $schoolId,
            'full_name' => $name,
            'academic_id' => "EDU-2026-S-" . $seqId++, // Guaranteed unique
            'gender' => $isF ? 'Female' : 'Male',
            'status' => 'Active',
            'grade' => $class->grade,
            'class_section' => $class->section,
            'class_section_id' => $class->id,
            'total_study_time_seconds' => rand(10000, 100000), // Random study time so charts look good
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}

// Insert in chunks
foreach (array_chunk($studentsToCreate, 500) as $chunk) {
    Student::insert($chunk);
}

echo "Inserted " . count($studentsToCreate) . " students successfully.\n";
