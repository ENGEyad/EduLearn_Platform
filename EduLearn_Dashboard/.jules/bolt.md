## 2025-04-28 - Optimizing Grouped Reports with Search
**Learning:** Using `groupBy` in Laravel for counts eliminates N+1 queries when summarizing data by categories. However, implementing "search" on concatenated fields (like `grade - section`) requires database-specific syntax (SQLite `||` vs MySQL `CONCAT`) or `whereRaw`.
**Action:** Use `DB::connection()->getDriverName()` to handle concatenation syntax differences in a database-agnostic way for filters and searches.

## 2025-04-28 - Testing Multi-Connection Laravel Apps
**Learning:** `RefreshDatabase` in Laravel tests may fail if some migrations or code use `Schema::connection('mysql')` or `on('app_mysql')` and those connections aren't correctly mapped to SQLite in-memory during test setup. Overriding `refreshTestDatabase` and `config()` is necessary.
**Action:** Always ensure all used connections are redirected to `:memory:` and `sqlite` in the test `setUp` or `refreshTestDatabase` method when working with multi-connection environments.
