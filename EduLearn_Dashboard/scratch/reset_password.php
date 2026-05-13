<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\Hash;

$email = 'alaQsaSchools1@gmail.com';
$newPass = 'Alaqsa@2026';

$user = User::where('email', $email)->first();
if ($user) {
    $user->update([
        'password' => Hash::make($newPass),
        'is_temp_password' => true,
        'otp_plain' => $newPass
    ]);
    echo "SUCCESS: Password for $email has been reset to $newPass\n";
} else {
    echo "ERROR: User $email not found.\n";
}
