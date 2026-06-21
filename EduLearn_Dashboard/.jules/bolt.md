## 2025-05-14 - [ReportsController N+1 and Memory Filtering]
**Learning:** The `ReportsController::list` method was performing N+1 queries by counting students for each class in a loop. Additionally, search filtering was happening in memory, forcing the application to fetch all classes before discarding those that didn't match.
**Action:** Use `groupBy` and `selectRaw('count(*)')` to aggregate counts in the main query. Move search logic into the database using `whereExists` and `whereRaw` for cross-driver string concatenation.
