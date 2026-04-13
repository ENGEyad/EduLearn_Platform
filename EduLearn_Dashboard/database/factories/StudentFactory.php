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
            'academic_id' => $this->faker->unique()->numerify('STU####'),
            'grade' => 'Grade ' . $this->faker->numberBetween(1, 12),
            'class_section' => 'Section ' . $this->faker->randomElement(['A', 'B', 'C']),
            'status' => 'Active',
        ];
    }
}
