# Bolt's Performance Journal ⚡

## 2026-06-11 - Optimized ReportsController Class Listing

**Learning:** Replaced an O(N) query bottleneck in `ReportsController::list` where student counts and search existence checks were being performed inside a loop for each class. By using `groupBy`, `selectRaw`, and an `orWhereExists` subquery, I reduced the database load from 22-42 queries down to a constant 2 queries for a 20-class dataset. This maintains accurate counts even when searching by student name, as the subquery ensures the whole class group is included if any student matches.

**Action:** Look for `foreach` loops over distinct model sets that trigger secondary queries (count, exists, find). Replace with `groupBy`, `withCount`, or `whereExists` to handle the logic in a single bulk SQL operation.
