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
            'academic_id' => 'S-' . $this->faker->unique()->randomNumber(5),
            'gender' => $this->faker->randomElement(['Male', 'Female']),
            'status' => 'Active',
            'performance_avg' => $this->faker->randomFloat(2, 50, 100),
            'attendance_rate' => $this->faker->randomFloat(2, 70, 100),
        ];
    }
}
