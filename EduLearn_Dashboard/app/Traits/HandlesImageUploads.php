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
        $hasGd = extension_loaded('gd');
        $hasImagick = extension_loaded('imagick');

        if (!$hasGd && !$hasImagick) {
            // Fallback: Just store the raw file if no library is available
            return $file->store($folder, 'public');
        }

        try {
            if ($hasGd) {
                $manager = new \Intervention\Image\ImageManager(new \Intervention\Image\Drivers\Gd\Driver());
            } else {
                $manager = new \Intervention\Image\ImageManager(new \Intervention\Image\Drivers\Imagick\Driver());
            }

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
        } catch (\Exception $e) {
            // If anything fails during processing, fallback to raw storage
            return $file->store($folder, 'public');
        }
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

    /**
     * Optimise an image and return its binary content (useful for DB storage).
     *
     * @param  UploadedFile $file
     * @param  int          $maxWidth
     * @param  int          $quality
     * @return array        ['data' => binary, 'mime' => 'image/webp']
     */
    protected function optimizeToBinary(\Illuminate\Http\UploadedFile $file, int $maxWidth = 400, int $quality = 70): array
    {
        $hasGd = extension_loaded('gd');
        $hasImagick = extension_loaded('imagick');

        if (!$hasGd && !$hasImagick) {
            return [
                'data' => file_get_contents($file->getRealPath()),
                'mime' => $file->getMimeType()
            ];
        }

        try {
            if ($hasGd) {
                $manager = new \Intervention\Image\ImageManager(new \Intervention\Image\Drivers\Gd\Driver());
            } else {
                $manager = new \Intervention\Image\ImageManager(new \Intervention\Image\Drivers\Imagick\Driver());
            }

            $image = $manager->read($file->getPathname());
            $image = $image->scaleDown(width: $maxWidth);
            $encoded = $image->toWebp($quality);

            return [
                'data' => (string) $encoded,
                'mime' => 'image/webp'
            ];
        } catch (\Exception $e) {
            return [
                'data' => file_get_contents($file->getRealPath()),
                'mime' => $file->getMimeType()
            ];
        }
    }
}
