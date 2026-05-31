## 2026-05-31 - [N+1 Query Optimization in Student Performance & Dashboard]
**Learning:** The `StudentPerformanceController` was performing 3 queries per subject in a loop (Lessons, Progress, Attempts), leading to $3N+2$ queries. Similarly, `DashboardAnalyticsService` was querying attendance averages for each class section individually. Eager loading (`withAvg`, `withCount`) and bulk fetching followed by in-memory collection filtering significantly reduced the query footprint.
**Action:** Always look for loops containing database queries and replace them with eager loading or bulk fetches with in-memory grouping/filtering.

## 2026-05-31 - [SQLite Multi-Connection Testing]
**Learning:** Using `RefreshDatabase` with multiple SQLite connections (e.g., `mysql` and `app_mysql`) can cause migration conflicts or "table already exists" errors if not handled carefully, as migrations might try to run against the same file or in the wrong order.
**Action:** Use distinct file-based SQLite databases for each connection and manually manage migration state or avoid `RefreshDatabase` when cross-connection migrations are complex.
