## 2025-09-01 - Single Aggregate GroupBy Query Prevents Section Attendance N+1 Bottleneck
**Learning:** In `DashboardAnalyticsService::buildOverview`, calculating low attendance class sections previously looped over all `ClassSection` instances and executed an `AVG(attendance_rate)` query per section. Grouping attendance rates by `class_section_id` in a single query eliminates O(N) database calls.
**Action:** Always pre-aggregate nested model metrics using `groupBy` subqueries or single grouped queries when evaluating thresholds across related collections.
