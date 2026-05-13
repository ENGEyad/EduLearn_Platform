AI Agent Prompt: EduLearn School Management System Development (Laravel)
Overall Goal
Develop a fully functional web application for the EduLearn School Management System using Laravel, encompassing database implementation, backend API development, and frontend UI development. The system must support a comprehensive school registration workflow, super admin approval processes, system initialization with dynamic subject selection, and subsequent management functionalities for students, teachers, classes, and subjects, as detailed in the provided documentation and reconciled requirements.

Technology Stack
Backend: Laravel (PHP 8+), Eloquent ORM, Controllers, Middleware.
Frontend: Laravel Blade Templates, HTML5, CSS3, Bootstrap 5 (with RTL support), JavaScript (Vanilla/jQuery), Chart.js.
Database: MySQL (or PostgreSQL).
Authentication: Laravel's built-in authentication system.
Email Service: Laravel's mail system, configurable with various drivers.

Phased Development Plan for the AI Agent
The development will proceed in the following sequential phases, adhering to the Laravel project structure and conventions:

Phase 1: Laravel Project Setup and Database Implementation
Objective: Initialize the Laravel project, define the database schema using migrations, and seed initial data.

Instructions:
Project Initialization: Create a new Laravel project named EduLearn_Dashboard.
Environment Configuration: Configure the .env file for database connection (MySQL/PostgreSQL) and other essential settings.
Model Creation: Generate Eloquent models for School, User, Student, Teacher, ClassSection, Subject, ClassSectionSubject, and TeacherClassSubject. Ensure models define relationships (e.g., hasMany, belongsTo, belongsToMany).
Migration Creation: Create database migrations for each model, accurately defining all fields, data types, constraints (primary keys, foreign keys, unique, not null), and default values as specified in the updated_design_document.md.
Pay close attention to ENUM types, JSON types, and auto-generated fields like academic_id and teacher_code.
Implement status fields for School (Active, Suspended, Waiting Approval) and Student/Teacher (Active/Suspended).
Seeder Creation: Create seeders to populate initial data for Subjects (with bilingual names) and any other necessary lookup data or test users (e.g., a Super Admin user).
Run Migrations and Seeders: Execute php artisan migrate and php artisan db:seed to set up the database.

Expected Output:
A fully initialized Laravel project with configured .env.
Eloquent models with defined relationships.
Database migrations for all required tables.
Database seeders for initial data.
A brief Markdown document (db_setup_summary.md) summarizing the database setup and migration process.

Phase 2: Backend Development (Controllers, Routes, Middleware)
Objective: Implement the backend logic, including controllers, web routes, API routes, and middleware for authentication and authorization.

Instructions:
Authentication: Implement Laravel's built-in authentication for user login (/login) and school registration (/register-school).
Develop SchoolRegistrationController to handle new school submissions, including validation, password hashing, and setting the initial status to Waiting Approval.
Develop Auth\LoginController for user authentication.
Super Admin Functionality: Implement SuperAdminController.
Route: /super-admin.
Endpoints to view all registered schools and manage their status (Activate, Suspend, Approve, Reject, Request Modification).
Logic to send email notifications for status changes (e.g., using Laravel Mailables).
Core Management Controllers: Develop controllers for CRUD operations as per DOCUMENTATION.md:
StudentController: /students (CRUD, import, search, filter).
TeacherController: /teachers (CRUD, import, filter).
ClassSectionController: /classes (CRUD, academic stage management).
SubjectController: /subjects (CRUD, bilingual names).
ClassSectionSubjectController: /class-subjects (assign subjects to classes).
TeacherClassSubjectController: /assignments (assign teachers to class-subjects).
School Settings Controller: Implement SchoolSettingsController for school-specific configurations, academic year, logo upload, and user preferences.
Include logic for the school system initialization process, allowing school admins to confirm school type/section and select subjects, updating the SchoolSubjects table.
Middleware: Implement middleware as described in DOCUMENTATION.md:
EnsureIsSuperAdmin: Restrict access to Super Admin routes.
EnsureSchoolIsActive: Check if a school account is active before allowing access to its dashboard.
SetUserPreferences: Load user preferences (theme, language).
Routes: Define web routes (routes/web.php) for all UI-driven functionalities and API routes (routes/api.php) for mobile app integration (if applicable, focusing on the dashboard first).

Expected Output:
Laravel controllers implementing all specified business logic.
Defined web and API routes.
Implemented middleware for access control and preferences.
A README.md in the backend section (or main project) detailing API endpoints and usage.

Phase 3: Frontend UI Development (Blade Templates, JavaScript, Styling)
Objective: Develop the user interface using Laravel Blade templates, integrating Bootstrap 5, custom JavaScript, and Chart.js for a responsive and interactive experience.

Instructions:
Layouts: Create layouts/app.blade.php (main layout with sidebar, topbar, notifications) and layouts/auth.blade.php (for login/registration pages).
School Registration UI: Develop auth/register_school.blade.php.
Implement the registration form with all required fields.
Use JavaScript (e.g., public/js/register_school.js) to handle conditional display of the "Section" field based on "School Type" selection.
Apply Bootstrap 5 styling for form elements and responsiveness.
Super Admin Dashboard UI: Develop super_admin/dashboard.blade.php.
Display a paginated table of registered schools with their statuses.
Implement UI for actions (Approve, Reject, Request Modification) using modals or dedicated forms.
Integrate Chart.js for any relevant statistics or reports.
School System Initialization UI: Develop a Blade template for the setup wizard.
Upon first login (or post-approval), guide the school admin to confirm school type/section.
Present dynamic subject selection options based on the school's configuration, allowing selection/deselection. Use JavaScript to filter/display subjects.
Core Management UIs: Create dedicated Blade templates for:
students.blade.php: Student management (table, add/edit modals, search, filter, import).
teachers.blade.php: Teacher management (table, add/edit modals, import).
classes.blade.php: Class management (table, add/edit modals).
subjects.blade.php: Subject management (table, add/edit modals, bilingual names).
class_subjects.blade.php: Assign subjects to classes.
assignments.blade.php: Assign teachers to class-subjects.
Settings UI: Develop settings/school.blade.php for school configurations and user preferences (language, theme).
JavaScript Integration: Create dedicated JavaScript files (e.g., public/js/students.js, public/js/teachers.js) to handle client-side interactions, AJAX calls to backend, form submissions, and dynamic UI updates.
Styling: Consistently apply Bootstrap 5 for all UI elements, ensuring full RTL/LTR support and responsiveness. Use Bootstrap Icons and Google Fonts (Cairo).

Expected Output:
Laravel Blade templates for all specified UI views.
Custom JavaScript files for dynamic functionalities.
Integrated Bootstrap 5 styling with RTL/LTR support.
A README.md in the frontend section (or main project) detailing UI components and their usage.

Phase 4: Integration, Testing, and Documentation
Objective: Integrate the frontend and backend, perform comprehensive testing, and provide detailed documentation for the entire system.

Instructions:
Integration: Ensure seamless communication between Blade templates (via forms and AJAX) and Laravel backend controllers.
Functional Testing: Conduct thorough functional testing for all core workflows:
School registration and Super Admin approval/rejection/modification.
School admin login and system initialization (subject selection).
CRUD operations for Students, Teachers, Classes, Subjects.
Class-Subject and Teacher-Class-Subject assignments.
User preferences (language, theme).
Error Handling: Implement robust error handling and user-friendly feedback messages across both frontend and backend.
Security Review: Verify authentication and authorization mechanisms are secure.
Comprehensive Documentation: Create a final README.md for the root project directory that includes:
Project overview and purpose.
Detailed setup instructions for the entire Laravel application (database, dependencies, environment).
Key features and how to use them, including user roles and workflows.
Technical architecture overview (Laravel components, database schema).
Instructions for running tests.
Any known limitations, future improvements, or deployment considerations.

Expected Output:
A fully integrated and runnable Laravel application.
A comprehensive README.md in the root directory.
A brief Markdown document (testing_report.md) outlining the tests performed, their results, and any identified issues.
