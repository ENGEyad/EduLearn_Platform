# Bolt's Journal

## 2026-05-14 - [Dashboard Analytics N+1 Eager Loading and Group-By Optimization]
**Learning:** In Laravel dashboard analytics or report-heavy components, calculating section aggregates (such as section average attendance rate) can easily lead to severe O(N) N+1 query loops. Pre-calculating aggregates via group-by queries on the student model and mapping in memory completely avoids these queries. Additionally, reusing loaded collections (like count of sections) avoids extra database aggregate hits.
**Action:** Always pre-calculate and group child records (e.g., avg attendance/score per class) in a single unified group-by query or via eager-loaded relations (`withAvg`, `withCount`) before filtering/looping over them.
