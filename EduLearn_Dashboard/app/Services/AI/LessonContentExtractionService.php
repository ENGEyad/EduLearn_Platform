<?php

namespace App\Services\AI;

use Illuminate\Http\UploadedFile;
use RuntimeException;

class LessonContentExtractionService
{
    /**
     * Extract normalized text from either direct text input or a PDF upload.
     */
    public function extractFromInput(?string $sourceText = null, ?UploadedFile $pdfFile = null): array
    {
        $text = trim((string) $sourceText);

        if ($text !== '') {
            return [
                'source_type' => 'text',
                'source_text' => $text,
                'source_file_name' => null,
                'extracted_text' => $this->normalizeText($text),
            ];
        }

        if ($pdfFile instanceof UploadedFile) {
            $this->assertPdfFile($pdfFile);

            return [
                'source_type' => 'pdf',
                'source_text' => null,
                'source_file_name' => $pdfFile->getClientOriginalName(),
                'extracted_text' => $this->extractPdfText($pdfFile),
            ];
        }

        throw new RuntimeException('Either source_text or a PDF file is required.');
    }

    public function assertPdfFile(UploadedFile $pdfFile): void
    {
        $ext = strtolower((string) $pdfFile->getClientOriginalExtension());
        $mime = strtolower((string) $pdfFile->getClientMimeType());

        if ($ext !== 'pdf' && $mime !== 'application/pdf') {
            throw new RuntimeException('Only PDF files are supported for AI lesson source uploads.');
        }
    }

    public function normalizeText(string $text): string
    {
        $text = str_replace(["\r\n", "\r"], "\n", $text);
        $text = preg_replace("/[\t ]+/u", ' ', $text) ?? $text;
        $text = preg_replace("/\n{3,}/u", "\n\n", $text) ?? $text;
        $text = trim($text);

        if ($text === '') {
            throw new RuntimeException('The extracted source text is empty.');
        }

        return $text;
    }

    protected function extractPdfText(UploadedFile $pdfFile): string
    {
        if (!class_exists(\Smalot\PdfParser\Parser::class)) {
            throw new RuntimeException(
                'PDF parsing package is not installed. Install smalot/pdfparser to extract PDF text.'
            );
        }

        try {
            $parser = new \Smalot\PdfParser\Parser();
            $pdf = $parser->parseFile($pdfFile->getRealPath());
            $text = $pdf->getText();
        } catch (\Throwable $e) {
            throw new RuntimeException('Failed to extract text from PDF: ' . $e->getMessage());
        }

        return $this->normalizeText($text);
    }
}
