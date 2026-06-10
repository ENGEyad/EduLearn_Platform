# Bolt's Performance Journal ⚡

## 2026-06-10 - Dashboard Analytics N+1 Optimization
**Learning:** The `DashboardAnalyticsService::buildOverview` method had a significant N+1 query bottleneck when calculating `lowAttendanceClasses`, as it performed a separate `avg()` query for each class section. Additionally, the dashboard index was performing a redundant duplicate query for the latest AI report.
**Action:** Use Laravel's `withAvg('students', 'attendance_rate')` to eager-load averages in a single query and reuse existing collections (`$sections->count()`) for basic stats.
