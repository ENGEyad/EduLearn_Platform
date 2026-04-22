<?php

namespace Database\Factories;

use App\Models\ClassSection;
use Illuminate\Database\Eloquent\Factories\Factory;

class ClassSectionFactory extends Factory
{
    protected $model = ClassSection::class;

    public function definition(): array
    {
        return [
            'grade' => $this->faker->numberBetween(1, 12),
            'section' => $this->faker->randomElement(['A', 'B', 'C']),
            'name' => $this->faker->word,
            'stage' => 'primary',
            'is_active' => true,
        ];
    }
}
