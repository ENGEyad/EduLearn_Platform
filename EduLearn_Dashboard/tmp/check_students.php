<?php
require __DIR__ . '/../bootstrap/app.php';
$kernel = app()->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$schoolId = 5;
$count = \App\Models\Student::where('school_id', $schoolId)->count();
echo "Students count for school 5: " . $count . "\n";
