# Bolt's Journal

## 2026-03-04 - Memoization of View Composers & Relation Aggregates

**Learning:** Wildcard view composers (`View::composer('*')`) execution is proportional to the number of layout partials and templates loaded in a single request. Eager loading and memoizing queries inside wildcard View composers using Laravel's `once()` helper completely avoids N+1 queries during complex Blade page renders.
**Action:** Always wrap redundant database queries in wildcard or global view composers using the `once()` helper, and eager-load relation counts/averages using Eloquent's `withCount()` and `withAvg()` to keep database interactions flat.
