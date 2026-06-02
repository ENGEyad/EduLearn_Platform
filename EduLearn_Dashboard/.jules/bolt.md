## 2026-06-02 - [Dashboard N+1 Optimization]
**Learning:** Found a major N+1 bottleneck in the dashboard analytics overview where low-attendance classes were being calculated by executing a separate aggregate query for every class section.
**Action:** Use Eloquent's `withAvg()` to eager-load averages for related models in a single query when performing aggregate filtering on collections.
