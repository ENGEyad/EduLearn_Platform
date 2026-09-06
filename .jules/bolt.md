## 2025-05-18 - Optimized ReportsController::list Search and Grouping
**Learning:** In `ReportsController::list`, grouping class sections in PHP memory forced O(N) query loops for student counts and search subquery filtering. Aggregating directly via SQL `GROUP BY grade, class_section` with `COUNT(*)` and cross-platform driver string concatenation (`getDriverName()`) reduced database queries from 22 down to 1-2.
**Action:** Always push list grouping and counting down to the database layer rather than retrieving base distinct records and running count queries inside PHP foreach loops.
