## 2026-05-28 - [N+1 Query in Reports List]
**Learning:** The `ReportsController::list` was performing O(N) queries by fetching student counts in a loop for each class. Additionally, it was doing in-memory filtering for class searches, which is inefficient as the dataset grows.
**Action:** Use `groupBy` with `selectRaw('count(*)')` to fetch aggregates in a single query. Use `whereExists` to move student-based class filtering to the database level. Always check for loops that perform database queries.

## 2026-05-28 - [Multi-Connection Testing in EduLearn_Dashboard]
**Learning:** Migrations in this project often use `Schema::connection('mysql')` or `Schema::connection('app_mysql')`. Standard Laravel test setup for SQLite (`DB_CONNECTION=sqlite`) might fail if these connections are not also overridden to use the sqlite driver.
**Action:** Update `config/database.php` to use environment variables for drivers (e.g., `env('DB_DRIVER', 'mysql')`) and override them to `sqlite` during performance tests to ensure they run in-memory and don't attempt to connect to a missing MySQL server.
