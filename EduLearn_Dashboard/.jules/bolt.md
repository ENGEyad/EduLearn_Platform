## 2025-05-15 - [ReportsController::list N+1 Optimization]
**Learning:** The `ReportsController::list` endpoint was executing O(N) queries by fetching distinct class names and then looping through them to count students and perform search matching. Moving the count logic to `groupBy` and `selectRaw`, and moving search logic to `whereExists` subqueries, reduced database queries from 22 to 2 for a 20-class dataset.
**Action:** Always prefer grouped aggregate queries and subqueries over in-memory loops for dashboard-style listing endpoints.

## 2025-05-15 - [Dual Connection Testing in EduLearn_Dashboard]
**Learning:** Laravel's `RefreshDatabase` trait can be unreliable in this project because some migrations use explicit `Schema::connection('app_mysql')` calls while the test runner might be configured for a single `sqlite` connection. This leads to "table already exists" or "connection refused" errors.
**Action:** Use file-based SQLite databases for both `mysql` and `app_mysql` connections in tests, and manually clean up tables in `setUp()` using `Schema::connection(...)->dropAllTables()` followed by a manual `migrate` call.
