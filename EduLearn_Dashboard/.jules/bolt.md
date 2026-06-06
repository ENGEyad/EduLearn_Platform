## 2026-06-06 - Optimized Dashboard Analytics Query Performance
**Learning:** Found an N+1 query bottleneck in `DashboardAnalyticsService::buildOverview` where calculating `lowAttendanceClasses` was triggering a separate `AVG(attendance_rate)` query for every class section. Additionally, a redundant `ClassSection::count()` query was being executed when a collection of sections was already available.
**Action:** Use Eloquent's `withAvg()` to eager-load averages for related models in a single query. Always reuse existing collections for counts instead of re-querying the database.
