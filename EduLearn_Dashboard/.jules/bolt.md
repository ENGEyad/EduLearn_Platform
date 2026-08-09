# Bolt Performance Journal

## 2026-05-14 - Optimize Class Attendance Calculation in Dashboard Overview
**Learning:** Found an N+1 query vulnerability in `DashboardAnalyticsService::buildOverview()`. Calculating low-attendance classes involved looping through all sections and calling `Student::where('class_section_id', $section->id)->avg('attendance_rate')` individually for each class section.
**Action:** Grouped the calculation into a single query grouping by `class_section_id` and pulling aggregate results via `pluck`, then filtered the classes list in memory. This reduces the number of database queries from O(N) to O(1).
