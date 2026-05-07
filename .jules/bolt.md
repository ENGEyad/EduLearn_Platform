## 2025-05-07 - Optimized Reports List N+1 Query
**Learning:** The `ReportsController::list` endpoint was executing one query to fetch distinct classes and then separate queries for each class to count students and check for search matches, leading to an N+1 problem (21+ queries for 20 classes).
**Action:** Use `groupBy` with `selectRaw('count(*)')` and `orWhereExists` for searching across relationships to collapse the logic into a single database query.
