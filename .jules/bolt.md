## 2025-05-15 - [ReportsController Optimization]
**Learning:** Replacing N+1 query loops with grouped Eloquent queries and subqueries (`whereExists`) can reduce database hits from O(N) to O(1). Using `DB::connection()->getDriverName()` allows for database-agnostic string concatenation (SQLite `||` vs MySQL `CONCAT`).
**Action:** Always prefer grouped database operations over in-memory collection processing for large datasets.
