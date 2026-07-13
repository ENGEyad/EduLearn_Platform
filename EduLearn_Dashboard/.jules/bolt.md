
## 2026-07-13 - [N+1 Query in ReportsController::list]
**Learning:** The `ReportsController::list` endpoint was performing O(N) queries where N is the number of classes, due to counting students in a loop. Additionally, in-memory search was triggering even more queries via `exists` checks.
**Action:** Use `groupBy` with `selectRaw('count(*)')` to fetch counts in the main query. Push search logic to the database using `whereExists` and `whereRaw` (handling driver-specific concatenation) to maintain O(1) query complexity regardless of list size.
