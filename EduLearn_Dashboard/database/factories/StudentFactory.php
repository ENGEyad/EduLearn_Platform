<?php

namespace Database\Factories;

use App\Models\Student;
use Illuminate\Database\Eloquent\Factories\Factory;

class StudentFactory extends Factory
{
    protected $model = Student::class;

    public function definition(): array
    {
        return [
            'full_name' => $this->faker->name(),
            'academic_id' => 'ST' . $this->faker->unique()->numberBetween(10000, 99999),
            'status' => 'Active',
            'grade' => $this->faker->numberBetween(1, 12),
            'class_section' => $this->faker->randomElement(['A', 'B', 'C']),
            'performance_avg' => $this->faker->randomFloat(2, 50, 100),
            'attendance_rate' => $this->faker->randomFloat(2, 70, 100),
        ];
    }
}
