# Bolt's Journal

## 2025-02-28 - Optimizing Dashboard Analytics low-attendance classes query
**Learning:** In `DashboardAnalyticsService::buildOverview`, filtering class sections to find low-attendance classes executed an N+1 query (`Student::where('class_section_id', $section->id)->avg('attendance_rate')`) inside a `filter()` callback for every section. Eager-loading `withAvg('students', 'attendance_rate')` on `ClassSection` retrieves section-level attendance aggregates in the initial query, allowing in-memory filtering and reducing query count from `O(N)` down to `O(1)`.
**Action:** Use `withAvg()` / `withCount()` when aggregating child models across collection queries rather than querying child models inside collection filters.
