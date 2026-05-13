<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$user = \App\Models\User::where('role', 'school_admin')->first();
auth()->login($user);

// 1. Report Index
$req1 = Request::create('/reports', 'GET');
$res1 = app()->handle($req1);
echo "REPORTS INDEX STATUS: " . $res1->getStatusCode() . "\n";
if ($res1->getStatusCode() !== 200) {
    echo "ERROR: " . substr($res1->getContent(), 0, 500) . "\n";
}

// 2. Report List
$req2 = Request::create('/reports/list', 'GET');
$req2->headers->set('Accept', 'application/json');
$res2 = app()->handle($req2);
echo "REPORTS LIST STATUS: " . $res2->getStatusCode() . "\n";
if ($res2->getStatusCode() !== 200) {
    echo "ERROR: " . substr($res2->getContent(), 0, 500) . "\n";
} else {
    echo "Output: " . substr($res2->getContent(), 0, 300) . "\n";
}
