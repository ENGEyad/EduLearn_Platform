# Bolt Performance Journal

## 2026-05-14 - Teacher Total Assigned Students Deduplication and Hydration Prevention
**Learning:** In Laravel Eloquent, calling `$relation->count()` when the relationship is not already loaded will execute a database query to hydrate the entire collection of models into PHP memory before calling `Collection::count()`. Furthermore, teachers assigned to multiple subjects in the same class section have multiple assignment records referencing identical class sections, which leads to duplicate computations and inflated student counts.
**Action:** When computing aggregations across relations:
1. Deduplicate by entity key (`unique('id')`) before computing sums.
2. Check `isset($cs->students_count)` or `$cs->relationLoaded('students')` before accessing relation collections.
3. Fall back to the Query Builder aggregate `$cs->students()->count()` rather than dynamic property `$cs->students->count()`.
