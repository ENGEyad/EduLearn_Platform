# EduLearn Dashboard - Documentation

## Overview

The **EduLearn Dashboard** is a Laravel-based web administration panel for managing the EduLearn educational platform. It provides comprehensive school management capabilities including student management, teacher administration, class scheduling, subject management, and reporting features.

## Project Structure

```
EduLearn_Dashboard/
├── app/
│   ├── Http/
│   │   ├── Controllers/          # Application controllers
│   │   ├── Middleware/           # Authentication & authorization middleware
│   │   └── Controllers/Api/      # API controllers
│   ├── Models/                   # Eloquent models
│   ├── Events/                   # Event classes
│   └── Providers/                # Service providers
├── config/                       # Laravel configuration files
├── database/
│   ├── migrations/              # Database schema migrations
│   └── seeders/                 # Database seeders
├── lang/                         # Localization files (en.json, ar.json)
├── public/
│   └── js/                      # Frontend JavaScript files
├── resources/
│   ├── css/                     # Stylesheets
│   └── views/                   # Blade templates
└── routes/                      # Application routes
```

---

## Features

### 1. Authentication & Authorization

| Feature | Description |
|---------|-------------|
| **School Registration** | New schools can register through `/register-school` |
| **User Login** | Authentication via `/login` with email/password |
| **Role-Based Access** | Super Admin, School Admin, Teacher, Student roles |
| **School Status** | Schools can be Active, Suspended, or Waiting Approval |
| **User Preferences** | Dark/light mode, language settings (EN/AR) |

### 2. Student Management

**Location:** `/students`

**Features:**
- View all students in a paginated table
- Add new students with full profile information
- Edit existing student records
- Delete students
- Import students from CSV/Excel files
- Search by name or academic ID
- Filter by grade level
- Side panel showing detailed student profile

**Student Data Fields:**
- Full Name, Gender, Birthdate
- Academic ID (auto-generated: S-YEAR-XXXX)
- Grade & Class Section
- Email, Address (Governorate, City, Street)
- Guardian Information (Name, Relationship, Phone)
- Status (Active/Suspended)
- Performance Average, Attendance Rate
- Photo upload support

### 3. Teacher Management

**Location:** `/teachers`

**Features:**
- View all teachers in a table format
- Add new teachers with personal details
- Edit teacher profiles
- Delete teachers
- Import teachers from CSV/Excel
- Filter by subject or status
- View teacher assignments and subjects

**Teacher Data Fields:**
- Full Name, Teacher Code (auto-generated: T-YEAR-XXX)
- Date of Birth, Age (auto-calculated)
- Email, Phone
- Shift (Morning/Evening)
- Address (District, Neighborhood, Street)
- Qualification, Join Date
- Status, Performance metrics

### 4. Classes Management

**Location:** `/classes`

**Features:**
- View all class sections
- Add new classes with grade and section
- Edit class details
- Delete classes
- Set academic stage (Primary, Preparatory, Secondary)
- Toggle active/inactive status

**Class Fields:**
- Grade (1-12)
- Section (A, B, C, etc.)
- Name (e.g., "Class 2 - A")
- Academic Stage
- Active Status

### 5. Subjects Management

**Location:** `/subjects`

**Features:**
- View all subjects in the system
- Add new subjects with bilingual names
- Edit subject details
- Delete subjects
- Toggle active status

**Subject Fields:**
- Code (e.g., math, quran, islamic)
- Name (English)
- Name (Arabic)
- Active Status

### 6. Class-Subjects Assignment

**Location:** `/class-subjects`

**Features:**
- Assign subjects to specific class sections
- Enable/disable subjects per class
- View subject assignments per class

### 7. Teacher-Class-Subject Assignments

**Location:** `/assignments`

**Features:**
- Assign teachers to teach specific subjects in specific classes
- Manage teacher workloads
- View all active assignments
- Remove assignments

### 8. Reports

**Location:** `/reports`

**Features:**
- School-wide reports
- Class-specific reports (by grade and section)
- Individual student reports
- Subject-specific performance reports
- Analytics and statistics

### 9. Notifications System

**Location:** `/notifications`

**Features:**
- Real-time notification display
- Mark individual notifications as read
- Mark all notifications as read
- Clear all notifications
- Notification types: alerts, system events, teacher/student events

### 10. Settings

**Location:** `/settings`

**Features:**
- School settings management
- Academic year configuration
- School logo upload
- User preferences (language, theme)

### 11. Super Admin Dashboard

**Location:** `/super-admin`

**Features:**
- View all registered schools
- Activate/suspend schools
- Send notifications to schools
- System-wide oversight

---

## Technical Architecture

### Backend (Laravel)

#### Controllers

| Controller | Responsibility |
|------------|----------------|
| `DashboardController` | Main dashboard view, statistics, AI insights |
| `StudentController` | CRUD operations for students, import functionality |
| `TeacherController` | CRUD operations for teachers, import functionality |
| `ClassSectionController` | Manage class sections |
| `SubjectController` | Manage subjects |
| `ClassSectionSubjectController` | Assign subjects to classes |
| `TeacherClassSubjectController` | Assign teachers to class-subjects |
| `ReportsController` | Generate various reports |
| `DashboardNotificationController` | Manage notifications |
| `SchoolSettingsController` | School configuration |
| `SchoolRegistrationController` | New school registration |
| `SuperAdminController` | Super admin functionality |
| `Auth\LoginController` | Authentication |

#### API Controllers (for Mobile App)

| Controller | Endpoints |
|------------|-----------|
| `Api\StudentAuthController` | Student authentication |
| `Api\TeacherAuthController` | Teacher authentication |
| `Api\StudentLessonController` | Student lesson progress |
| `Api\LessonController` | Lesson management |
| `Api\ChatController` | Chat functionality |
| `Api\AiController` | AI-powered features |
| `Api\ClassModuleController` | Class modules |

#### Models

| Model | Description |
|-------|-------------|
| `Student` | Student profiles and relationships |
| `Teacher` | Teacher profiles and assignments |
| `ClassSection` | Class sections (grade + section) |
| `Subject` | School subjects |
| `School` | School information |
| `User` | System users with roles |
| `TeacherClassSubject` | Teacher-class-subject assignments |
| `ClassSectionSubject` | Class-subject relationships |
| `StudentLessonProgress` | Student progress tracking |
| `DashboardNotification` | System notifications |
| `Lesson`, `LessonModule`, `LessonTopic`, `LessonBlock` | Lesson content structure |
| `LessonExercise`, `LessonExerciseQuestion`, `LessonExerciseOption` | Exercise content |

#### Middleware

| Middleware | Purpose |
|------------|---------|
| `EnsureIsSuperAdmin` | Restricts access to super admins only |
| `EnsureSchoolIsActive` | Checks if school account is active |
| `SetUserPreferences` | Loads user preferences (theme, language) |

### Frontend

#### Views (Blade Templates)

| View | Route | Description |
|------|-------|-------------|
| `layouts/app.blade.php` | - | Main layout with sidebar, topbar, notifications |
| `dashboard.blade.php` | `/dashboard` | Main dashboard with stats and charts |
| `students.blade.php` | `/students` | Student management interface |
| `teachers.blade.php` | `/teachers` | Teacher management interface |
| `classes.blade.php` | `/classes` | Class management interface |
| `subjects.blade.php` | `/subjects` | Subject management interface |
| `assignments.blade.php` | `/assignments` | Assignment management |
| `class_subjects.blade.php` | `/class-subjects` | Class-subject mapping |
| `reports.blade.php` | `/reports` | Reports and analytics |
| `notifications/index.blade.php` | `/notifications` | Notification center |
| `settings/school.blade.php` | `/settings` | School settings |
| `super_admin/dashboard.blade.php` | `/super-admin` | Super admin panel |
| `auth/login.blade.php` | `/login` | Login page |
| `auth/register_school.blade.php` | `/register-school` | School registration |

#### JavaScript Files

| File | Purpose |
|------|---------|
| `students.js` | Student CRUD operations, search, import |
| `teachers.js` | Teacher CRUD operations, search, import |
| `classes.js` | Class management, modal forms |
| `subjects.js` | Subject management |
| `assignments.js` | Assignment management |
| `class_subjects.js` | Class-subject assignment |
| `reports.js` | Report generation and display |

#### Styling

- **Framework:** Bootstrap 5 (RTL support)
- **Icons:** Bootstrap Icons
- **Fonts:** Google Fonts (Cairo)
- **Charts:** Chart.js
- **Theme:** Light/Dark mode support
- **Direction:** Full RTL/LTR support (Arabic/English)

---

## Routes

### Web Routes

```
GET  /                          → Redirect based on auth state
GET  /login                     → Login form
POST /login                     → Process login
POST /logout                    → Logout

GET  /dashboard                 → Main dashboard (auth required)

GET  /students                  → Student list view
GET  /students/list             → JSON list of students
POST /students                  → Create student
PUT  /students/{id}             → Update student
DELETE /students/{id}           → Delete student
POST /students/import           → Import from CSV/Excel

GET  /teachers                  → Teacher list view
GET  /teachers/list             → JSON list of teachers
POST /teachers                  → Create teacher
PUT  /teachers/{id}             → Update teacher
DELETE /teachers/{id}           → Delete teacher
POST /teachers/import           → Import from CSV/Excel

GET  /classes                   → Class list
GET  /classes/list              → JSON list of classes
POST /classes                   → Create class
PUT  /classes/{id}              → Update class
DELETE /classes/{id}            → Delete class

GET  /subjects                  → Subject list
GET  /subjects/list             → JSON list of subjects
POST /subjects                  → Create subject
PUT  /subjects/{id}             → Update subject
DELETE /subjects/{id}           → Delete subject

GET  /assignments               → Assignment list
GET  /assignments/list          → JSON list of assignments
POST /assignments              → Create assignment
DELETE /assignments/{id}       → Delete assignment

GET  /class-subjects           → Class-subject mapping
GET  /class-subjects/list      → JSON list of mappings
POST /class-subjects/save      → Save mappings

GET  /reports                   → Reports overview
GET  /reports/list             → JSON reports data
GET  /reports/class/{grade}/{section} → Class-specific report
GET  /reports/student/{id}     → Student report
GET  /reports/student/{id}/subject/{subj} → Subject-specific report

GET  /notifications            → Notification center
POST /notifications/mark-read/{id} → Mark as read
POST /notifications/mark-all-read → Mark all as read
DELETE /notifications/clear     → Clear all notifications

GET  /settings                  → Settings page
POST /settings                  → Update settings
POST /settings/preferences      → Update preferences

GET  /register-school           → School registration
POST /register-school           → Process registration

GET  /super-admin              → Super admin dashboard
POST /super-admin/schools/{id}/activate → Activate school
POST /super-admin/schools/{id}/suspend → Suspend school
POST /super-admin/schools/{id}/notify  → Notify school
```

### API Routes

```
POST /api/ai/generate-exercises    → AI exercise generation
POST /api/ai/daily-report          → AI daily report
POST /api/ai/submit-response       → Submit AI response
POST /api/ai/adaptive-exercises    → Get adaptive exercises

GET  /api/dashboard/ai-insight     → Get AI-powered insight

POST /api/auth/student/login       → Student login
POST /api/auth/teacher/login       → Teacher login
```

---

## Database Schema

### Key Tables

| Table | Purpose |
|-------|---------|
| `users` | System users with role-based access |
| `schools` | School information and settings |
| `students` | Student profiles |
| `teachers` | Teacher profiles |
| `class_sections` | Class sections (grade + section) |
| `subjects` | Available subjects |
| `teacher_class_subjects` | Teacher-class-subject assignments |
| `class_section_subjects` | Subject-class mappings |
| `lessons` | Lesson content |
| `lesson_modules` | Lesson module sections |
| `lesson_topics` | Lesson topics |
| `lesson_blocks` | Content blocks within topics |
| `lesson_exercises` | Exercise sets |
| `lesson_exercise_questions` | Exercise questions |
| `lesson_exercise_options` | Question options |
| `student_lesson_progress` | Student progress tracking |
| `dashboard_notifications` | System notifications |

---

## Internationalization (i18n)

The dashboard supports **English** and **Arabic** languages.

### Language Files
- `lang/en.json` - English translations
- `lang/ar.json` - Arabic translations

### Usage in Views
```blade
{{ __('Dashboard') }}
{{ __('Students') }}
{{ __('Welcome, :name', ['name' => $user->name]) }}
```

### RTL Support
The application automatically switches to RTL layout when Arabic is selected:
```blade
<html dir="{{ app()->getLocale() == 'ar' ? 'rtl' : 'ltr' }}">
```

---

## AI Integration

The dashboard integrates with an external AI service for:

1. **Exercise Generation** - Auto-generate quiz questions
2. **Daily Reports** - AI-powered school performance analysis
3. **Adaptive Exercises** - Personalized learning content
4. **Dashboard Insights** - Real-time AI analysis of school data

AI endpoint: `http://127.0.0.1:8001/chat/`

---

## Caching Strategy

Dashboard statistics are cached for 5 minutes to improve performance:

```php
$cacheKey = "dashboard_stats_school_" . auth()->user()->school_id;
$stats = Cache::remember($cacheKey, now()->addMinutes(5), function () {
    return [
        'teachers' => Teacher::count(),
        'students' => Student::count(),
        // ...
    ];
});
```

---

## Security Features

- CSRF Token protection on all forms
- Role-based access control (RBAC)
- School isolation (users only see their school's data)
- Input validation on all endpoints
- Password hashing for user accounts
- Session management

---

## Third-Party Packages

| Package | Purpose |
|---------|---------|
| Laravel Framework | Core PHP framework |
| Bootstrap 5 | CSS framework |
| Chart.js | Data visualization |
| Maatwebsite/Excel | CSV/Excel import/export |
| Laravel Sanctum | API authentication |
| Laravel Reverb | Real-time WebSocket support |

---

## Installation & Setup

1. Clone the repository
2. Run `composer install`
3. Copy `.env.example` to `.env` and configure database
4. Run `php artisan migrate` for database schema
5. Run `php artisan storage:link` for file uploads
6. Start the development server: `php artisan serve`

### Requirements
- PHP 8.1+
- MySQL 5.7+ / MariaDB 10.3+
- Composer
- Node.js (for asset compilation)

---

## API Endpoints for Mobile App

The dashboard also serves as the backend API for the EduLearn mobile application:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/student/login` | POST | Student authentication |
| `/api/auth/teacher/login` | POST | Teacher authentication |
| `/api/student/lessons` | GET | Get student's lessons |
| `/api/lessons/{id}` | GET | Get lesson content |
| `/api/lessons/{id}/progress` | POST | Update lesson progress |
| `/api/chat/send` | POST | Send chat message |
| `/api/ai/generate-exercises` | POST | Generate exercises |

---

## Future Enhancements

- Attendance tracking module
- Grade book integration
- Parent portal
- Examination management
- Payment/fees tracking
- Transportation management
- Advanced analytics dashboard
- Mobile app notifications

---

## Support

For technical support or questions about this documentation, please refer to the project repository or contact the development team.
