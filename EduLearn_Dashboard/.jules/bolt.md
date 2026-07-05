
## 2026-07-05 - [Redundant View Composer Queries]
**Learning:** Using a wildcard '*' in View::composer triggers the callback for every partial and component rendered in the request. If the callback performs DB queries, it leads to massive N+1-like overhead at the view layer.
**Action:** Always target specific layout files in View::composer if the data is global to a layout, and use request-level memoization (e.g., static variables) to ensure the DB is only hit once per request.
