<?php

require 'vendor/autoload.php';

$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\School;
use App\Models\User;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\Subject;
use Illuminate\Support\Facades\Auth;

echo "=== PHASE 2 VERIFICATION ===" . PHP_EOL;

// 1. Setup Mock Data
echo "Setting up test data..." . PHP_EOL;
$schoolA = School::updateOrCreate(['email' => 'schoolA@test.com'], [
    'name' => 'School A', 'status' => 'active', 'is_initialized' => true, 'slug' => 'school-a'
]);
$schoolB = School::updateOrCreate(['email' => 'schoolB@test.com'], [
    'name' => 'School B', 'status' => 'active', 'is_initialized' => true, 'slug' => 'school-b'
]);

$adminA = User::updateOrCreate(['email' => 'adminA@test.com'], [
    'name' => 'Admin A', 'password' => bcrypt('password'), 'role' => 'school_admin', 'school_id' => $schoolA->id
]);

$studentA = Student::updateOrCreate(['academic_id' => 'V-TEST-A'], [
    'full_name' => 'Student A', 'school_id' => $schoolA->id
]);
$studentB = Student::updateOrCreate(['academic_id' => 'V-TEST-B'], [
    'full_name' => 'Student B', 'school_id' => $schoolB->id
]);

// 2. Test Multi-Tenancy in StudentController
echo PHP_EOL . "Checking Multi-Tenancy (StudentController@list)..." . PHP_EOL;
Auth::login($adminA);
$controller = new App\Http\Controllers\StudentController();
$list = $controller->list();

$count = count($list);
$hasB = $list->contains('full_name', 'Student B');

echo "  Admin A logged in (School A)." . PHP_EOL;
echo "  Students found: {$count}" . PHP_EOL;
echo "  Contains Student B (wrong school)? " . ($hasB ? "❌ YES (FAILURE)" : "✅ NO (SUCCESS)") . PHP_EOL;

// 3. Test Super Admin Rejection Logic
echo PHP_EOL . "Checking Super Admin Rejection Logic..." . PHP_EOL;
$superAdmin = User::where('role', 'super_admin')->first();
Auth::login($superAdmin);

$testSchool = School::updateOrCreate(['email' => 'pending@test.com'], [
    'name' => 'Pending School', 'status' => 'pending', 'slug' => 'pending-school'
]);

$superController = new App\Http\Controllers\SuperAdminController();
$request = new \Illuminate\Http\Request(['reason' => 'Invalid document uploaded.']);
$superController->reject($request, $testSchool);

$testSchool->refresh();
echo "  School Status after rejection: {$testSchool->status}" . PHP_EOL;
echo "  Rejection Reason: {$testSchool->rejection_reason}" . PHP_EOL;
echo "  Check: " . ($testSchool->status === 'rejected' && $testSchool->rejection_reason === 'Invalid document uploaded.' ? "✅ SUCCESS" : "❌ FAILURE") . PHP_EOL;

// 4. Test Email Rendering
echo PHP_EOL . "Checking Email Template Rendering..." . PHP_EOL;
try {
    $mailable = new App\Mail\SchoolApproved($schoolA);
    $html = $mailable->render();
    echo "  SchoolApproved template: ✅ RENDERS" . PHP_EOL;
} catch (\Exception $e) {
    echo "  SchoolApproved template: ❌ FAILED (" . $e->getMessage() . ")" . PHP_EOL;
}

echo PHP_EOL . "=== VERIFICATION COMPLETE ===" . PHP_EOL;
