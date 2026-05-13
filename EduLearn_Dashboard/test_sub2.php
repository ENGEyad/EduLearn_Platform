<?php
use Illuminate\Http\Request;
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$user = App\Models\User::where('role','school_admin')->first();
auth()->login($user);

// Simulate the fetch request
try {
    $request = Request::create('/subjects/list', 'GET');
    $response = app()->handle($request);
    echo "Status: " . $response->getStatusCode() . "\n";
    echo substr($response->getContent(), 0, 500) . "\n";
} catch (\Throwable $e) {
    echo "ERROR: " . $e->getMessage() . "\n" . $e->getFile() . ":" . $e->getLine();
}
