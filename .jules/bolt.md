## 2025-05-18 - Deduplicating Class Sections in Teacher Total Assigned Students Aggregation

**Learning:** When a teacher is assigned to multiple subjects in the same class section (e.g., Math and Science in Section 5-A), iterating over `$teacher->assignments` without deduplicating class sections causes student counts to be multiplied and triggers duplicate queries on `$cs->students` if `students_count` is missing.
**Action:** Deduplicate assigned `classSection` models by `id` using `$this->assignments->map(fn($as) => $as->classSection)->filter()->unique('id')` prior to summing student counts.
