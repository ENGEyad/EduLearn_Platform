
## 2026-05-09 - Optimized List Aggregations & N+1 in Accessors
**Learning:** Using `loadMissing()` inside Eloquent accessors (`$appends`) effectively hides N+1 queries from performance profiling until the dataset grows. Nested relationship counts (e.g., Teacher -> Assignments -> ClassSection -> Students Count) require explicit eager loading using closures in `with()`.
**Action:** Always prefer `withCount()` at the controller level and check if accessors are using relationships. Replace `$model->relation->count()` (collection load) with `$model->relation()->count()` (direct query) in fallback paths.
