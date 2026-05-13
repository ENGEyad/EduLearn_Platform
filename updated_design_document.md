Updated Design Document: EduLearn School Management System
1. Database Schema (Laravel Eloquent Models)
This section outlines the revised database schema, aligning with the Laravel Eloquent models and relationships described in the provided documentation. The design supports the comprehensive features of the EduLearn Dashboard.

Model: School
Model: User
Model: Student
Model: Teacher
Model: ClassSection
Model: Subject
Model: ClassSectionSubject (Pivot Table)
Model: TeacherClassSubject (Pivot Table)
Other Models (as per documentation, but not detailed here for brevity):
DashboardNotification
Lesson, LessonModule, LessonTopic, LessonBlock
LessonExercise, LessonExerciseQuestion, LessonExerciseOption
StudentLessonProgress

2. UI Architecture and Flow (Laravel Blade & JavaScript)
This section outlines the user interface (UI) architecture and the flow of interactions, specifically tailored for a Laravel Blade-based frontend with Bootstrap 5 and custom JavaScript.

2.1. School Registration Form (auth/register_school.blade.php)
Layout: A dedicated Blade template for school registration, likely extending a base layout (layouts/app.blade.php or layouts/auth.blade.php).
Fields: All required fields for school registration, as per the reconciled requirements.
Conditional Logic: JavaScript will handle the dynamic display of the "Section" field based on "School Type" selection. This will involve client-side scripting, likely within a dedicated JavaScript file (e.g., register_school.js).
Validation: Server-side validation will be handled by Laravel controllers. Client-side validation can be implemented using JavaScript for immediate feedback.
Styling: Bootstrap 5 for form elements and layout, ensuring responsiveness and RTL/LTR support.

2.2. Super Admin Dashboard (super_admin/dashboard.blade.php)
Overview: A Blade template displaying a list of registered schools, their statuses, and actions.
Request Details: Modals or dedicated detail pages (Blade templates) to show comprehensive school information.
Actions: Buttons for "Activate/Suspend", "Approve", "Reject", "Request Modification". These actions will trigger AJAX requests to the SuperAdminController.
Notifications: Display of system notifications, managed by DashboardNotificationController.
Styling: Bootstrap 5 tables, cards, and forms. Chart.js for any statistical displays.

2.3. School System Initialization UI (Post-Approval)
Login Page: Standard Laravel authentication login page (auth/login.blade.php).
Setup Wizard: After successful login, if the school's status is Waiting Approval and then Active, a Blade template will guide the school admin through the setup.
Confirmation: Display school type and section(s).
Subject Selection: A form within a Blade template to select/confirm subjects. This will involve dynamic rendering based on school type/section, potentially using JavaScript to filter subjects from a pre-loaded list or an AJAX call to fetch relevant subjects.
Backend: SchoolSettingsController will handle saving these configurations.

2.4. Core Management UIs (e.g., Student, Teacher, Class, Subject Management)
Dedicated Blade Templates: Each management area (e.g., students.blade.php, teachers.blade.php, classes.blade.php, subjects.blade.php) will have its own Blade template.
Data Display: Paginated tables for viewing records, with search and filter functionalities implemented via AJAX calls and JavaScript.
CRUD Operations: Modals or dedicated forms (within Blade templates) for Add, Edit, Delete operations. These will submit data via AJAX to the respective Laravel controllers (e.g., StudentController, TeacherController).
Import Functionality: Forms for uploading CSV/Excel files, handled by Laravel controllers.
Styling: Consistent use of Bootstrap 5 for UI elements, RTL/LTR support, and responsive design.
JavaScript: Dedicated JavaScript files (e.g., students.js, teachers.js) will manage client-side interactions, form submissions, dynamic updates, and data manipulation.

2.5. Settings UI (settings/school.blade.php)
School Settings: Blade template for managing school-specific configurations, academic year, and logo upload.
User Preferences: Blade template for language and theme settings, with JavaScript to apply changes dynamically.

3. Technology Stack (Confirmed)
Backend: Laravel (PHP 8+)
Frontend: Laravel Blade Templates, HTML5, CSS3, Bootstrap 5 (with RTL support), JavaScript (Vanilla/jQuery), Chart.js.
Database: MySQL (as implied by Laravel's common usage, or PostgreSQL).
Authentication: Laravel's built-in authentication system.
Email Service: Laravel's mail system, configurable with various drivers (e.g., SMTP, Mailgun, SendGrid).

4. Workflow Summary (Updated)
School Registration: User accesses /register-school, fills out the form (dynamic fields for section), and submits. Data is processed by SchoolRegistrationController.
Super Admin Review: Super Admin logs in, navigates to /super-admin, views requests. Actions (Approve, Reject, Request Modification) are handled by SuperAdminController, triggering email notifications.
School Modification (if requested): School receives email, logs in, accesses their registration details (if in draft/modification state), updates, and resubmits. Handled by SchoolSettingsController or similar.
System Initialization: Upon approval, school admin logs in. If first login post-approval, a setup wizard (Blade template with JS) guides them to confirm school type/section and select subjects. Data saved via SchoolSettingsController.
Ongoing Management: School admins use dedicated Blade views and associated JavaScript for Student, Teacher, Class, Subject, and Assignment management. New user/branch creation follows similar registration/approval workflows.

--- Table 1 ---
Field Name | Data Type | Description | Constraints
id | BIGINT | Primary Key, Auto-increment | PRIMARY KEY
name | VARCHAR(255) | School's official name | NOT NULL, UNIQUE
logo_url | VARCHAR(255) | URL to school's logo | 
academic_year | VARCHAR(50) | Current academic year (e.g., "2025-2026") | NOT NULL
country | VARCHAR(100) | Country where the school is located | NOT NULL
city | VARCHAR(100) | City where the school is located | NOT NULL
district | VARCHAR(100) | District where the school is located | NOT NULL
email | VARCHAR(255) | School's contact email | NOT NULL, UNIQUE
contact_number | VARCHAR(50) | School's contact phone number | NOT NULL
school_type | ENUM | 'Primary', 'Secondary', 'Primary/Secondary', 'Other' | NOT NULL
section | ENUM | 'Scientific', 'Literary', 'Scientific/Literary', NULL | 
address | TEXT | Full physical address of the school | NOT NULL
admin_name | VARCHAR(255) | Name of the system administrator for the school | NOT NULL
website | VARCHAR(255) | School's official website | 
password | VARCHAR(255) | Hashed password for school admin login | NOT NULL
num_students | INT | Number of students school wishes to register | NOT NULL
status | ENUM | 'Active', 'Suspended', 'Waiting Approval' | NOT NULL, DEFAULT 'Waiting Approval'
rejection_reason | TEXT | Reason for rejection, if applicable | 
created_at | TIMESTAMP | Timestamp of creation | DEFAULT CURRENT_TIMESTAMP
updated_at | TIMESTAMP | Timestamp of last update | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

--- Table 2 ---
Field Name | Data Type | Description | Constraints
id | BIGINT | Primary Key, Auto-increment | PRIMARY KEY
school_id | BIGINT | Foreign Key to Schools table | FOREIGN KEY
name | VARCHAR(255) | User's full name | NOT NULL
email | VARCHAR(255) | User's email (used for login) | NOT NULL, UNIQUE
password | VARCHAR(255) | Hashed password | NOT NULL
role | ENUM | 'SuperAdmin', 'SchoolAdmin', 'Teacher', 'Student' | NOT NULL
preferences | JSON | Dark/light mode, language settings (EN/AR) | 
created_at | TIMESTAMP | Timestamp of creation | DEFAULT CURRENT_TIMESTAMP
updated_at | TIMESTAMP | Timestamp of last update | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

--- Table 3 ---
Field Name | Data Type | Description | Constraints
id | BIGINT | Primary Key, Auto-increment | PRIMARY KEY
school_id | BIGINT | Foreign Key to Schools table | FOREIGN KEY
class_section_id | BIGINT | Foreign Key to ClassSection table | FOREIGN KEY
full_name | VARCHAR(255) | Student's full name | NOT NULL
gender | ENUM | 'Male', 'Female' | NOT NULL
birthdate | DATE | Student's birthdate | NOT NULL
academic_id | VARCHAR(50) | Auto-generated: S-YEAR-XXXX | NOT NULL, UNIQUE
email | VARCHAR(255) | Student's email | UNIQUE
address_governorate | VARCHAR(100) | Student's governorate | 
address_city | VARCHAR(100) | Student's city | 
address_street | VARCHAR(255) | Student's street address | 
guardian_name | VARCHAR(255) | Guardian's full name | 
guardian_relationship | VARCHAR(100) | Guardian's relationship to student | 
guardian_phone | VARCHAR(50) | Guardian's phone number | 
status | ENUM | 'Active', 'Suspended' | DEFAULT 'Active'
performance_average | DECIMAL(5,2) | Student's average performance | 
attendance_rate | DECIMAL(5,2) | Student's attendance rate | 
photo_url | VARCHAR(255) | URL to student's photo | 
created_at | TIMESTAMP | Timestamp of creation | DEFAULT CURRENT_TIMESTAMP
updated_at | TIMESTAMP | Timestamp of last update | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

--- Table 4 ---
Field Name | Data Type | Description | Constraints
id | BIGINT | Primary Key, Auto-increment | PRIMARY KEY
school_id | BIGINT | Foreign Key to Schools table | FOREIGN KEY
full_name | VARCHAR(255) | Teacher's full name | NOT NULL
teacher_code | VARCHAR(50) | Auto-generated: T-YEAR-XXX | NOT NULL, UNIQUE
birthdate | DATE | Teacher's birthdate | NOT NULL
email | VARCHAR(255) | Teacher's email | UNIQUE
phone | VARCHAR(50) | Teacher's phone number | 
shift | ENUM | 'Morning', 'Evening' | 
address_district | VARCHAR(100) | Teacher's district | 
address_neighborhood | VARCHAR(100) | Teacher's neighborhood | 
address_street | VARCHAR(255) | Teacher's street address | 
qualification | VARCHAR(255) | Teacher's highest qualification | 
join_date | DATE | Date teacher joined | NOT NULL
status | ENUM | 'Active', 'Inactive' | DEFAULT 'Active'
performance_metrics | JSON | JSON object for performance metrics | 
created_at | TIMESTAMP | Timestamp of creation | DEFAULT CURRENT_TIMESTAMP
updated_at | TIMESTAMP | Timestamp of last update | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

--- Table 5 ---
Field Name | Data Type | Description | Constraints
id | BIGINT | Primary Key, Auto-increment | PRIMARY KEY
school_id | BIGINT | Foreign Key to Schools table | FOREIGN KEY
grade | INT | Grade level (1-12) | NOT NULL
section_name | VARCHAR(10) | Section identifier (e.g., 'A', 'B') | NOT NULL
name | VARCHAR(255) | Full class name (e.g., "Class 2 - A") | NOT NULL
academic_stage | ENUM | 'Primary', 'Preparatory', 'Secondary' | NOT NULL
is_active | BOOLEAN | Whether the class is active | DEFAULT TRUE
created_at | TIMESTAMP | Timestamp of creation | DEFAULT CURRENT_TIMESTAMP
updated_at | TIMESTAMP | Timestamp of last update | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

--- Table 6 ---
Field Name | Data Type | Description | Constraints
id | BIGINT | Primary Key, Auto-increment | PRIMARY KEY
code | VARCHAR(50) | Subject code (e.g., 'math', 'quran') | NOT NULL, UNIQUE
name_en | VARCHAR(255) | Subject name in English | NOT NULL
name_ar | VARCHAR(255) | Subject name in Arabic | NOT NULL
is_active | BOOLEAN | Whether the subject is active | DEFAULT TRUE
created_at | TIMESTAMP | Timestamp of creation | DEFAULT CURRENT_TIMESTAMP
updated_at | TIMESTAMP | Timestamp of last update | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

--- Table 7 ---
Field Name | Data Type | Description | Constraints
id | BIGINT | Primary Key, Auto-increment | PRIMARY KEY
class_section_id | BIGINT | Foreign Key to ClassSection table | FOREIGN KEY
subject_id | BIGINT | Foreign Key to Subject table | FOREIGN KEY
is_active | BOOLEAN | Whether the subject is active for this class | DEFAULT TRUE
created_at | TIMESTAMP | Timestamp of creation | DEFAULT CURRENT_TIMESTAMP
updated_at | TIMESTAMP | Timestamp of last update | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

--- Table 8 ---
Field Name | Data Type | Description | Constraints
id | BIGINT | Primary Key, Auto-increment | PRIMARY KEY
teacher_id | BIGINT | Foreign Key to Teacher table | FOREIGN KEY
class_section_subject_id | BIGINT | Foreign Key to ClassSectionSubject table | FOREIGN KEY
created_at | TIMESTAMP | Timestamp of creation | DEFAULT CURRENT_TIMESTAMP
updated_at | TIMESTAMP | Timestamp of last update | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
