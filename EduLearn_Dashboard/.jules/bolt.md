# Bolt Performance Journal

## 2026-05-15 - [ReportsController::list N+1 query optimization]
**Learning:** Checking student counts and searching across classes was originally done in a loops fetching individual count queries (N+1 queries). By using `groupBy` and database-level search via subqueries (`orWhereExists`), we can retrieve the count of students directly in a single database query.
**Action:** Replaced in-memory loops and individual queries with a clean database-level group by count and optimized subqueries.
