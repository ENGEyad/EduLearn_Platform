## 2025-05-15 - N+1 query loop in ReportsController::list
**Learning:** The `ReportsController::list` endpoint was performing separate count and search queries for each class group in a PHP loop, leading to $O(N)$ database hits where $N$ is the number of classes.
**Action:** Use SQL `groupBy` and `count(*)` to aggregate data in a single query. Push search logic (including existence checks for related models) into the database using `whereExists` and driver-aware string concatenation to maintain $O(1)$ query complexity.
