## 2026-07-01 - Optimized Dashboard Analytics Overview

**Learning:** Found an N+1 query pattern in `DashboardAnalyticsService::buildOverview` where average attendance was being calculated per-class in a loop. Also identified redundant queries for class counts and student counts.

**Action:** Used `withAvg('students', 'attendance_rate')` to eager-load the average at the database level and reused the existing `$sections` collection for counts. This reduced queries from 18 to 7 for a 10-class dataset.
