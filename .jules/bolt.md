## 2025-11-20 - Eager Loading Relationship Counts to Fix N+1 Queries
**Learning:** Appended model attributes that perform relationship queries (like `count()`) cause N+1 database issues when listing models. Even if using `loadMissing()` inside the accessor, it still triggers a query per model if the relationship wasn't already eager-loaded with counts.
**Action:** Use `withCount(['relation'])` in the controller's initial query and update the model accessor to prioritize the resulting `relation_count` attribute using `getAttribute('relation_count')` before falling back to a manual count.
