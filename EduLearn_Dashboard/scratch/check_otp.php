<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "Users with active OTPs:\n";
$users = App\Models\User::whereNotNull('otp_plain')->get();
if ($users->count() > 0) {
    foreach ($users as $user) {
        echo "- " . $user->email . " : " . $user->otp_plain . "\n";
    }
} else {
    echo "No active OTPs found in the database.\n";
}

echo "\nChecking specific user: alaQsaSchools1@gmail.com\n";
$user = App\Models\User::where('email', 'alaQsaSchools1@gmail.com')->first();
if ($user) {
    echo "User exists. Role: " . $user->role . "\n";
    echo "Is Temp Password: " . ($user->is_temp_password ? "Yes" : "No") . "\n";
    echo "OTP Plain: " . ($user->otp_plain ?: "NULL") . "\n";
} else {
    echo "User not found.\n";
}
