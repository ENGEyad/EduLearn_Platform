## 2025-06-20 - [Optimized ReportsController::list N+1 queries]
**Learning:** O(N) queries in `ReportsController::list` were caused by counting students for each distinct class in a PHP loop. Additionally, search logic was performed in-memory, leading to even more queries.
**Action:** Use `groupBy` and `selectRaw('count(*) as students_count')` to handle counting in the primary query. Move search logic to the database using `whereExists` and `whereRaw` with driver-specific concatenation logic to maintain single-query performance.
