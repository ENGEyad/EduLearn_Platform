<?php

use App\Models\School;
use App\Models\Subject;
use App\Models\ClassSection;

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$school = School::latest()->first();

if (!$school) {
    echo "No schools found.\n";
    exit;
}

echo "Current School: {$school->name} (ID: {$school->id})\n";
echo "Type: {$school->school_type}\n";
echo "Initialized: " . ($school->is_initialized ? 'Yes' : 'No') . "\n";

$sections = ClassSection::where('school_id', $school->id)->get();
echo "Classes Count: " . $sections->count() . "\n";
foreach($sections->groupBy('grade') as $grade => $group) {
    echo "  Grade {$grade}: " . $group->count() . " sections\n";
}

$subjects = $school->subjects;
echo "Subjects Count: " . $subjects->count() . "\n";
foreach($subjects as $s) {
    echo "  - {$s->name_ar} ({$s->name_en}) [{$s->pivot->is_active}]\n";
}

// Force a deep clean and re-init for school 8 if needed
if (true) {
    echo "\nPerforming Deep Clean for School {$school->id}...\n";
    
    // Clear Sections
    ClassSection::where('school_id', $school->id)->delete();
    
    // Clear Subjects
    $school->subjects()->detach();
    
    // Re-init with Primary
    $school->update(['school_type' => 'Primary', 'is_initialized' => true]);
    
    // Add 8 core subjects (mimicking wizard selection)
    $coreSubjectIds = Subject::whereIn('code', ['QR01', 'IS01', 'AR01', 'EN01', 'MA01', 'SC01', 'SO01', 'CS01'])->pluck('id');
    $school->subjects()->syncWithPivotValues($coreSubjectIds, ['is_active' => true]);
    
    // Build Structure
    $startGrade = 1;
    $endGrade = 6;
    for ($gradeNum = $startGrade; $gradeNum <= $endGrade; $gradeNum++) {
        foreach (['أ', 'ب'] as $letter) {
            ClassSection::create([
                'school_id' => $school->id,
                'grade'     => $gradeNum,
                'section'   => $letter,
                'name'      => "Grade {$gradeNum} - {$letter}",
                'stage'     => 'Primary',
                'is_active' => true
            ]);
        }
    }
    echo "Deep Clean Complete.\n";
}
