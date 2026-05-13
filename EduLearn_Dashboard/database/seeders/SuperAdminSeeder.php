<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class SuperAdminSeeder extends Seeder
{
    /**
     * Create the Super Admin user account.
     */
    public function run(): void
    {
        $admin = User::updateOrCreate(
            ['email' => 'admin@edulearn.com'],
            [
                'name'      => 'Super Admin',
                'password'  => Hash::make('password'),
                'role'      => 'super_admin',
                'school_id' => null,
            ]
        );

        $this->command->info("✅ Super Admin created/updated: {$admin->email}");
    }
}
