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
            'academic_id' => 'S-' . $this->faker->unique()->numberBetween(1000, 9999),
            'status' => 'Active',
            'grade' => 'Grade ' . $this->faker->numberBetween(1, 12),
            'class_section' => $this->faker->randomElement(['A', 'B', 'C']),
        ];
    }
}
