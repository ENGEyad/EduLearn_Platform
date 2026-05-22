## 2025-05-22 - Optimized Dashboard Analytics N+1 Queries
**Learning:** The `DashboardAnalyticsService::buildOverview` was performing an N+1 query pattern when calculating `lowAttendanceClasses` by calling `Student::where('class_section_id', $section->id)->avg('attendance_rate')` inside a loop over `$sections`. Laravel's `withAvg()` on the initial query can eager-load these aggregates efficiently.
**Action:** Always check for aggregate calculations (count, avg, max, min) inside loops over Eloquent collections and replace them with `withCount()` or `withAvg()` at the query level.
