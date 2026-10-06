## 2026-05-18 - Deduplicating assigned class sections in Teacher student count computation
**Learning:** In `Teacher::getTotalAssignedStudentsAttribute()`, iterating over `$this->assignments` without deduplicating class sections caused student counts to be duplicated when teachers are assigned to multiple subjects in the same class section (e.g., Math and Science in Grade 5 - Section A), leading to both inaccurate counts and redundant computations.
**Action:** Deduplicate assigned class sections by ID (`pluck('classSection')->filter()->unique('id')`) before computing student counts.
