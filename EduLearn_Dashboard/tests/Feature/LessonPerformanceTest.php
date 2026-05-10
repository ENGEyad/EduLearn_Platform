<?php

namespace Tests\Feature;

use App\Models\Teacher;
use App\Models\Subject;
use App\Models\ClassSection;
use App\Models\TeacherClassSubject;
use App\Models\ClassModule;
use App\Models\Lesson;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;
use Illuminate\Support\Facades\Artisan;

class LessonPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected array $connectionsToTransact = ['mysql', 'app_mysql'];

    protected function refreshTestDatabase()
    {
        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => ':memory:']);
        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);

        Artisan::call('migrate:fresh', [
            '--force' => true,
        ]);

        $this->app[ \Illuminate\Contracts\Console\Kernel::class]->setArtisan(null);
    }

    public function test_save_lesson_performance_baseline()
    {
        $teacher = Teacher::create([
            'full_name' => 'Test Teacher',
            'teacher_code' => 'T100',
            'status' => 'active',
        ]);

        $subject = Subject::create([
            'name_en' => 'Math',
            'code' => 'MATH101'
        ]);

        $classSection = ClassSection::create([
            'grade' => '1',
            'section' => 'A',
            'name' => 'Grade 1 - A'
        ]);

        $assignment = TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'subject_id' => $subject->id,
            'class_section_id' => $classSection->id,
        ]);

        $classModule = ClassModule::create([
            'title' => 'Module 1',
            'teacher_id' => $teacher->id,
            'assignment_id' => $assignment->id,
            'subject_id' => $subject->id,
            'class_section_id' => $classSection->id,
        ]);

        $blocks = [];
        for ($i = 1; $i <= 10; $i++) {
            $blocks[] = [
                'type' => 'text',
                'body' => "Block content $i",
                'position' => $i,
            ];
        }

        $exercises = [];
        for ($i = 1; $i <= 5; $i++) {
            $exercises[] = [
                'type' => 'mcq',
                'question_text' => "Question $i",
                'options' => [
                    ['text' => 'Option 1', 'is_correct' => true],
                    ['text' => 'Option 2', 'is_correct' => false],
                    ['text' => 'Option 3', 'is_correct' => false],
                    ['text' => 'Option 4', 'is_correct' => false],
                ]
            ];
        }

        $payload = [
            'teacher_code' => 'T100',
            'assignment_id' => $assignment->id,
            'class_module_id' => $classModule->id,
            'class_section_id' => $classSection->id,
            'subject_id' => $subject->id,
            'title' => 'Performance Test Lesson',
            'status' => 'draft',
            'blocks' => $blocks,
            'exercises' => $exercises,
        ];

        $queryCount = 0;
        DB::connection('app_mysql')->listen(function ($query) use (&$queryCount) {
            if (preg_match('/^(insert|update|delete)/i', $query->sql)) {
                $queryCount++;
            }
        });

        $response = $this->postJson('/api/teacher/lessons/save', $payload);

        if ($response->status() !== 200) {
            echo "\nError Response: " . $response->getContent() . "\n";
        }
        $response->assertStatus(200);

        echo "\nQueries for saving lesson: $queryCount\n";
    }

    public function test_bulk_delete_performance_baseline()
    {
        $teacher = Teacher::create([
            'full_name' => 'Test Teacher',
            'teacher_code' => 'T100',
            'status' => 'active',
        ]);

        $lessonIds = [];
        for ($i = 0; $i < 5; $i++) {
            $lesson = Lesson::create([
                'teacher_id' => $teacher->id,
                'assignment_id' => 1,
                'class_module_id' => 1,
                'class_section_id' => 1,
                'subject_id' => 1,
                'title' => "Lesson $i",
                'status' => 'draft',
            ]);
            $lessonIds[] = $lesson->id;

            // Add some blocks
            for ($j = 0; $j < 3; $j++) {
                $lesson->blocks()->create([
                    'type' => 'text',
                    'body' => "Block $j",
                    'position' => $j
                ]);
            }
        }

        $queryCount = 0;
        DB::connection('app_mysql')->listen(function ($query) use (&$queryCount) {
            if (preg_match('/^(delete)/i', $query->sql)) {
                $queryCount++;
            }
        });

        $response = $this->postJson('/api/teacher/lessons/bulk-delete', [
            'teacher_code' => 'T100',
            'lesson_ids' => $lessonIds
        ]);

        $response->assertStatus(200);

        echo "\nQueries for bulk delete: $queryCount\n";
    }
}
