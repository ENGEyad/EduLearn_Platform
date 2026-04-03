## 2024-05-22 - [Optimizing Relation Counts in Accessors]
**Learning:** Accessing relation counts in model accessors (appended attributes) can cause significant N+1 query overhead in list views. Using `withCount` in controllers and checking for the attribute in the accessor is a standard but powerful optimization. Additionally, calling `$model->relation()->count()` is much more efficient than `$model->relation->count()` as it avoids loading the full collection into memory.
**Action:** Always check if model accessors used in lists can be optimized with `withCount`. Use count queries (`()->count()`) instead of counting loaded collections (`->count()`) when the full models are not needed.

## 2024-05-22 - [Multi-Database Testing with RefreshDatabase]
**Learning:** Laravel's `RefreshDatabase` trait might fail when a migration uses a connection name that isn't configured for testing (e.g., `Connection refused` if it tries to connect to a real MySQL instance). Overriding the connection configuration in the test's `setUp` (or `getEnvironmentSetUp` in some cases) to use SQLite is necessary.
**Action:** When testing models or migrations involving multiple connections, ensure all connections are redirected to a testing-safe driver (like SQLite memory) in the test setup.
