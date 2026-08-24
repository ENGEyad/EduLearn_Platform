## 2025-05-24 - Pre-calculating group aggregates to eliminate N+1 in Dashboard Analytics
**Learning:** In `DashboardAnalyticsService::buildOverview`, calculating low-attendance classes by querying `Student::where('class_section_id', ...)->avg('attendance_rate')` inside a `$sections->filter(...)` closure caused an O(N) database query bottleneck (N+1 queries for each class section).
**Action:** Pre-calculate attendance averages for all sections in a single `groupBy('class_section_id')` query and look up results in memory.
