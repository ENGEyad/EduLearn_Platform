## 2025-05-15 - Optimized ReportsController::list student counts

**Learning:** The `ReportsController::list` method had a classic N+1 query vulnerability where it would fetch distinct classes and then loop through each to perform a separate COUNT query for students. This resulted in O(N) queries, significantly slowing down the reports overview as the number of classes grows. Additionally, in-memory search was inefficient.

**Action:** Replaced the loop with a single grouped query (`groupBy('grade', 'class_section')->selectRaw('count(*) as students_count')`). Moved the search logic (class name matching and student existence checks) into the database using `whereRaw` and `whereExists`. This reduced queries from 12+ (for 10 classes) down to 2 constant queries. Used cross-platform SQL for class name concatenation to support both MySQL (production) and SQLite (testing).
