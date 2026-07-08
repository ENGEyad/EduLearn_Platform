## 2026-07-08 - [Optimizing Grouped Lists and Redundant Queries]
**Learning:** Iterating over distinct groups to perform counts or related searches causes N+1 bottlenecks. In the ReportsController, the O(N) query pattern was fetching distinct classes and then querying each for student counts and search matches.
**Action:** Use database-level `groupBy` with aggregate `count(*)` and push search logic into the database using `whereExists` for related model checks. This reduced query count from 21+ down to 2 for a standard 20-class view.
