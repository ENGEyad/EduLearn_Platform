## 2026-05-18 - Eager loading attendance rates with withAvg in DashboardAnalyticsService

**Learning:** In `DashboardAnalyticsService::buildOverview`, calculating average attendance for each class section by querying `Student::where('class_section_id', ...)` inside a filter loop caused an N+1 query bottleneck (executing N queries for N sections). Using Laravel's `withAvg('students', 'attendance_rate')` eager loads aggregate section attendance rates directly in the main `ClassSection` query, allowing in-memory filtering. Reusing `$sections->count()` also eliminates a redundant count query.

**Action:** Whenever calculating per-group aggregates over Eloquent collections, use `withAvg` / `withCount` on the parent query instead of executing aggregate queries in loops or repeated counts.
