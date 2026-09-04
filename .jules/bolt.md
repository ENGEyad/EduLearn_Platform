# Bolt's Journal

## 2025-05-15 - Dashboard Analytics N+1 & View Composer Optimization
**Learning:** In `DashboardAnalyticsService`, calculating low attendance classes originally looped over class sections and fired `Student::where('class_section_id', $section->id)->avg('attendance_rate')` for every section, leading to $O(N)$ database queries. Using Eloquent's `withAvg('students', 'attendance_rate')` pre-calculates averages in a single aggregated query, allowing in-memory filtering. Furthermore, wrapping header notification queries in `View::composer('*')` with Laravel 12's `once()` helper prevents query re-execution across multiple Blade partial renders.
**Action:** Always check `View::composer('*')` bindings for `once()` memoization, and replace relationship aggregate loops with `withAvg()` or `withCount()` in query builder chains.
