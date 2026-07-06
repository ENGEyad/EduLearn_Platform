## 2025-07-06 - [ReportsController list N+1 optimization]
**Learning:** In grouped list queries (like ReportsController::list), pushing search filtering on related models to the database level using whereExists instead of in-memory collection filtering maintains O(1) query complexity.
**Action:** Always prefer database-level grouping and filtering for list endpoints.
