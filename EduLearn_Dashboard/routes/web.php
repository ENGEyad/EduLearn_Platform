<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\StudentController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\TeacherController;
use App\Http\Controllers\ReportsController;
use App\Http\Controllers\SubjectController;
use App\Http\Controllers\ClassSectionController;
use App\Http\Controllers\ClassSectionSubjectController;
use App\Http\Controllers\TeacherClassSubjectController;

// الهوم -> الداشبورد
Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard.index');

// students
Route::get('/students', [StudentController::class, 'index'])->name('students.index');
Route::get('/students/list', [StudentController::class, 'list'])->name('students.list');
Route::post('/students', [StudentController::class, 'store'])->name('students.store');
Route::put('/students/{student}', [StudentController::class, 'update'])->name('students.update');
Route::delete('/students/{student}', [StudentController::class, 'destroy'])->name('students.destroy');
Route::post('/students/import', [StudentController::class, 'import'])->name('students.import');

// teachers
Route::get('/teachers', [TeacherController::class, 'index'])->name('teachers.index');
Route::get('/teachers/list', [TeacherController::class, 'list'])->name('teachers.list');
Route::post('/teachers', [TeacherController::class, 'store'])->name('teachers.store');
Route::put('/teachers/{teacher}', [TeacherController::class, 'update'])->name('teachers.update');
Route::delete('/teachers/{teacher}', [TeacherController::class, 'destroy'])->name('teachers.destroy');
Route::post('/teachers/import', [TeacherController::class, 'import'])->name('teachers.import');

// classes (ClassSections)
Route::get('/classes', [ClassSectionController::class, 'index'])->name('classes.index');
Route::get('/classes/list', [ClassSectionController::class, 'list'])->name('classes.list');
Route::post('/classes', [ClassSectionController::class, 'store'])->name('classes.store');
Route::put('/classes/{class_section}', [ClassSectionController::class, 'update'])->name('classes.update');
Route::delete('/classes/{class_section}', [ClassSectionController::class, 'destroy'])->name('classes.destroy');

// subjects
Route::get('/subjects', [SubjectController::class, 'index'])->name('subjects.index');
Route::get('/subjects/list', [SubjectController::class, 'list'])->name('subjects.list');
Route::post('/subjects', [SubjectController::class, 'store'])->name('subjects.store');
Route::put('/subjects/{subject}', [SubjectController::class, 'update'])->name('subjects.update');
Route::delete('/subjects/{subject}', [SubjectController::class, 'destroy'])->name('subjects.destroy');

// teacher – class – subject assignments
Route::get('/assignments', [TeacherClassSubjectController::class, 'index'])->name('assignments.index');
Route::get('/assignments/list', [TeacherClassSubjectController::class, 'list'])->name('assignments.list');
Route::post('/assignments', [TeacherClassSubjectController::class, 'store'])->name('assignments.store');
Route::delete('/assignments/{assignment}', [TeacherClassSubjectController::class, 'destroy'])->name('assignments.destroy');

// صفحات ثابتة مؤقتة (attendance فقط الآن)
Route::view('/attendance', 'placeholder', [
    'pageTitle' => 'Attendance',
    'pageSubtitle' => 'Track attendance from mobile app'
])->name('attendance.index');

// Reports
Route::get('/reports', [ReportsController::class, 'index'])->name('reports.index');
Route::get('/reports/list', [ReportsController::class, 'list'])->name('reports.list');
Route::get('/reports/class/{grade}/{section}', [ReportsController::class, 'class'])->name('reports.class');
Route::get('/reports/student/{student}', [ReportsController::class, 'student'])->name('reports.student');

Route::view('/settings', 'placeholder', [
    'pageTitle' => 'Settings',
    'pageSubtitle' => 'Configure school branding, users and notifications'
])->name('settings.index');





Route::get('/class-subjects', [ClassSectionSubjectController::class, 'index'])
    ->name('class-subjects.index');

Route::get('/class-subjects/list', [ClassSectionSubjectController::class, 'list'])
    ->name('class-subjects.list');

Route::post('/class-subjects/save', [ClassSectionSubjectController::class, 'save'])
    ->name('class-subjects.save');