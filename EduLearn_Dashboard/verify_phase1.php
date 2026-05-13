<?php

require 'vendor/autoload.php';

$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "=== Subjects (" . App\Models\Subject::count() . " total) ===" . PHP_EOL;
foreach (App\Models\Subject::all() as $s) {
    echo "  {$s->code} | {$s->name_en} | {$s->name_ar}" . PHP_EOL;
}

echo PHP_EOL . "=== Super Admin ===" . PHP_EOL;
$admin = App\Models\User::where('role', 'super_admin')->first();
if ($admin) {
    echo "  Email: {$admin->email} | Role: {$admin->role}" . PHP_EOL;
} else {
    echo "  NOT FOUND" . PHP_EOL;
}

echo PHP_EOL . "=== Schema Check ===" . PHP_EOL;
$checks = [
    ['schools', 'section'],
    ['schools', 'admin_name'],
    ['schools', 'num_students'],
    ['schools', 'rejection_reason'],
    ['schools', 'is_initialized'],
    ['students', 'school_id'],
    ['teachers', 'school_id'],
    ['class_sections', 'school_id'],
];
foreach ($checks as [$table, $col]) {
    $exists = Illuminate\Support\Facades\Schema::hasColumn($table, $col);
    echo "  {$table}.{$col}: " . ($exists ? '✅ YES' : '❌ NO') . PHP_EOL;
}

echo PHP_EOL . "school_subjects table: " . (Illuminate\Support\Facades\Schema::hasTable('school_subjects') ? '✅ YES' : '❌ NO') . PHP_EOL;

echo PHP_EOL . "=== VERIFICATION COMPLETE ===" . PHP_EOL;
