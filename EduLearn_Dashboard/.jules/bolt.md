# Bolt Journal - Learnings

## 2026-05-13 - Batch attendance averages calculation for sections in DashboardAnalyticsService
**Learning:** In `DashboardAnalyticsService::buildOverview`, filtering `$sections` to count low attendance classes ran `Student::where('class_section_id', ...)->avg('attendance_rate')` inside a loop, causing $N$ queries for $N$ sections.
**Action:** Replace the loop with a single `GROUP BY class_section_id` query on the `Student` model using `pluck(\DB::raw('AVG(attendance_rate)'), 'class_section_id')` to pre-calculate averages, reducing total database queries from 32 down to 13.
