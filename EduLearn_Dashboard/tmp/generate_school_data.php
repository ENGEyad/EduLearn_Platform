<?php
// tmp/generate_school_data.php
require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\School;
use App\Models\ClassSection;
use App\Models\Teacher;
use App\Models\Student;
use App\Models\Subject;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

// Configuration
$schoolId = 5; // Assuming this is the school ID for Al-Aqsa Schools Modern
$school = School::find($schoolId);
if (!$school) {
    die("School not found!");
}

echo "=== Wiping Data for School: {$school->name} ===\n";
DB::statement('SET FOREIGN_KEY_CHECKS=0;');
Student::where('school_id', $schoolId)->delete();
Teacher::where('school_id', $schoolId)->delete();
ClassSection::where('school_id', $schoolId)->delete();
DB::statement('SET FOREIGN_KEY_CHECKS=1;');
echo "Data wiped successfully.\n\n";

// Naming Resources (Yemeni Prefixes/Families)
$firstNamesM = ['أحمد', 'عبدالله', 'محمد', 'علي', 'حسين', 'حسن', 'يحيى', 'قاسم', 'إبراهيم', 'سليمان', 'فؤاد', 'صالح', 'فارس', 'وليد', 'باسم', 'هاني', 'عمار', 'رامي', 'مازن', 'سامي'];
$firstNamesF = ['سارة', 'فاطمة', 'عائشة', 'ريم', 'أمل', 'هدى', 'منى', 'ليلى', 'زينب', 'بلقيس', 'أروى', 'يسرى', 'خلود', 'عبير', 'نورا', 'سلوى', 'حنان', 'مريم', 'إيمان', 'فوزية'];
$lastNames = ['الحاشدي', 'البكاري', 'الذيفاني', 'السفياني', 'اليدومي', 'الإرياني', 'الجبري', 'المؤيد', 'الخميسي', 'القرشي', 'الأهجري', 'البيضاني', 'الزبيري', 'الوزير', 'المطري', 'المتوكل', 'الشريف', 'الصايدي', 'القاسمي', 'الحرازي', 'الهمداني', 'المذحجي', 'الكندي', 'اليافعي'];

function generateName($isFemale = false) {
    global $firstNamesM, $firstNamesF, $lastNames;
    $first = $isFemale ? $firstNamesF[array_rand($firstNamesF)] : $firstNamesM[array_rand($firstNamesM)];
    $father = $firstNamesM[array_rand($firstNamesM)];
    $last = $lastNames[array_rand($lastNames)];
    return "{$first} {$father} {$last}";
}

$importDir = __DIR__ . '/../public/imports/';
if (!file_exists($importDir)) mkdir($importDir, 0777, true);

// 1. Generate Classes CSV
$classesFile = fopen($importDir . 'classes_import.csv', 'w');
fputcsv($classesFile, ['grade', 'section', 'name', 'stage']);
for ($g = 1; $g <= 12; $g++) {
    foreach (['أ', 'ب'] as $s) {
        $stage = ($g <= 6) ? 'Primary' : (($g <= 9) ? 'Middle' : 'Secondary');
        fputcsv($classesFile, [$g, $s, "Grade {$g} - {$s}", $stage]);
    }
}
fclose($classesFile);
echo "Generated public/imports/classes_import.csv\n";

// 2. Generate Teachers CSV
$subjects = Subject::all();
$teachersFile = fopen($importDir . 'teachers_import.csv', 'w');
fputcsv($teachersFile, ['full_name', 'email', 'phone', 'specialization', 'is_active', 'photo_path']);
for ($i = 0; $i < 16; $i++) {
    $name = generateName(rand(0, 10) > 7);
    $spec = ($subjects->count() > 0) ? $subjects[$i % $subjects->count()]->name_en : 'General';
    $email = 'teacher' . ($i + 1) . '@example.com';
    $photo = "teachers/teacher_" . ($i + 1) . ".jpg";
    fputcsv($teachersFile, [$name, $email, '77'.rand(1000000, 9999999), $spec, 1, $photo]);
}
fclose($teachersFile);
echo "Generated public/imports/teachers_import.csv\n";

// 3. Generate Students CSV
$studentsFile = fopen($importDir . 'students_import.csv', 'w');
fputcsv($studentsFile, ['full_name', 'email', 'parent_phone', 'gender', 'grade', 'section', 'photo_path']);
for ($g = 1; $g <= 12; $g++) {
    foreach (['أ', 'ب'] as $s) {
        for ($i = 0; $i < 50; $i++) {
            $isF = rand(0, 1) == 1;
            $name = generateName($isF);
            $email = 'student' . $g . '_' . $s . '_' . ($i + 1) . '@example.com';
            $photo = "students/student_" . $g . "_" . $s . "_" . ($i + 1) . ".jpg";
            fputcsv($studentsFile, [$name, $email, '7'.rand(10000000, 99999999), $isF ? 'female' : 'male', $g, $s, $photo]);
        }
    }
}
fclose($studentsFile);
echo "Generated public/imports/students_import.csv\n";

echo "\nDone! All files generated in public/imports/\n";
