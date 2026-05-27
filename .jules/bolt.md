
## 2025-05-15 - N+1 Query Optimization in ReportsController::list
**Learning:** The `ReportsController::list` method was performing O(N) queries by counting students for each class in a loop, and even more queries when search was active.
**Action:** Use `groupBy` with `selectRaw('count(*)')` to fetch counts in the main query. Use `whereExists` for searching related records (students) without breaking the grouping or adding extra queries. Handle DB-specific syntax (like concatenation) using `DB::connection()->getDriverName()`.
