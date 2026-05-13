Reconciled Requirements: EduLearn School Management System
1. School Registration & Approval (Original + Documentation)
Registration Path: /register-school
Fields: Logo, School Name, Academic Year, Country, City, District, Email, Contact Number.
School Type Selection:
Primary (أساسي)
Secondary (ثانوي)
Primary/Secondary (أساسي/ثانوي)
Other (أخرى)
Conditional Logic: If "Secondary" or "Primary/Secondary" is selected, show Section (القسم) options:
Scientific (علمي)
Literary (أدبي)
Scientific/Literary (علمي/أدبي)
Additional Fields: Address, System Admin Name, Website, Password, Confirm Password, Number of Students.
Super Admin Workflow:
Location: /super-admin
Actions: Approve, Reject (with email reason), Request Modification (draft mode).
Statuses: Active, Suspended, Waiting Approval.

2. System Initialization (Post-Approval)
Login: /login
Setup Screen: Confirm school type and sections.
Subject Selection: Based on the confirmed type/section.
Primary (1-9): Arabic, Islamic Education, Math, Science, Social Studies, English, Quran.
Grade 10 (Common): Arabic, Islamic Education, English, Math, Physics, Chemistry, Biology, History, Geography, National Education, Quran.
Scientific (11-12): Arabic, Islamic Education, English, Math, Physics, Chemistry, Biology, Quran.
Literary (11-12): Arabic, Islamic Education, English, History, Geography, Philosophy/Psychology, Sociology, Quran.

3. Core Management Features (From Documentation)
Student Management: CRUD, Import (CSV/Excel), Search, Filter, Academic ID (S-YEAR-XXXX).
Teacher Management: CRUD, Import, Assignments, Teacher Code (T-YEAR-XXX).
Classes Management: Grade (1-12), Section (A, B, C), Academic Stage.
Subjects Management: Bilingual names (EN/AR), Codes.
Assignments:
Class-Subjects: Mapping subjects to specific classes.
Teacher-Class-Subject: Assigning teachers to specific subjects in specific classes.
Reports: School-wide, Class-specific, Student-specific, Subject-specific.
Notifications: Real-time alerts, system events.
Settings: Academic year, Logo, User preferences (Dark/Light, EN/AR).

4. Technical Architecture (Laravel)
Backend: Laravel (PHP), Eloquent Models, Controllers, Middleware.
Frontend: Blade Templates, Bootstrap 5 (RTL/LTR), Chart.js, JavaScript (Vanilla/jQuery).
API: Specialized controllers for Mobile App integration.
