## 2025-05-14 - Optimized Reports class listing performance
**Learning:** Consolidating aggregation and search logic into a single database query using `groupBy` and `whereExists` eliminates N+1 query bottlenecks in report listings.
**Action:** Always check for loops that perform database queries or `exists()` checks; refactor them into a single query with subqueries or joins for O(1) performance.
