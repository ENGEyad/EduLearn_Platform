# Bolt's Performance Journal

## 2026-03-31 - Dual Connection Testing & Cross-Platform SQLite/MySQL Group By Optimizations
**Learning:**
1. In `ReportsController::list`, counting student records across multiple class segments triggered an N+1 query loop. Moving the count directly into a `groupBy('grade', 'class_section')` query resolved the bottleneck completely.
2. Cross-platform SQL string concatenation behaves differently in SQLite (using `||`) and MySQL (using `CONCAT`). We dynamically detected the database engine using `DB::connection()->getDriverName()` to ensure compatibility.
3. Feature tests on dual-connection (mysql/app_mysql) databases can fail on SQLite when tables are queried/created across different connections. Overriding `createApplication()` in `tests/TestCase.php` to dynamically remap `mysql` and `app_mysql` connections to the SQLite configuration resolved all connection issues without altering production models or migration code.

**Action:**
1. Avoid in-memory count filtering on groups. Shift grouping and counting to the database level via Eloquent aggregate queries.
2. Use `DB::connection()->getDriverName()` to branch query builders when concatenating columns dynamically.
3. Use the dynamic configuration override in `TestCase::createApplication()` to mock secondary connections during test suites.
