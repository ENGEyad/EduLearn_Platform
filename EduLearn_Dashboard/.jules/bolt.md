## 2026-05-15 - Student Performance Report N+1 Optimization
**Learning:** The `StudentPerformanceController::show` method had a 3N+2 query complexity where N is the number of subjects. For a student with 10 subjects, this resulted in 32+ queries (plus framework overhead). Bulk fetching Lessons, Progress, and Attempts reduced this to a constant number of queries regardless of subject count.
**Action:** Always bulk-fetch related data before loops in report controllers. Use `orderBy` in the DB query rather than `sortBy` on collections when possible.
