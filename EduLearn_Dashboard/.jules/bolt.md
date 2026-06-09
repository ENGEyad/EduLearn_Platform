## 2025-05-15 - [Dashboard N+1 Query Optimization]
**Learning:** The dashboard overview had a significant N+1 bottleneck where class-level attendance averages were being re-queried for every section in the `lowAttendanceClasses` calculation. Additionally, redundant queries for counts and `AiReport` were identified.
**Action:** Use `withAvg()` to eager-load aggregates when fetching collections. Reuse collection counts (`$coll->count()`) instead of re-querying the database (`Model::count()`). Verify gains using `DB::getQueryLog()` in a dedicated performance test.
