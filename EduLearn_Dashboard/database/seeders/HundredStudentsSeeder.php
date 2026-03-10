<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Student;
use App\Models\ClassSection;
use Illuminate\Support\Facades\Hash;

class HundredStudentsSeeder extends Seeder
{
    public function run(): void
    {
        $class = ClassSection::find(1);
        if (!$class) {
            echo "Class not found!";
            return;
        }

        $names = [
            'احمد', 'محمد', 'علي', 'عمر', 'يوسف', 'ابراهيم', 'خالد', 'سعيد', 'ياسين', 'محمود',
            'سارة', 'ليلى', 'نورا', 'مريم', 'فاطمة', 'زينب', 'هدى', 'امل', 'ريم', 'حنين'
        ];

        $surnames = ['العلي', 'المنصور', 'الحربي', 'العتيبي', 'الشمري', 'القحطاني', 'الزهراني', 'الغامدي', 'الشهري', 'العمري'];

        echo "Generating 100 students for {$class->name}...\n";

        for ($i = 0; $i < 100; $i++) {
            $firstName = $names[array_rand($names)];
            $lastName = $surnames[array_rand($surnames)];
            $fullName = $firstName . ' ' . $lastName;
            $academicId = 'AD' . (1000 + $i + rand(1, 9000));

            Student::create([
                'full_name' => $fullName,
                'academic_id' => $academicId,
                'email' => strtolower($academicId) . '@edulearn.com',
                'password' => Hash::make('password123'),
                'gender' => (in_array($firstName, ['سارة', 'ليلى', 'نورا', 'مريم', 'فاطمة', 'زينب', 'هدى', 'امل', 'ريم', 'حنين']) ? 'Female' : 'Male'),
                'grade' => $class->grade,
                'class_section_id' => $class->id,
                'status' => 'Active',
                'performance_avg' => rand(60, 98),
                'attendance_rate' => rand(70, 100),
            ]);
        }

        echo "Successfully added 100 students.\n";
    }
}
