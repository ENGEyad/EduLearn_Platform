## 2025-12-05 - Request-Scoped View Composer Query Memoization with `once()`

**Learning:** Global view composers (e.g. `View::composer('*', ...)`) fire for every rendered Blade view partial and component on a page. Unmemoized database queries inside global view composers lead to repeated DB queries (N times per request where N is the number of rendered partials). Using Laravel's `once()` helper inside the view composer closure memoizes the query result per HTTP request safely without data leaking between users in Octane/Swoole environments.

**Action:** Wrap database queries in global view composers with `once(function () use ($key) { ... })` to guarantee single-execution per request.
