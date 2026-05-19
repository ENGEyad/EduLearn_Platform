## 2026-05-19 - Dashboard Analytics Optimization
**Learning:** Found an N+1 query pattern in `DashboardAnalyticsService::buildOverview` where average attendance was being calculated per class section in a loop. Also found redundant DB queries in the controller.
**Action:** Use Laravel's `withAvg()` to eager-load aggregates in a single query. Always check for duplicate query logic in controllers (especially after merge/refactor). Enable query logging on all connections during performance tests to see the full picture.
