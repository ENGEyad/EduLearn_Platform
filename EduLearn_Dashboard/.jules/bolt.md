## 2026-08-16 - Dashboard Analytics Query Optimization & View Composer Memoization

**Learning:** `DashboardAnalyticsService::buildOverview` iterated through all class sections to calculate average student attendance, creating an O(N) database query bottleneck. In addition, global view composers in `AppServiceProvider` executed duplicate database queries for header notifications on every rendered Blade view partial.

**Action:**
1. Pre-calculate class section attendance averages in a single grouped database subquery (`Student::whereNotNull('class_section_id')->groupBy('class_section_id')->selectRaw(...)`).
2. Wrap global view composer database calls inside Laravel's `once()` helper so query results are memoized per request lifecycle across sub-views/partials.
3. Use Eloquent subquery instances (`select('id')`) instead of plucking large arrays of IDs into PHP memory.
