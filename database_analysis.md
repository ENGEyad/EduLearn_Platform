# EduLearn Platform: Database Architecture Analysis

## 1. Overview
The EduLearn platform utilizes a dual-database architecture to separate administrative concerns from educational content and interactive features. This ensures high performance, better data isolation, and scalability.

- **Management Database (CMS)**: `edulearn_db` (Default connection: `mysql`)
- **Educational/App Database (Operational)**: `edulearn_app` (Connection: `app_mysql`)

---

## 2. Management Database Structure (`edulearn_db`)

### 2.1 Core Administration Tables
| Table | Key Fields | Relationships |
| :--- | :--- | :--- |
| **`schools`** | `id`, `name`, `slug`, `school_type`, `is_initialized`, `parent_school_id` | `1:N` with `users`, `students`, `teachers`, `class_sections`. `N:N` with `subjects`. |
| **`users`** | `id`, `name`, `email`, `password`, `role`, `school_id`, `branch_id` | `N:1` with `schools`. |
| **`branches`** | (Stored in `schools`) `parent_school_id`, `name` | `N:1` with parent `schools`. |

### 2.2 Academic Skeleton
| Table | Key Fields | Relationships |
| :--- | :--- | :--- |
| **`class_sections`** | `id`, `school_id`, `grade`, `section`, `stage`, `name` | `N:1` with `schools`. `1:N` with `students`. |
| **`subjects`** | `id`, `code`, `name_en`, `name_ar`, `is_active` | `N:N` with `schools` via `school_subjects`. |
| **`school_subjects`** | `school_id`, `subject_id`, `is_active` | **Pivot Table** linking `schools` and `subjects`. |
| **`class_section_subjects`** | `class_section_id`, `subject_id`, `is_active` | **Pivot Table** linking `class_sections` and `subjects`. |

### 2.3 People & Roles
| Table | Key Fields | Relationships |
| :--- | :--- | :--- |
| **`students`** | `id`, `academic_id`, `full_name`, `gender`, `class_section_id`, `school_id` | `N:1` with `schools` and `class_sections`. |
| **`teachers`** | `id`, `teacher_code`, `full_name`, `email`, `school_id` | `N:1` with `schools`. `1:N` with `teacher_class_subject`. |
| **`teacher_class_subject`**| `teacher_id`, `class_section_id`, `subject_id`, `weekly_load` | **Assignment Matrix**: Links `teachers` to specific `class_sections` and `subjects`. |

---

## 3. Educational/App Database Structure (`edulearn_app`)

### 3.1 Content & Curriculum
| Table | Key Fields | Relationships |
| :--- | :--- | :--- |
| **`class_modules`** | `id`, `name`, `class_section_id`, `subject_id` | `1:N` with `lessons`. (Links back to CMS `class_sections`). |
| **`lessons`** | `id`, `teacher_id`, `class_module_id`, `title`, `status`, `published_at` | `N:1` with `class_modules`. `1:N` with `lesson_blocks`. |
| **`lesson_blocks`** | `id`, `lesson_id`, `type` (video/text/pdf), `content`, `position` | `N:1` with `lessons`. |

### 3.2 Assessment System
| Table | Key Fields | Relationships |
| :--- | :--- | :--- |
| **`lesson_exercise_sets`** | `id`, `lesson_id`, `title`, `passing_score` | `1:1` or `1:N` with `lessons`. `1:N` with `questions`. |
| **`exercise_questions`** | `id`, `exercise_set_id`, `question_text`, `points` | `N:1` with `exercise_sets`. `1:N` with `options`. |
| **`exercise_options`** | `id`, `question_id`, `option_text`, `is_correct` | `N:1` with `questions`. |

### 3.3 Student Interaction & Progress
| Table | Key Fields | Relationships |
| :--- | :--- | :--- |
| **`conversations`** | `id`, `school_id`, `type` (support/teacher-student) | `1:N` with `messages`. |
| **`messages`** | `id`, `conversation_id`, `sender_id`, `text`, `attachment_path` | `N:1` with `conversations`. |
| **`student_lesson_progress`**| `student_id`, `lesson_id`, `is_completed`, `last_viewed_at` | Tracks individual student engagement. |
| **`student_exercise_attempts`**| `id`, `student_id`, `exercise_set_id`, `score`, `status` | `1:N` with `student_exercise_answers`. |

---

## 4. Relationship Types Summary
- **One-to-Many (`1:N`)**: The most common type. (e.g., One School has many Students).
- **Many-to-Many (`N:N`)**: Managed via pivot tables. (e.g., Schools have many Subjects, and a Subject can belong to many Schools).
- **Polymorphic**: Used in `messages` where the `sender` can be a Teacher, Student, or Admin.
- **Cross-Connection**: Managed at the application level (e.g., `Lesson` in `app_mysql` references `Teacher` ID from `mysql`).
