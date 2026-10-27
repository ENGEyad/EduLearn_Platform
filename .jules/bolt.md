## 2025-02-18 - Dashboard Analytics Section Attendance Aggregation Optimization

**Learning:** `ClassSection` low attendance calculation was performing `Student::where('class_section_id', $section->id)->avg('attendance_rate')` inside a collection `filter()` closure for every section, causing an N+1 query loop. Additionally, `View::composer('*')` in `AppServiceProvider` ran un-memoized database queries for header notifications on every sub-view render.

**Action:** Eager load `students_avg_attendance_rate` on the initial `ClassSection` query using Eloquent's `withAvg('students', 'attendance_rate')` and use `once()` in Blade view composers for request-scoped memoization.
