## 2025-05-15 - [N+1 Query in Dashboard Risk Analysis]
**Learning:** Using `filter()` on an Eloquent collection and performing a database query (like `avg()`) inside the closure creates an N+1 query bottleneck. Even if the main query is fast, repeated sub-queries scale poorly with the number of entities (e.g., class sections).
**Action:** Use Laravel's `withAvg()`, `withCount()`, or `withSum()` to eager-load aggregates in the main query. Re-use existing collections (e.g., `$collection->count()`) instead of issuing new `count()` queries to the database.
