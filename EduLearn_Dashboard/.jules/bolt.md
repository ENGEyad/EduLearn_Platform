
## 2026-06-08 - Dashboard Analytics N+1 Anti-pattern
**Learning:** The dashboard analytics service was calculating class-level aggregates (like attendance average) by iterating through class sections and performing individual queries for each. This resulted in O(N) queries where N is the number of class sections.
**Action:** Use Laravel's `withAvg()`, `withSum()`, or `withCount()` to eager-load aggregates in the initial query. Always check for collection methods (like `->count()`) to reuse already fetched data instead of re-querying the database.
