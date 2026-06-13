## 2026-06-13 - [N+1 Query in Dashboard Overview]
**Learning:** The `DashboardAnalyticsService::buildOverview` method was executing a separate query for each `ClassSection` to calculate its average attendance rate when determining `lowAttendanceClasses`. This resulted in O(N) queries where N is the number of sections. Additionally, the same method was executing an extra `ClassSection::count()` query even though the sections were already fetched into a collection.

**Action:** Use Laravel's `withAvg('relation', 'column')` to eager-load averages in a single query. Reuse existing collections for counting (e.g., `$sections->count()`) instead of re-querying the database. Always check if data already fetched into memory can satisfy multiple statistics.
