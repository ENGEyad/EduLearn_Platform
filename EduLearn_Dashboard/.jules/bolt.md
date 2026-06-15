## 2026-06-15 - Dashboard N+1 Optimization

**Learning:** The `DashboardAnalyticsService::buildOverview` method had a significant N+1 query bottleneck when calculating `lowAttendanceClasses`. For each class section, it executed a separate `avg()` query on the `students` table. consolidated this using `withAvg('students', 'attendance_rate')` on the initial `ClassSection` query.

**Action:** Always check for aggregate calculations inside collection filters/loops and use Eloquent's `withCount`, `withAvg`, `withSum`, etc., to eager-load these values in a single query.

## 2026-06-15 - Redundant Query Patterns

**Learning:** Identified a pattern in `DashboardController` where the same Eloquent query for `AiReport` was executed twice consecutively. This was likely a copy-paste error during development.

**Action:** Peer-review controller logic for redundant model fetches, especially when multiple people are working on the same file. Reusing already fetched variables is a zero-cost performance win.
