## 2026-04-10 - [Optimization of Reports List and AI Caching]
**Learning:** Replacing an N+1 query loop with a single grouped Eloquent query significantly reduces database load and ensures constant-time complexity for listing operations. Caching external AI responses prevents redundant network overhead.
**Action:** Always prefer grouped aggregations over per-item query loops in controllers. Use hashing of input data for robust cache keys.
