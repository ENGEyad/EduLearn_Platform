
## 2026-06-30 - Optimized Grouped Search in Reports
**Learning:** In Laravel, when performing a search on a grouped result set (e.g., counting students per class), it's more efficient to move the search logic to the database using `orWhereExists` rather than filtering in-memory PHP collections. Additionally, cross-platform string concatenation requires checking `DB::getDriverName()` (`||` for SQLite/PgSQL vs `CONCAT` for MySQL).
**Action:** Use `groupBy` with `selectRaw('count(*)')` for summary lists and push complex sub-filtering into `whereExists` clauses to maintain O(1) query performance relative to the number of items.
