# Bolt's Performance Journal

## 2026-09-12 - Batch pre-fetching for Student Performance Controller
**Learning:** `StudentPerformanceController::show` iterated over subjects and performed per-subject queries for `Lesson`, `StudentLessonProgress`, and `StudentExerciseAttempt` models (including eager-loaded relationships `exerciseSet` and `lesson`), generating $O(N)$ query loops (51 total queries for 8 subjects).
**Action:** Pre-fetch lessons, progress, and exercise attempts in batch `whereIn` queries keyed by `$subjectIds` / `$allLessonIds`, group them by ID in memory, and map them to each subject. This reduced total database queries from 51 down to 16 for 8 subjects.
