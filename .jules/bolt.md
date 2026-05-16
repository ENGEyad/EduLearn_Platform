
## 2026-05-16 - Optimize dashboard analytics N+1 queries
**Learning:** Found an N+1 query pattern in `DashboardAnalyticsService::buildOverview` where student attendance was being averaged individually for every class section. This resulted in O(N) queries where N is the number of classes.
**Action:** Use Laravel's `withAvg()` to eager-load averages on the relationship in a single query. Also reused already-fetched collections for counts instead of re-querying the database (e.g., `$sections->count()` instead of `ClassSection::count()`).
