## 2025-05-15 - [Dashboard Analytics N+1 Optimization]
**Learning:** Found a major N+1 query bottleneck in `DashboardAnalyticsService::buildOverview` where average attendance was being calculated individually for every class section in a loop. Re-querying the database for counts already available in collections also added unnecessary overhead.
**Action:** Use Laravel's `withAvg()` to eager-load aggregate averages on relationships and reuse existing collection counts (`$collection->count()`) instead of trigger new database count queries.

## 2025-05-15 - [Redundant Controller Queries]
**Learning:** `DashboardController::index` had a duplicate query for `AiReport`, causing double the database hits for the same data.
**Action:** Always scan for copy-paste residue or redundant queries in controllers, especially when multiple people are working on the same file.
