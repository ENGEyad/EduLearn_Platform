## 2026-04-23 - [N+1 query masking via loadMissing]
**Learning:** Using `loadMissing()` inside Eloquent model accessors (appended attributes) effectively hides N+1 queries from developers, making performance bottlenecks invisible until they hit production scale. While it prevents errors, it's a "lazy-eager" anti-pattern that should be replaced with explicit controller-level eager loading using `with()` or `withCount()`.
**Action:** When auditing models, look for `loadMissing` in accessors. Remove them to expose N+1 issues and fix them at the query source (controller/repository).
