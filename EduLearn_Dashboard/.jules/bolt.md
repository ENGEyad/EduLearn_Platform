# Bolt's Performance Journal

This journal tracks critical codebase-specific performance insights.

## 2026-07-30 - Dynamically Overriding Dual Connections in SQLite Tests
**Learning:** In projects that use multiple databases/connections (e.g., `mysql` and `app_mysql`), running SQLite migrations in-memory during testing causes "Connection refused" or missing connection errors because migrations reference those connection names.
Overriding connection configurations dynamically within the test case bootstrap (`tests/TestCase.php::createApplication`) perfectly points both connections to SQLite without altering any migration source code.
**Action:** Use `$sqliteConfig = config('database.connections.sqlite'); config(['database.connections.mysql' => $sqliteConfig, 'database.connections.app_mysql' => $sqliteConfig]);` inside `createApplication()` to enable flawless SQLite-based test runs.

## 2026-07-30 - Eliminating N+1 Query Loops in Reports List
**Learning:** Retrieving lists of groups (e.g., unique class sections) and then looping through them in memory to run sub-queries (e.g., student counts and exists searches) leads to severe O(N) database-hit scalability bottlenecks.
By grouping the base query on the database level (`groupBy('grade', 'class_section')`) and leveraging database-level subqueries (`orWhereExists()`), query count is reduced from 22 down to 2, and remains O(1) regardless of list size.
**Action:** Use database-level aggregations and exists subqueries instead of looping over Eloquent collections.
