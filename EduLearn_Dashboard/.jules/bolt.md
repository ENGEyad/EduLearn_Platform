## 2025-05-20 - Deduplicating Class Sections in Teacher Total Students Calculation
**Learning:** `Teacher::getTotalAssignedStudentsAttribute` was summing `students_count` across all assignment records without deduplicating class sections. When a teacher is assigned multiple subjects in the same class section, student totals were being multiplied, and un-preloaded relationship access was risking O(N) queries.
**Action:** Deduplicate assigned `ClassSection` models by `id` prior to summing student counts, and use `count()` fallback query instead of loading full model collections.
