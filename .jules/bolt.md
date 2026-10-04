## 2025-05-20 - Subquery Aggregation vs Loop Database Calls in Dashboard Analytics
**Learning:** Calculating section-level averages inside a collection loop like `$sections->filter(...)` causes an N+1 query explosion. Using Eloquent's `withAvg('students', 'attendance_rate')` pre-calculates section attendance averages via a single subquery on the primary query, eliminating up to N queries.
**Action:** When calculating statistics across grouped models or sections, leverage Eloquent's `withAvg` and `withCount` subqueries instead of querying in collection filters.
