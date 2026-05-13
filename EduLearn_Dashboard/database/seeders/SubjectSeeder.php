<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Subject;

class SubjectSeeder extends Seeder
{
    /**
     * Seed all subjects with bilingual names (EN/AR) and codes.
     *
     * Subject categories per the requirements:
     * - Primary (1-9): Arabic, Islamic Education, Math, Science, Social Studies, English, Quran
     * - Grade 10 (Common): Arabic, Islamic Education, English, Math, Physics, Chemistry, Biology,
     *                       History, Geography, National Education, Quran
     * - Scientific (11-12): Arabic, Islamic Education, English, Math, Physics, Chemistry, Biology, Quran
     * - Literary (11-12): Arabic, Islamic Education, English, History, Geography,
     *                      Philosophy/Psychology, Sociology, Quran
     */
    public function run(): void
    {
        $subjects = [
            ['code' => 'arabic',           'name_en' => 'Arabic',                  'name_ar' => 'اللغة العربية'],
            ['code' => 'islamic_edu',      'name_en' => 'Islamic Education',       'name_ar' => 'التربية الإسلامية'],
            ['code' => 'math',             'name_en' => 'Mathematics',             'name_ar' => 'الرياضيات'],
            ['code' => 'science',          'name_en' => 'Science',                 'name_ar' => 'العلوم'],
            ['code' => 'social_studies',   'name_en' => 'Social Studies',          'name_ar' => 'الدراسات الاجتماعية'],
            ['code' => 'english',          'name_en' => 'English',                 'name_ar' => 'اللغة الإنجليزية'],
            ['code' => 'quran',            'name_en' => 'Quran',                   'name_ar' => 'القرآن الكريم'],
            ['code' => 'physics',          'name_en' => 'Physics',                 'name_ar' => 'الفيزياء'],
            ['code' => 'chemistry',        'name_en' => 'Chemistry',               'name_ar' => 'الكيمياء'],
            ['code' => 'biology',          'name_en' => 'Biology',                 'name_ar' => 'الأحياء'],
            ['code' => 'history',          'name_en' => 'History',                 'name_ar' => 'التاريخ'],
            ['code' => 'geography',        'name_en' => 'Geography',               'name_ar' => 'الجغرافيا'],
            ['code' => 'national_edu',     'name_en' => 'National Education',      'name_ar' => 'التربية الوطنية'],
            ['code' => 'philosophy',       'name_en' => 'Philosophy & Psychology',  'name_ar' => 'الفلسفة وعلم النفس'],
            ['code' => 'sociology',        'name_en' => 'Sociology',               'name_ar' => 'علم الاجتماع'],
        ];

        foreach ($subjects as $subject) {
            Subject::updateOrCreate(
                ['code' => $subject['code']],
                [
                    'name_en'   => $subject['name_en'],
                    'name_ar'   => $subject['name_ar'],
                    'is_active' => true,
                ]
            );
        }

        $this->command->info('✅ Seeded ' . count($subjects) . ' subjects with bilingual names.');
    }
}
