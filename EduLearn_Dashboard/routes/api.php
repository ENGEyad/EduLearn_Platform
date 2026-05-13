<?php

use App\Http\Controllers\Api\TeacherLessonExerciseController;
use App\Http\Controllers\Api\StudentLessonExerciseController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\StudentAuthController;
use App\Http\Controllers\Api\TeacherAuthController;
use App\Http\Controllers\Api\LessonController;
use App\Http\Controllers\Api\LessonMediaController;
use App\Http\Controllers\Api\StudentLessonController;
use App\Http\Controllers\Api\ClassModuleController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\BroadcastAuthController;
use App\Http\Controllers\Api\LearningActivityController;
use App\Http\Controllers\Api\LessonAiController;
use App\Http\Controllers\Api\StudentDataController;
use App\Http\Controllers\Api\StudentProgressController;
use App\Http\Controllers\Api\TeacherDataController;
use App\Http\Controllers\Api\TeacherProgressController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// ==================== إعدادات المنصة العامة (Platform Settings) ====================
Route::get('/settings', [\App\Http\Controllers\Api\SettingController::class, 'index']);


// ==================== مصادقة الطالب / الأستاذ ====================
Route::post('/student/auth', [StudentAuthController::class, 'auth']);
Route::post('/teacher/auth', [TeacherAuthController::class, 'auth']);

// ==================== Broadcasting Auth (Reverb / Pusher protocol) ====================
Route::post('/broadcasting/auth', [BroadcastAuthController::class , 'auth']);

// ==================== دروس الأستاذ ====================
Route::post('/teacher/lessons/save', [LessonController::class, 'save']);
Route::get('/teacher/lessons', [LessonController::class, 'index']);
Route::get('/teacher/lessons/{lesson}', [LessonController::class, 'show']);
Route::delete('/teacher/lessons/{lesson}', [LessonController::class, 'destroy']);
Route::post('/teacher/lessons/bulk-delete', [LessonController::class, 'bulkDelete']);
Route::post('/teacher/lessons/media', [LessonMediaController::class, 'store']);

// ==================== موديولات الفصل ====================
Route::get('/teacher/class-modules', [ClassModuleController::class, 'index']);
Route::post('/teacher/class-modules', [ClassModuleController::class, 'store']);
Route::put('/teacher/class-modules/{module}', [ClassModuleController::class, 'update']);
Route::delete('/teacher/class-modules/{module}', [ClassModuleController::class, 'destroy']);
Route::get('/teacher/class-modules/{module}/lessons', [ClassModuleController::class, 'lessons']);

// ==================== دروس الطالب ====================
Route::get('/student/lessons', [StudentLessonController::class , 'index']);
Route::get('/student/lessons/{lesson}', [StudentLessonController::class , 'show']);
Route::post('/student/lessons/update-status', [StudentLessonController::class , 'updateStatus']);
Route::post('/student/lessons/{lesson}/progress', [StudentLessonController::class , 'saveProgress']);

// ==================== تمارين الأستاذ ====================
Route::prefix('teacher/lessons/{lesson}/exercise-set')->group(function () {
    Route::get('/draft', [TeacherLessonExerciseController::class, 'showDraft']);
    Route::post('/save-draft', [TeacherLessonExerciseController::class, 'saveDraft']);
    Route::post('/publish', [TeacherLessonExerciseController::class, 'publish']);
    Route::post('/archive', [TeacherLessonExerciseController::class, 'archiveSet']);
    Route::post('/unarchive', [TeacherLessonExerciseController::class, 'unarchiveSet']);

    Route::delete('/questions/{stableQuestionKey}', [TeacherLessonExerciseController::class, 'deleteDraftQuestion']);
    Route::post('/questions/{stableQuestionKey}/restore', [TeacherLessonExerciseController::class, 'restoreDraftQuestion']);
    Route::post('/questions/{stableQuestionKey}/archive', [TeacherLessonExerciseController::class, 'archiveDraftQuestion']);
    Route::post('/questions/{stableQuestionKey}/unarchive', [TeacherLessonExerciseController::class, 'unarchiveDraftQuestion']);
});

// ==================== تمارين الطالب ====================
Route::prefix('student/lessons/{lesson}/exercise-set')->group(function () {
    Route::get('/current', [StudentLessonExerciseController::class, 'current']);
    Route::get('/latest-attempt', [StudentLessonExerciseController::class, 'latestAttempt']);
    Route::post('/save', [StudentLessonExerciseController::class, 'save']);
    Route::post('/submit', [StudentLessonExerciseController::class, 'submit']);
});

// ==================== الدردشة ====================
Route::prefix('chat')->group(function () {
    Route::post('/conversations/open', [ChatController::class, 'openConversation']);
    Route::post('/conversations/open-group', [ChatController::class, 'openGroupConversation']);

    Route::get('/conversations/teacher', [ChatController::class, 'teacherConversations']);
    Route::get('/conversations/student', [ChatController::class, 'studentConversations']);

    Route::get('/conversations/{conversation}/messages', [ChatController::class, 'messages']);
    Route::post('/conversations/{conversation}/messages', [ChatController::class, 'sendMessage']);

    Route::post('/broadcasting/auth', [BroadcastAuthController::class , 'auth']);
});

// ==================== ميزات الذكاء الاصطناعي العامة ====================
Route::post('/ai/generate-notification', [\App\Http\Controllers\Api\AiController::class, 'generateNotificationContent']);

// ==================== الميزات المتقدمة المحمية (Auth Required) ====================
Route::middleware('auth:sanctum')->group(function () {
    
    // سجل الأنشطة (Activity Feed)
    Route::get('/teacher/activities', [LearningActivityController::class, 'teacherActivities']);
    Route::post('/teacher/activities/mark-read', [LearningActivityController::class, 'markTeacherActivitiesRead']);
    Route::get('/student/activities', [LearningActivityController::class, 'studentActivities']);
    Route::post('/student/activities/mark-read', [LearningActivityController::class, 'markStudentActivitiesRead']);

    // بيانات الطالب (Student Data)
    Route::get('/student/subjects', [StudentDataController::class, 'subjects']);
    Route::get('/student/teachers', [StudentDataController::class, 'teachers']);

    // تقدم الطالب (Student Progress)
    Route::get('/student/progress/overview', [StudentProgressController::class, 'overview']);
    Route::get('/student/subjects/{subject}/progress', [StudentProgressController::class, 'subject']);

    // بيانات الأستاذ (Teacher Data)
    Route::get('/teacher/assignments-summary', [TeacherDataController::class, 'assignmentsSummary']);
    Route::get('/teacher/assignment/{assignment}/students', [TeacherDataController::class, 'assignmentStudents']);

    // تقدم الأستاذ (Teacher Progress)
    Route::get('/teacher/progress/summary', [TeacherProgressController::class, 'summary']);
    Route::get('/teacher/progress/class-subject', [TeacherProgressController::class, 'classSubject']);
    Route::get('/teacher/progress/student-subject', [TeacherProgressController::class, 'studentSubject']);

    // ==================== دروس الذكاء الاصطناعي (AI Lessons) ====================
    Route::prefix('teacher/lessons/ai')->group(function () {
        Route::post('/generate-blocks', [LessonAiController::class, 'generateBlocks']);
        Route::post('/rewrite-block', [LessonAiController::class, 'rewriteBlock']);
        Route::get('/source/{lesson}', [LessonAiController::class, 'getActiveSource']);
        Route::post('/source/{lesson}/replace', [LessonAiController::class, 'replaceSource']);
    });
});
