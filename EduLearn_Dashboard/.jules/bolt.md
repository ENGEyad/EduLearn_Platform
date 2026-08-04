# Bolt's Performance Journal

## 2026-05-13 - [N+1 Query Optimization in Reports Class List]
**Learning:** In the `ReportsController::list` endpoint, fetching the class list originally loaded classes and then performed count and exist checks within a loop. This caused O(N) database query scaling, leading to at least 22 queries for 20 classes. By utilizing SQL grouping (`groupBy('grade', 'class_section')`) combined with driver-aware concatenation (e.g. `getDriverName()` for SQLite/MySQL compatibility) and `orWhereExists` for searching, we can resolve this to a single query (O(1)) while keeping 100% logic and data structure correctness.
**Action:** Replace the N+1 count loop with SQL aggregation in `ReportsController::list` and write a feature performance test to monitor query complexity.
