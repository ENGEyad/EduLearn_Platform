## 2025-02-18 - Optimize Teacher Assigned Student Counting

**Learning:** In Eloquent, calling `$cs->students->count()` accesses the relationship dynamic property which executes `SELECT *` and hydrates all `Student` model instances into memory before counting them in PHP. Using `$cs->students()->count()` executes a fast SQL aggregate `SELECT COUNT(*)`. Additionally, teachers assigned to multiple subjects in the same class section can produce duplicate `classSection` objects in `$teacher->assignments`, inflating student counts unless unique class sections are filtered by ID.

**Action:** Always filter assigned sections by unique `id` and use relationship query builder methods (`$relation()->count()`) instead of collection properties (`$relation->count()`) when calculating counts across model relationships.
