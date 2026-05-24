## 2024-05-24 - N+1 in Dashboard Analytics
**Learning:** Calculating aggregate values (like `avg` attendance) inside a loop over collection items (like class sections) causes N+1 queries. Laravel's `withAvg()` is the correct tool to eager-load these aggregates in a single query.
**Action:** Always check for aggregate calculations in loops and use `withAvg()`, `withCount()`, or `withSum()` at the query level.
