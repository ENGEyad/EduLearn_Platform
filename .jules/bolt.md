## 2026-05-29 - Dashboard Analytics N+1 Optimization
**Learning:** The dashboard overview was suffering from an N+1 query pattern where student attendance averages were being queried per class section to identify "low attendance classes". Additionally, redundant database counts and duplicate controller queries were adding unnecessary overhead.
**Action:** Use `withAvg()` to eager-load aggregates on collections and reuse already fetched collections for counts. Always check for duplicate queries in controllers during profiling.
