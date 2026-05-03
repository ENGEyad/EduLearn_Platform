<?php

namespace Database\Factories;

use App\Models\Student;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Student>
 */
class StudentFactory extends Factory
{
    protected $model = Student::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'full_name' => $this->faker->name(),
            'academic_id' => 'S-' . now()->year . '-' . strtoupper(Str::random(4)),
            'gender' => $this->faker->randomElement(['Male', 'Female']),
            'status' => 'Active',
            'grade' => 'Grade 1',
            'class_section' => 'A',
        ];
    }
}
