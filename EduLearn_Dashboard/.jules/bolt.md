## 2026-06-07 - Optimized Reports and Dashboard Queries
**Learning:** Found N+1 query patterns in class-based reporting and dashboard analytics. Using `groupBy` with `selectRaw` and `withAvg` eager-loading reduced query counts significantly. Reusing already-fetched collections for counts also avoids redundant DB hits.
**Action:** Always use `withCount` and `withAvg` for aggregate data when listing items. Prefer `groupBy` on the DB side over in-memory grouping for large datasets.
