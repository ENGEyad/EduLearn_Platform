<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\StudentController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\TeacherController;
use App\Http\Controllers\Api\AiController;
use App\Http\Controllers\ReportsController;
use App\Http\Controllers\SubjectController;
use App\Http\Controllers\ClassSectionController;
use App\Http\Controllers\ClassSectionSubjectController;
use App\Http\Controllers\TeacherClassSubjectController;
use App\Http\Controllers\SchoolRegistrationController;
use App\Http\Controllers\SuperAdminController;
use App\Http\Controllers\SuperAdmin\GlobalSubjectController;
use App\Http\Controllers\SuperAdmin\AnalyticsController;
use App\Http\Controllers\SuperAdmin\SystemNotificationController;
use App\Http\Controllers\SuperAdmin\SupportController;
use App\Http\Controllers\SuperAdmin\SettingController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\ForgotPasswordController;
use App\Http\Controllers\Auth\ResetPasswordController;
use App\Http\Controllers\Auth\ForcePasswordChangeController;
use App\Http\Controllers\BranchController;
use App\Http\Controllers\LocaleController;

// Locale Switching
Route::get('/lang/{lang}', [LocaleController::class, 'switchLocale'])->name('locale.switch');

// الهوم -> توجيه لصفحة التسجيل أو الداشبورد بناءً على التوكن
// Landing Page → the gateway for new and existing users
Route::get('/', function (\Illuminate\Http\Request $request) {
    if (auth()->check()) {
        return redirect()->route('dashboard');
    }
    
    return view('welcome');
});

// Auth Routes
Route::get('/login', [LoginController::class, 'showLoginForm'])->name('login');
Route::post('/login', [LoginController::class, 'login'])->name('login.post');
Route::post('/logout', [LoginController::class, 'logout'])->name('logout');

// Password Reset Routes
Route::get('password/reset', [ForgotPasswordController::class, 'showLinkRequestForm'])->name('password.request');
Route::post('password/email', [ForgotPasswordController::class, 'sendResetLinkEmail'])->name('password.email');
Route::get('password/reset/{token}', [ResetPasswordController::class, 'showResetForm'])->name('password.reset');
Route::post('password/reset', [ResetPasswordController::class, 'reset'])->name('password.update');

// Forced Password Change (For Branch Admins or anyone with temp password)
Route::middleware(['auth'])->group(function () {
    Route::get('/auth/force-password-change', [ForcePasswordChangeController::class, 'show'])->name('auth.force-password-change.show');
    Route::post('/auth/force-password-change', [ForcePasswordChangeController::class, 'update'])->name('auth.force-password-change.update');
});

Route::get('/dashboard', [DashboardController::class , 'index'])->middleware(['auth', 'school.active'])->name('dashboard');
Route::get('/api/dashboard/ai-insight', [DashboardController::class , 'getAiInsight'])->middleware(['auth', 'school.active'])->name('api.dashboard.ai-insight');

// AI Features
Route::group(['prefix' => 'api/ai'], function () {
    Route::post('/generate-exercises', [AiController::class , 'generateExercises']);
    Route::post('/daily-report', [AiController::class , 'generateDailyReport']);
    Route::post('/submit-response', [AiController::class , 'submitResponse']);
    Route::post('/adaptive-exercises', [AiController::class , 'getAdaptiveExercises']);
});

// Exports
Route::group(['prefix' => 'exports', 'middleware' => ['auth', 'school.active']], function () {
    Route::get('/students/csv', [\App\Http\Controllers\ExportController::class, 'exportStudentsCsv'])->name('exports.students.csv');
    Route::get('/students/pdf', [\App\Http\Controllers\ExportController::class, 'exportStudentsPdf'])->name('exports.students.pdf');
    Route::get('/teachers/csv', [\App\Http\Controllers\ExportController::class, 'exportTeachersCsv'])->name('exports.teachers.csv');
    Route::get('/teachers/pdf', [\App\Http\Controllers\ExportController::class, 'exportTeachersPdf'])->name('exports.teachers.pdf');
});

// Management Area (Students, Teachers, Classes)
Route::middleware(['auth', 'school.active'])->group(function () {
    // students
    Route::get('/students', [StudentController::class , 'index'])->middleware('branch.can:manage_students')->name('students.index');
    Route::get('/students/list', [StudentController::class , 'list'])->middleware('branch.can:manage_students')->name('students.list');
    Route::post('/students/import', [StudentController::class , 'import'])->middleware('branch.can:manage_students')->name('students.import');
    Route::post('/students', [StudentController::class , 'store'])->middleware('branch.can:manage_students')->name('students.store');
    Route::put('/students/{student}', [StudentController::class , 'update'])->middleware('branch.can:manage_students')->name('students.update');
    Route::delete('/students/{student}', [StudentController::class , 'destroy'])->middleware('branch.can:manage_students')->name('students.destroy');
    Route::get('/students/{student}/performance', [\App\Http\Controllers\StudentPerformanceController::class, 'show'])->middleware('branch.can:view_reports')->name('students.performance');
    Route::get('/students/{student}/photo', [StudentController::class , 'showPhoto'])->name('students.photo');

    // teachers
    Route::get('/teachers', [TeacherController::class , 'index'])->middleware('branch.can:manage_teachers')->name('teachers.index');
    Route::get('/teachers/list', [TeacherController::class , 'list'])->middleware('branch.can:manage_teachers')->name('teachers.list');
    Route::post('/teachers', [TeacherController::class , 'store'])->middleware('branch.can:manage_teachers')->name('teachers.store');
    Route::put('/teachers/{teacher}', [TeacherController::class , 'update'])->middleware('branch.can:manage_teachers')->name('teachers.update');
    Route::delete('/teachers/{teacher}', [TeacherController::class , 'destroy'])->middleware('branch.can:manage_teachers')->name('teachers.destroy');
    Route::post('/teachers/import', [TeacherController::class , 'import'])->middleware('branch.can:manage_teachers')->name('teachers.import');

    // classes (ClassSections)
    Route::get('/classes', [ClassSectionController::class , 'index'])->middleware('branch.can:manage_classes')->name('classes.index');
    Route::get('/classes/list', [ClassSectionController::class , 'list'])->middleware('branch.can:manage_classes')->name('classes.list');
    Route::post('/classes', [ClassSectionController::class , 'store'])->middleware('branch.can:manage_classes')->name('classes.store');
    Route::put('/classes/{class_section}', [ClassSectionController::class , 'update'])->middleware('branch.can:manage_classes')->name('classes.update');
    Route::delete('/classes/{class_section}', [ClassSectionController::class , 'destroy'])->middleware('branch.can:manage_classes')->name('classes.destroy');
    Route::post('/classes/import', [ClassSectionController::class , 'import'])->middleware('branch.can:manage_classes')->name('classes.import');
});

// subjects (CRUD for school admins and super admins)
Route::middleware(['auth', 'school.active'])->group(function () {
    Route::get('/subjects', [SubjectController::class , 'index'])->middleware('branch.can:manage_subjects')->name('subjects.index');
    Route::get('/subjects/list', [SubjectController::class , 'list'])->middleware('branch.can:manage_subjects')->name('subjects.list');
    Route::post('/subjects', [SubjectController::class , 'store'])->middleware('branch.can:manage_subjects')->name('subjects.store');
    Route::put('/subjects/{subject}', [SubjectController::class , 'update'])->middleware('branch.can:manage_subjects')->name('subjects.update');
    Route::delete('/subjects/{subject}', [SubjectController::class , 'destroy'])->middleware('branch.can:manage_subjects')->name('subjects.destroy');
    Route::get('/subjects/{subject}/content', [SubjectController::class , 'content'])->middleware('branch.can:manage_subjects')->name('subjects.content');
});

// assignments
Route::middleware(['auth', 'school.active'])->group(function () {
    Route::get('/assignments', [\App\Http\Controllers\TeacherClassSubjectController::class , 'index'])->name('assignments.index');
    Route::get('/assignments/list', [\App\Http\Controllers\TeacherClassSubjectController::class , 'list'])->name('assignments.list');
    Route::post('/assignments', [\App\Http\Controllers\TeacherClassSubjectController::class , 'store'])->name('assignments.store');
    Route::put('/assignments/{assignment}', [\App\Http\Controllers\TeacherClassSubjectController::class , 'update'])->name('assignments.update');
    Route::delete('/assignments/{assignment}', [\App\Http\Controllers\TeacherClassSubjectController::class , 'destroy'])->name('assignments.destroy');
    Route::post('/assignments/import', [\App\Http\Controllers\TeacherClassSubjectController::class , 'import'])->name('assignments.import');
});

// صفحات ثابتة مؤقتة (attendance فقط الآن)
Route::view('/attendance', 'placeholder', [
    'pageTitle' => 'Attendance',
    'pageSubtitle' => 'Track attendance from mobile app'
])->name('attendance.index');

// Reports
Route::middleware(['auth', 'school.active'])->group(function () {
    Route::get('/reports', [ReportsController::class , 'index'])->middleware('branch.can:view_reports')->name('reports.index');
    Route::get('/reports/list', [ReportsController::class , 'list'])->middleware('branch.can:view_reports')->name('reports.list');
    Route::get('/reports/at-risk', [ReportsController::class , 'atRisk'])->middleware('branch.can:view_reports')->name('reports.atRisk');
    Route::get('/reports/class/{grade}/{section}', [ReportsController::class , 'class'])->middleware('branch.can:view_reports')->name('reports.class');
    Route::get('/reports/student/{student}', [ReportsController::class , 'student'])->middleware('branch.can:view_reports')->name('reports.student');
    Route::get('/reports/student/{student}/subject/{subject}', [ReportsController::class , 'subject'])->middleware('branch.can:view_reports')->name('reports.subject');
    Route::get('/reports/teacher/{teacher}', [ReportsController::class , 'teacher'])->middleware('branch.can:view_reports')->name('reports.teacher');
    Route::get('/reports/generate-ai-analytics', [ReportsController::class , 'generateAiAnalytics'])->middleware('branch.can:view_reports')->name('reports.aiAnalytics');
    Route::get('/reports/ai-report-status/{report}', [ReportsController::class , 'checkAiReportStatus'])->middleware('branch.can:view_reports')->name('reports.aiReportStatus');
});

// School Registration
Route::get('/register-school', [SchoolRegistrationController::class, 'showRegistrationForm'])->name('register-school.index');
Route::post('/register-school', [SchoolRegistrationController::class, 'register'])->name('register-school.post');

// Super Admin Area
Route::group(['prefix' => 'super-admin', 'middleware' => ['super_admin']], function () {
    Route::get('/', [SuperAdminController::class, 'index'])->name('super-admin.dashboard');
    Route::post('/schools/{school}/approve', [SuperAdminController::class, 'approve'])->name('super-admin.schools.approve');
    Route::post('/schools/{school}/reject', [SuperAdminController::class, 'reject'])->name('super-admin.schools.reject');
    Route::post('/schools/{school}/request-modification', [SuperAdminController::class, 'requestModification'])->name('super-admin.schools.request-modification');
    Route::post('/schools/{school}/activate', [SuperAdminController::class, 'activate'])->name('super-admin.schools.activate');
    Route::post('/schools/{school}/suspend', [SuperAdminController::class, 'suspend'])->name('super-admin.schools.suspend');
    Route::post('/schools/{school}/notify', [SuperAdminController::class, 'notify'])->name('super-admin.schools.notify');
    
    // Global Subject Management
    Route::get('/subjects', [GlobalSubjectController::class, 'index'])->name('super-admin.subjects.index');
    Route::post('/subjects', [GlobalSubjectController::class, 'store'])->name('super-admin.subjects.store');
    Route::put('/subjects/{subject}', [GlobalSubjectController::class, 'update'])->name('super-admin.subjects.update');
    Route::delete('/subjects/{subject}', [GlobalSubjectController::class, 'destroy'])->name('super-admin.subjects.destroy');

    // Analytics
    Route::get('/analytics', [AnalyticsController::class, 'index'])->name('super-admin.analytics.index');

    // Global Notifications
    Route::get('/notifications', [SystemNotificationController::class, 'index'])->name('super-admin.notifications.index');
    Route::post('/notifications', [SystemNotificationController::class, 'store'])->name('super-admin.notifications.store');
    Route::delete('/notifications/{notification}', [SystemNotificationController::class, 'destroy'])->name('super-admin.notifications.destroy');

    // Support Tickets
    Route::get('/support', [SupportController::class, 'index'])->name('super-admin.support.index');
    Route::get('/support/{ticket}', [SupportController::class, 'show'])->name('super-admin.support.show');
    Route::post('/support/{ticket}/reply', [SupportController::class, 'reply'])->name('super-admin.support.reply');
    Route::post('/support/{ticket}/close', [SupportController::class, 'close'])->name('super-admin.support.close');

    // System Settings
    Route::get('/settings', [SettingController::class, 'index'])->name('super-admin.settings.index');
    Route::post('/settings', [SettingController::class, 'update'])->name('super-admin.settings.update');
});

use App\Http\Controllers\SchoolSettingsController;

Route::group(['middleware' => ['auth']], function () {
    // These routes check auth but NOT school.active because they are for initialization
    Route::get('/setup-wizard', [SchoolSettingsController::class, 'showWizard'])->name('school-setup.wizard');
    Route::post('/setup-wizard/initialize', [SchoolSettingsController::class, 'initialize'])->name('school-setup.initialize');
});

Route::group(['middleware' => ['auth', 'school.active']], function () {
    Route::get('/settings/school', [SchoolSettingsController::class, 'index'])->name('settings.index');
    Route::post('/settings/school', [SchoolSettingsController::class, 'update'])->name('settings.update');
    
    // Performance Optimization: Asynchronous AI Insights
    Route::get('/api/dashboard/ai-insight', [DashboardController::class, 'getAiInsight'])->name('api.dashboard.ai-insight');

    // System Preferences
    Route::post('/settings/preferences', [SchoolSettingsController::class, 'updatePreferences'])->name('settings.preferences.update');

    // Account Security
    Route::post('/settings/security', [SchoolSettingsController::class, 'updateSecurity'])->name('settings.security.update');

    // Branch Management (For School Admins)
    Route::get('/settings/branches', [BranchController::class, 'index'])->name('settings.branches.index');
    Route::post('/settings/branches', [BranchController::class, 'store'])->name('settings.branches.store');
    Route::get('/settings/branches/requests', [BranchController::class, 'requests'])->name('settings.branches.requests');
    Route::get('/settings/branches/{branch}/permissions', [BranchController::class, 'editPermissions'])->name('settings.branches.permissions.edit');
    Route::post('/settings/branches/{branch}/permissions', [BranchController::class, 'updatePermissions'])->name('settings.branches.permissions.update');
    Route::delete('/settings/branches/requests/{branch}', [BranchController::class, 'destroy'])->name('settings.branches.requests.destroy');
    Route::get('/settings/branches/requests/{branch}/edit', [BranchController::class, 'editRequest'])->name('settings.branches.requests.edit');
    Route::put('/settings/branches/requests/{branch}', [BranchController::class, 'updateRequest'])->name('settings.branches.requests.update');
});





Route::get('/class-subjects', [ClassSectionSubjectController::class , 'index'])
    ->name('class-subjects.index');

Route::get('/class-subjects/list', [ClassSectionSubjectController::class , 'list'])
    ->name('class-subjects.list');

Route::post('/class-subjects/save', [ClassSectionSubjectController::class , 'save'])
    ->name('class-subjects.save');

// Notifications
use App\Http\Controllers\DashboardNotificationController;
Route::get('/notifications', [DashboardNotificationController::class , 'index'])->name('notifications.index');
Route::middleware(['auth', 'school.active'])->group(function () {
    Route::post('/system-notifications/{id}/read', [App\Http\Controllers\SuperAdmin\SystemNotificationController::class, 'trackRead'])->name('notifications.trackRead');
    Route::get('/notifications/{notification}/details', [App\Http\Controllers\SuperAdmin\SystemNotificationController::class, 'getDetails'])->name('notifications.details');
    
    // Dashboard Notifications (Local to the school)
    Route::post('/notifications/{id}/mark-read', [DashboardNotificationController::class, 'markAsRead'])->name('notifications.markRead');
    Route::post('/notifications/mark-all-read', [DashboardNotificationController::class , 'markAllAsRead'])->name('notifications.markAllRead');
    Route::delete('/notifications/clear', [DashboardNotificationController::class , 'clear'])->name('notifications.clear');
    Route::post('/notifications/broadcast', [DashboardNotificationController::class, 'broadcast'])->name('notifications.broadcast');
});

// Help & Support (Unified for all roles except Super Admin)
use App\Http\Controllers\GeneralSupportController;
Route::middleware(['auth', 'school.active'])->group(function () {
    Route::get('/support', [GeneralSupportController::class, 'index'])->name('support.index');
    Route::post('/support/ticket', [GeneralSupportController::class, 'storeTicket'])->name('support.ticket.store');
});