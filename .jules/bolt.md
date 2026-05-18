## 2026-05-18 - [N+1 Query Optimization in Student Performance]
**Learning:** The `StudentPerformanceController::show` method suffered from a multi-level N+1 query problem, fetching lessons, progress, and attempts individually for each subject. This resulted in $5N$ queries where $N$ is the number of subjects.
**Action:** Use bulk-fetching (`whereIn`) for all related records across all subjects before the loop, and then group/filter the resulting collections in-memory. This reduces complexity to a constant 5 queries regardless of the number of subjects.
