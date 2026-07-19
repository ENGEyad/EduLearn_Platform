## 2026-04-05 - Request-scoped Wildcard View Composer Memoization
**Learning:** Wildcard (`*`) view composers run for every single partial view or layout blade block rendered within a request. Placing query logic inside them causes N+1 database queries to scale exponentially with view complexity. Using Laravel's global `once()` helper cleanly and safely binds query execution to once per request scope.
**Action:** Always memoize queries located in globally or broadly scoped View Composers or middleware using `once()` or class-level request state to avoid high layout N+1 overhead.
