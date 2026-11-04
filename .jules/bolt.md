# Bolt's Performance Journal

## 2026-05-13 - Request-Scoped Memoization with Laravel once() in View::composer
**Learning:** `View::composer('*', ...)` triggers on every single rendered view, layout, and partial during a request lifecycle. Executing database queries directly inside wildcard view composers causes severe N+1 query multiplication when views render multiple components or sub-views. Using `static` variables inside closures risks cross-request state leakage in Octane/Swoole environments. Laravel's built-in `once()` helper provides safe, request-scoped memoization.
**Action:** When data must be shared across views via `View::composer('*', ...)`, always wrap the query fetch logic inside `once(fn() => ...)` to ensure it executes exactly once per HTTP request lifecycle.
