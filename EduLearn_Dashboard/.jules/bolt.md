# Bolt's Performance Journal - EduLearn Dashboard

## 2026-05-14 - [Optimize ReportsController class section list]
**Learning:** Checking class existences and student counts in an in-memory loop creates a severe N+1 query problem that scales poorly with the number of classes/sections and students. Grouping by grade and class_section at the database level and counting/filtering there dramatically reduces database load.
**Action:** Use database-level `groupBy('grade', 'class_section')`, `selectRaw('count(*) as students_count')`, and cross-platform concatenation matching or `whereExists` subqueries to execute everything in exactly 2 queries.
