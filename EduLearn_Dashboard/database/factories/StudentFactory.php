<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Student>
 */
class StudentFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
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
