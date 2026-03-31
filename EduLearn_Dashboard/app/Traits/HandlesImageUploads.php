<?php

namespace App\Traits;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Intervention\Image\ImageManager;

/**
 * High-performance image handling trait.
 *
 * - Resizes large images to a sensible max width (default 1200px)
 * - Generates a smaller thumbnail (default 300px)
 * - Converts everything to WebP for ~30-50 % smaller files
 * - Cleans up old images when replaced
 */
trait HandlesImageUploads
{
    /**
     * Upload, optimise and store an image.
     *
     * @param  UploadedFile  $file     The uploaded file from the request.
     * @param  string        $folder   Storage sub-folder, e.g. "students" or "schools/logos".
     * @param  int           $maxWidth Maximum width for the full-size image (height scales proportionally).
     * @param  int           $quality  WebP quality 1-100 (75 is a good balance).
     * @param  int           $thumbWidth Width of the auto-generated thumbnail.
     * @return string        The relative storage path of the full-size WebP image.
     */
    protected function uploadAndOptimize(
        UploadedFile $file,
        string $folder = 'images',
        int $maxWidth = 1200,
        int $quality = 75,
        int $thumbWidth = 300,
    ): string {
        $manager = ImageManager::gd();

        // Read the uploaded file into Intervention
        $image = $manager->read($file->getPathname());

        // Scale down only if larger than maxWidth (never scale up)
        $image = $image->scaleDown(width: $maxWidth);

        // Generate a unique filename with .webp extension
        $filename = uniqid() . '_' . time() . '.webp';
        $fullPath = $folder . '/' . $filename;
        $thumbPath = $folder . '/thumbs/' . $filename;

        // Encode to WebP
        $encoded = $image->toWebp($quality);

        // Store the full-size image
        Storage::disk('public')->put($fullPath, (string) $encoded);

        // Generate and store thumbnail
        $thumb = $manager->read($file->getPathname())
            ->scaleDown(width: $thumbWidth)
            ->toWebp($quality);

        Storage::disk('public')->put($thumbPath, (string) $thumb);

        return $fullPath;
    }

    /**
     * Delete an image and its thumbnail from storage.
     *
     * @param  string|null  $path  The relative path stored in the database.
     */
    protected function deletePreviousImage(?string $path): void
    {
        if (!$path) {
            return;
        }

        Storage::disk('public')->delete($path);

        // Also delete the thumbnail if it exists
        $thumbPath = $this->getThumbnailPath($path);
        if ($thumbPath) {
            Storage::disk('public')->delete($thumbPath);
        }
    }

    /**
     * Get the thumbnail path for a given image path.
     * e.g. "students/abc123.webp" → "students/thumbs/abc123.webp"
     */
    protected function getThumbnailPath(?string $path): ?string
    {
        if (!$path) {
            return null;
        }

        $dir = dirname($path);
        $file = basename($path);

        return $dir . '/thumbs/' . $file;
    }
}
