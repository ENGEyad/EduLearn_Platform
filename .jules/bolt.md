
## 2026-04-24 - [N+1 Query in Teacher Assignments]
**Learning:** The Teacher model's `total_assigned_students` accessor triggered an N+1 query problem by calling `count()` on the `students` relationship of each assigned `classSection`. Even if assignments were eager-loaded, the student counts for those sections were not, leading to one query per assignment.
**Action:** Use `withCount('students')` on the `classSection` relationship when eager-loading assignments in the controller. This allows the model's accessor to use the pre-loaded `students_count` attribute, reducing query count from O(N) to O(1).
