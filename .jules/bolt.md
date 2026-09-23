## 2025-05-18 - Deduplicate Class Sections in Teacher Total Students Calculation
**Learning:** `Teacher::getTotalAssignedStudentsAttribute` was aggregating student counts across all teacher assignments without deduplicating class sections. When a teacher was assigned multiple subjects within the same class section (e.g., Math and Physics in Grade 10-A), students were counted multiple times, skewing metrics and causing unnecessary processing.
**Action:** Extract unique `ClassSection` models by `id` from `$this->assignments` before computing total student counts in model accessor attributes.
