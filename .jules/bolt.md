## 2026-03-31 - Deduplicate Class Sections in `Teacher::getTotalAssignedStudentsAttribute`
**Learning:** When a teacher is assigned to multiple subjects in the same class section (e.g. Math and Science for Grade 1 - A), iterating over `$teacher->assignments` without deduplicating class sections causes duplicate aggregation of student counts.
**Action:** Deduplicate `classSection` models by `id` using `unique('id')` on the mapped collection before summing student counts in `Teacher::getTotalAssignedStudentsAttribute()`.
