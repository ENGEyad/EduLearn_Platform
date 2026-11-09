# Bolt Performance Journal

## 2026-05-13 - Eager Aggregating Related Averages via withAvg to Eliminate N+1 Queries
**Learning:** In dashboard overview routines where parent models (`ClassSection`) need aggregates of child records (`Student::avg('attendance_rate')`) to count cohorts meeting threshold criteria, filtering with inline subqueries in PHP collection callbacks triggers 1 additional SQL query per parent model (O(N) queries).
**Action:** Use Eloquent's `withAvg('students', 'attendance_rate')` when loading the parent models to fetch the aggregated averages in a single SQL query, then evaluate the threshold against `$section->students_avg_attendance_rate` directly in memory, reducing queries from O(N) to O(1).
