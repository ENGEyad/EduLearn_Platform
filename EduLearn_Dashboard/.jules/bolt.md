## 2025-06-19 - [N+1 Query Optimization in Dashboard Analytics]
**Learning:** The `DashboardAnalyticsService::buildOverview` calculation of `lowAttendanceClasses` used a collection filter with an internal database query, causing N+1 performance degradation.
**Action:** Use `withAvg('relation', 'column')` to eager-load aggregates into a dynamic property (e.g., `relation_avg_column`), allowing for high-performance in-memory collection filtering.

## 2025-06-19 - [Redundant Query in Dashboard Controller]
**Learning:** Found a duplicate Eloquent query in `DashboardController::index` fetching the exact same `AiReport` record twice.
**Action:** Always scan for repeated query patterns in controllers, especially when multiple people are contributing to the same method.

## 2025-06-19 - [Testing with Multiple SQLite Connections]
**Learning:** Migration files with hardcoded `Schema::connection('app_mysql')` make it difficult to switch to SQLite for testing without modifying migrations.
**Action:** When testing, use a temporary `config/database.php` override to point `app_mysql` driver to `sqlite`, but revert these changes before PR to avoid codebase churn.
