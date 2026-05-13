<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\School;
use App\Models\Subject;

$schoolId = 5; // Al-Aqsa Modern Schools
$importDir = __DIR__ . '/../public/imports/';
if (!file_exists($importDir)) mkdir($importDir, 0777, true);

// Get the DB data to build relations
$subjects = Subject::all();
$classesPath = $importDir . 'classes_import.csv';
$teachersPath = $importDir . 'teachers_import.csv';

if (!file_exists($classesPath) || !file_exists($teachersPath)) {
    die("Error: classes_import.csv or teachers_import.csv not found. Please run generate_school_data.php first.\n");
}

// Read Classes
$handleC = fopen($classesPath, 'r');
fgetcsv($handleC); // skip header
$classesData = [];
while (($row = fgetcsv($handleC)) !== false) {
    if (count($row) >= 2) {
        $classesData[] = ['grade' => $row[0], 'section' => $row[1]];
    }
}
fclose($handleC);

// Read Teachers
$handleT = fopen($teachersPath, 'r');
fgetcsv($handleT); // skip header
$teachersData = [];
while (($row = fgetcsv($handleT)) !== false) {
    if (count($row) >= 4) {
        $teachersData[] = [
            'name' => $row[0], 
            'subject' => $row[3], // From specialization column
        ];
    }
}
fclose($handleT);

// Build assignments
// Rule: assign a different teacher for the same subject to each branch (if possible).
$assignmentsFile = fopen($importDir . 'assignments_import.csv', 'w');
fputcsv($assignmentsFile, ['teacher', 'grade', 'section', 'subject']);

// Group teachers by subject
$teachersBySubject = [];
foreach ($teachersData as $t) {
    $teachersBySubject[$t['subject']][] = $t;
}

$count = 0;
foreach ($classesData as $class) {
    $grade = $class['grade'];
    $section = $class['section'];

    // For every subject, try to assign a teacher
    foreach ($subjects as $subject) {
        $subName = $subject->name_en;
        $availableTeachers = $teachersBySubject[$subName] ?? [];
        
        if (count($availableTeachers) > 0) {
            // Pick a teacher based on section. If section is 'أ', pick first teacher, if 'ب', pick second.
            // If only 1 teacher for subject, fallback to them.
            if ($section === 'أ') {
                $teacher = $availableTeachers[0];
            } else {
                $teacher = isset($availableTeachers[1]) ? $availableTeachers[1] : $availableTeachers[0];
            }
            
            fputcsv($assignmentsFile, [$teacher['name'], $grade, $section, $subName]);
            $count++;
        }
    }
}

fclose($assignmentsFile);
echo "Generated public/imports/assignments_import.csv with {$count} assignments.\n";
