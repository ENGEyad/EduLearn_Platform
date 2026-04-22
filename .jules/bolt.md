## 2025-05-15 - [Eager Loading in Model Accessors]
**Learning:** Model accessors that aggregate relationship data (like counts) can cause silent N+1 query problems if not eager-loaded with `withCount` or similar. Even if the relationship itself is eager-loaded, the aggregation query might still fire per model.
**Action:** Always use `withCount` in controllers when an accessor relies on a relationship count, and ensure the accessor checks for the presence of the `_count` attribute before falling back to a query.
