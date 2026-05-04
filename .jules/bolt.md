## 2025-05-04 - N+1 query optimization in Teacher student count
**Learning:** The `Teacher` model's `total_assigned_students` accessor was triggering N+1 queries by calling `$cs->students->count()` for each assigned class. Using `loadMissing()` inside an accessor masks N+1 issues when the model is serialized.
**Action:** Use `withCount('students')` when eager-loading the `classSection` relationship in the controller, and update the accessor to prioritize the pre-loaded `students_count` attribute.
