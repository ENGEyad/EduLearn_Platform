# Bolt's Journal

## 2025-02-18 - Batching Query Fetches in Student Performance Controller
**Learning:** In `StudentPerformanceController::show`, executing `Lesson`, `StudentLessonProgress`, and `StudentExerciseAttempt` queries per subject inside a loop resulted in $3N + 2$ database queries for $N$ subjects. Fetching all items for assigned subject IDs upfront using `whereIn` and grouping results in memory with Laravel Collections reduced total database queries to $5$ static queries regardless of the number of subjects.
**Action:** When calculating per-entity aggregates in controller endpoints, batch-fetch related models using `whereIn` prior to looping and collect/group records in memory.
