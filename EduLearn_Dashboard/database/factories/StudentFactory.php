<?php

namespace Database\Factories;

use App\Models\Student;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class StudentFactory extends Factory
{
    protected $model = Student::class;

    public function definition(): array
    {
        return [
            'full_name' => $this->faker->name(),
            'academic_id' => 'S-' . Str::random(8),
            'gender' => $this->faker->randomElement(['Male', 'Female']),
            'status' => 'Active',
            'grade' => 'Grade 1',
            'class_section' => 'A',
            'email' => $this->faker->unique()->safeEmail(),
        ];
    }
}
