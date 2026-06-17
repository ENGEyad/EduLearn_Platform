## 2026-06-17 - [Dashboard Analytics N+1 Optimization]
**Learning:** The `DashboardAnalyticsService::buildOverview` method was suffering from an N+1 query problem when calculating `lowAttendanceClasses`. It was performing a separate `avg('attendance_rate')` query for every class section. Additionally, redundant `count()` queries were being executed for data already present in collections.

**Action:** Use `withAvg('students', 'attendance_rate')` when fetching class sections to eager-load averages in a single query. Reuse collection counts (e.g., `$sections->count()`) instead of re-querying the database. Always check for duplicate code blocks in controllers that might be fetching the same model multiple times.
