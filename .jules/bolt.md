## 2026-05-06 - Optimized ReportsController list query
**Learning:** The `ReportsController::list` endpoint had an N+1 query bottleneck where it iterated through all classes and performed a count query for each. Additionally, search filtering was performed in-memory, which is inefficient for large datasets.
**Action:** Refactor aggregate listings to use `groupBy` and `count(*)` in a single database query. Use `whereExists` for searching against related records (like students in a class) to keep filtering logic within the database.
