## 2025-05-18 - Eager-load Section Attendance Averages to Eliminate N+1
**Learning:** `DashboardAnalyticsService::buildOverview` executed an O(N) query loop fetching individual section attendance averages (`Student::where('class_section_id', ...)->avg()`). Eager-loading `withAvg('students', 'attendance_rate')` on `ClassSection` reduced total overview database queries from 32 down to 11 for 20 class sections.
**Action:** Always check section/group aggregate operations on models and replace per-item loops with Eloquent `withAvg()` or `withCount()` eager aggregates.
