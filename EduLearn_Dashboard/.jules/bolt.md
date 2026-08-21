## 2026-04-28 - Grouped Query Optimization for Per-Section Averages
**Learning:** `DashboardAnalyticsService::buildOverview` computed low-attendance class section counts by executing an individual `Student::where('class_section_id', ...)->avg('attendance_rate')` query inside a `$sections->filter(...)` closure loop. For schools with $N$ class sections, this resulted in $N$ individual database calls ($O(N)$ query complexity).

**Action:** Pre-calculate section-level aggregated metrics (such as average attendance or average scores) using a single grouped database query with `groupBy('class_section_id')->pluck(DB::raw('AVG(col)'), 'class_section_id')`. Lookup results in-memory during collection filtering to keep query counts constant ($O(1)$ database calls regardless of section count).
