<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$user = App\Models\User::where('role','school_admin')->first();
auth()->login($user);
$controller = new App\Http\Controllers\SubjectController();
try {
    $res = $controller->list();
    echo substr($res->getContent(), 0, 500);
} catch (\Throwable $e) {
    echo "ERROR: " . $e->getMessage();
}
