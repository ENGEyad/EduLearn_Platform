## 2025-05-21 - [Dashboard Analytics N+1 Optimization]
**Learning:** Found an N+1 query pattern in `DashboardAnalyticsService::buildOverview` where average attendance was being queried individually for every class section.
**Action:** Used `withAvg('students', 'attendance_rate')` to eager-load class averages in a single query.

## 2025-05-21 - [Dual-Connection Testing with SQLite]
**Learning:** Using `:memory:` databases with `migrate:fresh` across multiple connections in a single test can be problematic if migrations hardcode `Schema::connection('name')`.
**Action:** Use file-based SQLite for tests involving multiple connections to ensure proper isolation and persistence during the test lifecycle.
