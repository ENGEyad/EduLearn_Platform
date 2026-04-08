## 2026-04-08 - [Optimized Grouped Query for Reports]
**Learning:** A common performance bottleneck in reports that aggregate data (e.g., student counts per class) is an N+1 query pattern where the app first fetches distinct groups and then performs a separate query for each group to get its count. This can be significantly optimized by using a single query with `GROUP BY` and `count(*)`.

**Action:** Always prefer grouped database queries for aggregate reports instead of looping through unique identifiers and executing individual count queries. Use `DB::connection()->getDriverName()` to handle database-specific syntax (like string concatenation) when writing raw query parts.
