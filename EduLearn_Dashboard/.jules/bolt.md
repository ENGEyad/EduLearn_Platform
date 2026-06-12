## 2026-06-12 - [Dashboard N+1 Optimization]
**Learning:** The `DashboardAnalyticsService::buildOverview` was performing a separate query for each class section to calculate average attendance, leading to an O(N) database query pattern.
**Action:** Use Laravel's `withAvg('relation', 'column')` to eager-load these aggregates in a single query when fetching the parent models.

## 2026-06-12 - [Multi-Connection SQLite Testing]
**Learning:** In a Laravel environment with multiple database connections (e.g., `mysql` and `app_mysql`), standard `RefreshDatabase` might not handle the secondary connection correctly. Additionally, some migrations might explicitly hardcode a connection, causing them to run even if a different `--database` flag is passed.
**Action:** When testing, ensure both `DB_DRIVER` and `APP_DB_DRIVER` are set to `sqlite` and use absolute paths for the database files to avoid resolution issues across different execution contexts.
