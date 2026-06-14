## 2026-06-14 - Optimized Dashboard and Reports List Queries
**Learning:** Found significant N+1 query patterns in `DashboardAnalyticsService::buildOverview` and `ReportsController::list`. Specifically, calculating class-level averages or counts in a loop triggered a query for every class section.
**Action:** Used `withAvg()` to eager-load class averages in a single query and refactored the Reports list to use a single grouped query with `groupBy`, `selectRaw`, and `whereExists` for searching, reducing queries from O(N) to a constant count.
