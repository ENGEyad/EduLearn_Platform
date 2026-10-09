## 2025-05-18 - Deduplicating Class Section Aggregation in Teacher Model
**Learning:** In `Teacher::getTotalAssignedStudentsAttribute`, iterating directly over `$teacher->assignments` causes duplicate student count aggregations when a teacher is assigned multiple subjects within the same class section.
**Action:** Always filter and deduplicate class sections by `id` using `->map(fn($as) => $as->classSection)->filter()->unique('id')` before summing student counts to prevent incorrect statistical outputs and redundant query/calculation operations.
