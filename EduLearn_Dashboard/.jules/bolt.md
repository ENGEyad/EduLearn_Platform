## 2026-06-23 - [Optimization: ReportsController list N+1 query]
**Learning:** The `ReportsController::list` endpoint was performing O(N) queries by counting students for each class section in a loop. Moving this logic into a single database query using `groupBy` and `selectRaw` dramatically improves performance. Additionally, search logic was moved into the database using `whereExists` to avoid in-memory filtering of large collections.
**Action:** Always look for loops performing database counts or existence checks and replace them with grouped queries or subqueries.
