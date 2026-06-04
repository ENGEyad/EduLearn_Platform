## 2025-05-15 - Optimized ReportsController::list N+1 queries
**Learning:** O(N) query patterns in class listing (where N is number of classes) significantly degrade performance as the school grows. Replacing manual loops with `groupBy` and `selectRaw` for counts, and utilizing `orWhereExists` for cross-model searching, maintains O(1) database query performance.
**Action:** Always prefer grouped database queries and subqueries over in-memory collection filtering and per-item database hits for aggregate listings.
