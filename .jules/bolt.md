
## 2025-05-18 - Optimize Teacher Student Count Aggregation
**Learning:** In `Teacher::getTotalAssignedStudentsAttribute`, iterating through teacher assignments without deduplicating class section IDs led to duplicate student counting when a teacher taught multiple subjects to the same section. Furthermore, accessing `$cs->students` hydrated all Student models into memory rather than performing a lightweight `COUNT(*)` database query.
**Action:** Unique class sections by `id` prior to summing student counts and use `$cs->students()->count()` for aggregate query execution.
