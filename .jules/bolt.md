## 2025-05-18 - Optimize ReportsController list N+1 query via SQL Group By
**Learning:** `ReportsController::list` iterated over each class section in PHP to execute `count()` and search checks, leading to 22-42 database queries per request. Using SQL `GROUP BY grade, class_section` with `COUNT(*)` and database-level `whereExists` subqueries reduces queries down to 1-2.
**Action:** Always push class-level aggregations and child existence filtering down to SQL `GROUP BY` and `whereExists` instead of in-memory loop iteration.
