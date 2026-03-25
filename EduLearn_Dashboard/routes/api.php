<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\StudentAuthController;
use App\Http\Controllers\Api\TeacherAuthController;
use App\Http\Controllers\Api\LessonController;
use App\Http\Controllers\Api\LessonMediaController;
use App\Http\Controllers\Api\StudentLessonController;
use App\Http\Controllers\Api\ClassModuleController;
use App\Http\Controllers\Api\ChatController;
// use App\Http\Controllers\Api\BroadcastAuthController;

/* |-------------------------------------------------------------------------- | API Routes |-------------------------------------------------------------------------- */

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// ✅ مسار الطالب
Route::post('/student/auth', [StudentAuthController::class , 'auth']);

// ✅ مسار الأستاذ
Route::post('/teacher/auth', [TeacherAuthController::class , 'auth']);

// ==================== Broadcasting Auth (Reverb / Pusher protocol) ====================
// ✅ هذا هو المسار الذي Flutter يستخدمه: /api/broadcasting/auth
// Route::post('/broadcasting/auth', [BroadcastAuthController::class , 'auth']);

// ==================== دروس الأستاذ ====================
Route::post('/teacher/lessons/save', [LessonController::class , 'save']);
Route::get('/teacher/lessons', [LessonController::class , 'index']);

// ملاحظة: أبقيناه كما هو الآن
Route::get('/teacher/lessons/{lesson}', [LessonController::class , 'show']);
Route::delete('/teacher/lessons/{lesson}', [LessonController::class , 'destroy']);

Route::post('/teacher/lessons/bulk-delete', [LessonController::class , 'bulkDelete']);
Route::post('/teacher/lessons/media', [LessonMediaController::class , 'store']);

// ==================== موديولات الفصل (Class Modules) ====================
Route::get('/teacher/class-modules', [ClassModuleController::class , 'index']);
Route::post('/teacher/class-modules', [ClassModuleController::class , 'store']);
Route::put('/teacher/class-modules/{module}', [ClassModuleController::class , 'update']);
Route::delete('/teacher/class-modules/{module}', [ClassModuleController::class , 'destroy']);
Route::get('/teacher/class-modules/{module}/lessons', [ClassModuleController::class , 'lessons']);

// ==================== دروس الطالب ====================
Route::get('/student/lessons', [StudentLessonController::class , 'index']);
Route::get('/student/lessons/{lesson}', [StudentLessonController::class , 'show']);
Route::post('/student/lessons/{lesson}/exercises/check', [StudentLessonController::class , 'checkExercises']);
Route::post('/student/lessons/update-status', [StudentLessonController::class , 'updateStatus']);
Route::post('/student/lessons/{lesson}/progress', [StudentLessonController::class , 'saveProgress']);

// ==================== دردشة الأستاذ / الطالب ====================
Route::group(['prefix' => 'chat'], function () {

    // فتح / إنشاء محادثة بين أستاذ وطالب
    Route::post('/conversations/open', [ChatController::class , 'openConversation']);

    // فتح / إنشاء محادثة جماعية للفصل
    Route::post('/conversations/open-group', [ChatController::class , 'openGroupConversation']);

    // قائمة محادثات الأستاذ
    Route::get('/conversations/teacher', [ChatController::class , 'teacherConversations']);

    // قائمة محادثات الطالب
    Route::get('/conversations/student', [ChatController::class , 'studentConversations']);

    // رسائل محادثة معيّنة
    Route::get('/conversations/{conversation}/messages', [ChatController::class , 'messages']);

    // إرسال رسالة في محادثة معيّنة
    Route::post('/conversations/{conversation}/messages', [ChatController::class , 'sendMessage']);

    // ✅ (اختياري للتوافق) إذا كان عندك أي جزء قديم يستخدم /api/chat/broadcasting/auth
    // Route::post('/broadcasting/auth', [BroadcastAuthController::class , 'auth']);
});
