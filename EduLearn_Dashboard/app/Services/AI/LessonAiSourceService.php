<?php

namespace App\Services\AI;

use App\Models\Lesson;
use App\Models\LessonAiSource;
use App\Models\Teacher;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

class LessonAiSourceService
{
    public function __construct(
        protected LessonContentExtractionService $extractionService,
    ) {
    }

    public function getActiveSourceForLesson(Lesson $lesson): ?LessonAiSource
    {
        return LessonAiSource::on('app_mysql')
            ->where('lesson_id', $lesson->id)
            ->where('is_active', true)
            ->latest('id')
            ->first();
    }

    public function createOrReplaceActiveSource(
        Lesson $lesson,
        Teacher $teacher,
        ?string $sourceText = null,
        ?UploadedFile $pdfFile = null
    ): LessonAiSource {
        $prepared = $this->extractionService->extractFromInput($sourceText, $pdfFile);

        LessonAiSource::on('app_mysql')
            ->where('lesson_id', $lesson->id)
            ->where('is_active', true)
            ->update(['is_active' => false]);

        $storedFilePath = null;
        if ($pdfFile instanceof UploadedFile) {
            $storedFilePath = $this->storePdfSourceFile($pdfFile);
        }

        $source = new LessonAiSource();
        $source->setConnection('app_mysql');
        $source->lesson_id = $lesson->id;
        $source->teacher_id = $teacher->id;
        $source->source_type = $prepared['source_type'];
        $source->source_file_path = $storedFilePath;
        $source->source_file_name = $prepared['source_file_name'];
        $source->source_text = $prepared['source_text'];
        $source->extracted_text = $prepared['extracted_text'];
        $source->content_hash = sha1($prepared['extracted_text']);
        $source->is_active = true;
        $source->save();

        return $source;
    }

    protected function storePdfSourceFile(UploadedFile $pdfFile): string
    {
        $this->extractionService->assertPdfFile($pdfFile);

        $path = $pdfFile->store('lesson-ai-sources', 'public');
        if (!$path || trim($path) === '') {
            throw new RuntimeException('Failed to store the uploaded AI source PDF.');
        }

        return ltrim((string) $path, '/');
    }
}
