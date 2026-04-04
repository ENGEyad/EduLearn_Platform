## 2025-05-15 - [Database Agnostic Concatenation]
**Learning:** Using `||` for string concatenation works in SQLite/PostgreSQL but fails in MySQL unless `PIPES_AS_CONCAT` is enabled. In Laravel, it's safer to use `CONCAT()` or check the driver name.
**Action:** Use `DB::connection()->getDriverName()` to switch between `||` and `CONCAT()` when writing raw SQL for concatenation to ensure compatibility across dev (SQLite) and prod (MySQL) environments.

## 2025-05-15 - [N+1 in Grouped Lists]
**Learning:** Identifying N+1 queries in loops that perform `count()` or `exists()` on grouped data.
**Action:** Use `groupBy()` with `selectRaw('count(*)')` and `whereExists()` to collapse multiple queries into a single efficient database call.
