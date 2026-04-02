## 2026-04-02 - [N+1 Query in Teacher Model Accessor]
**Learning:** Eager loading relationships in controllers is only half the battle when a model accessor aggregates data from those relationships. If the accessor performs its own counts (e.g., `$cs->students->count()`), it triggers N+1 queries even if the relationship (`classSection`) is eager-loaded. Using `withCount('students')` in the controller and checking for `$cs->students_count` in the accessor is the optimal pattern.
**Action:** Always check if model accessors perform aggregations and use `withCount` in the eager loading chain to optimize them.

## 2026-04-02 - [Database Connection Specificity in Migrations]
**Learning:** Hardcoding connection names like `app_mysql` in migrations is risky as it might not exist in all environments (e.g., CI/testing). Defensively checking for table existence via `Schema::connection('...')` and providing fallbacks or specific error handling is necessary when working with multiple databases.
**Action:** Use defensive checks (`Schema::hasTable`, `Schema::hasColumn`) and be cautious with non-default connections in migrations.
