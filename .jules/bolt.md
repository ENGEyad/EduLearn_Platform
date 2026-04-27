## 2026-04-27 - N+1 in Aggregated Reports
**Learning:** Iterating over grouped collections to perform counts or existence checks creates severe N+1 bottlenecks. Moving these to single grouped SQL queries with sub-queries (whereExists) reduces query volume from O(N) to O(1).
**Action:** Always check for loops executing Eloquent queries inside controllers, especially in dashboard/report list views.

## 2026-04-27 - Multi-connection Test Migrations
**Learning:** Laravel migrations using hardcoded `Schema::connection('mysql')` will fail during tests if ONLY the default connection is swapped to sqlite.
**Action:** Explicitly override all named connections (e.g., 'mysql', 'app_mysql') to use the sqlite driver and ':memory:' database in the test's `setUp` or `refreshTestDatabase` method.
