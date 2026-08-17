# Bolt Performance Journal

## 2025-05-18 - Optimized ReportsController::list Query Loop
**Learning:** The `ReportsController::list` endpoint fetched distinct class sections and then iterated over each class section in memory, performing individual `Student::where(...)->count()` and `->exists()` database queries for each class. For 20 classes, this resulted in 22+ queries (and 42+ queries when performing search filtering).
**Action:** Replace the in-memory iteration and per-class database queries with a single database query using `select('grade', 'class_section', DB::raw('COUNT(*) as students_count'))` grouped by `grade` and `class_section`. For search filtering, use cross-platform string concatenation (`grade || ' - ' || class_section` on SQLite/PgSQL vs `CONCAT` on MySQL) and an `orWhereExists` subquery (`students as s_inner`) to perform matching directly in SQL. This reduced queries from 22 down to 2 for a full listing and 42 down to 3 for search filtering.
