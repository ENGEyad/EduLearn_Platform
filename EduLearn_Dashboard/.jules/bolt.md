# Bolt's Performance Journal

## 2025-07-02 - Optimized ReportsController::list N+1 Queries
**Learning:** The `ReportsController::list` endpoint had a severe N+1 bottleneck where each class section triggered a separate `count()` query and potentially multiple existence checks during search. Moving the aggregation to the database level using `groupBy` and `selectRaw` combined with `whereExists` for deep relation searching reduced the query count from O(N) to O(1) relative to the number of classes.
**Action:** Always check list endpoints for loops that execute queries per item, and prioritize database-level aggregation and filtering.
