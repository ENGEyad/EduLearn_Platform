<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$user = \App\Models\User::where('role', 'school_admin')->first();
auth()->login($user);

// 1. Teachers API
$req1 = Request::create('/teachers/list', 'GET');
$res1 = app()->handle($req1);
echo "TEACHERS STATUS: " . $res1->getStatusCode() . "\n";
if ($res1->getStatusCode() !== 200) {
    echo $res1->getContent() . "\n";
}

// 2. Classes API
$req2 = Request::create('/classes/list', 'GET');
$res2 = app()->handle($req2);
echo "CLASSES STATUS: " . $res2->getStatusCode() . "\n";
if ($res2->getStatusCode() !== 200) {
    echo $res2->getContent() . "\n";
}

// 3. Subjects API
$req3 = Request::create('/subjects/list', 'GET');
$res3 = app()->handle($req3);
echo "SUBJECTS STATUS: " . $res3->getStatusCode() . "\n";
if ($res3->getStatusCode() !== 200) {
    echo $res3->getContent() . "\n";
}

// 4. Assignments list API
$req4 = Request::create('/assignments/list', 'GET');
$res4 = app()->handle($req4);
echo "ASSIGNMENTS STATUS: " . $res4->getStatusCode() . "\n";
if ($res4->getStatusCode() !== 200) {
    echo $res4->getContent() . "\n";
}
