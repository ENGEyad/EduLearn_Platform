# Bolt's Performance Journal

This journal contains critical codebase-specific performance learnings for EduLearn_Dashboard.

## 2026-03-31 - Optimized ReportsController Class Listing Query Complexity
**Learning:** Returning grouped data (like distinct classes) and calling individual subqueries for each row (like count or search verification on related models/tables) introduces an O(N) database query overhead (N+1 query bottleneck). We can reduce query counts from 22 down to 2 by using standard `groupBy` aggregation, string concatenation checks at database level with `DB::connection()->getDriverName()`, and `orWhereExists` checks.
**Action:** When querying grouped elements, push counts and search logic directly to the DB level via aggregations and subquery existence constraints instead of looping through models.
