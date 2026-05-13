<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class LessonMediaController extends Controller
{
    /**
     * ============================================================
     * ✅ رفع ميديا الدرس (Image/Video/Audio/Voice)
     * POST /api/teacher/lessons/media
     *
     * ✅ يرجّع دائماً:
     * - media_path: مسار نظيف للتخزين في DB (lessons/xxx.ext)
     * - media_url : رابط كامل صالح للاستخدام الفوري في Flutter Preview
     * - media_mime, media_size
     *
     * ملاحظة مهمة:
     * - "مصدر الحقيقة" للتخزين داخل DB هو media_path فقط.
     * - media_url يُستخدم للعرض الفوري (Preview) بعد الرفع.
     * ============================================================
     */
    public function store(Request $request)
    {
        // ✅ Validation (50MB)
        $request->validate([
            'file' => 'required|file|max:51200|mimes:jpg,jpeg,png,mp4,mp3,wav,m4a,pdf', // 50MB
        ]);

        $file = $request->file('file');

        // ✅ حفظ ثابت داخل public disk: storage/app/public/lessons/...
        $path = $file->store('lessons', 'public');

        // ✅ ضمان الشكل lessons/xxx.ext
        $path = ltrim((string) $path, '/');
        if ($path === '' || !Str::startsWith($path, 'lessons/')) {
            $path = 'lessons/' . basename((string) $path);
        }

        // ✅ توليد رابط كامل من نفس Host الذي وصل منه الطلب
        // هذا يحل مشكلة localhost على الجوال + يحل اختلاف IP/Port
        $base = $request->getSchemeAndHttpHost(); // مثال: http://192.168.1.10:8000
        $url  = $base . '/storage/' . ltrim($path, '/');

        return response()->json([
            'success'    => true,
            'media_path' => $path,                 // lessons/abc.mp4
            'media_url'  => $url,                  // http://<host>/storage/lessons/abc.mp4
            'media_mime' => $file->getClientMimeType(),
            'media_size' => $file->getSize(),      // bytes
        ]);
    }
}