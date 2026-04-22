<?php

namespace Database\Factories;

use App\Models\Teacher;
use Illuminate\Database\Eloquent\Factories\Factory;

class TeacherFactory extends Factory
{
    protected $model = Teacher::class;

    public function definition(): array
    {
        return [
            'full_name' => $this->faker->name,
            'teacher_code' => 'T-' . $this->faker->unique()->numberBetween(1000, 9999),
            'email' => $this->faker->unique()->safeEmail,
            'phone' => $this->faker->phoneNumber,
            'status' => 'active',
        ];
    }
}
