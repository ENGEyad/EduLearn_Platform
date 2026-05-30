# Bolt's Performance Journal

## 2025-05-30 - Optimized Reports and Dashboard Query Performance
**Learning:** The `ReportsController::list` endpoint had an O(N) query bottleneck where N is the number of classes. Fetching class counts and searching students inside a loop created significant overhead. Similarly, `DashboardAnalyticsService` was performing individual queries for every class section to calculate attendance thresholds.
**Action:** Use `groupBy` and `selectRaw('count(*)')` for efficient grouping in the database. Use `withAvg` for pre-calculating related aggregates in a single query. Always double-check controller methods for redundant or duplicate queries (like the `$latestReport` duplication found in `DashboardController`).
