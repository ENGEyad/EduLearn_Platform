## 2025-06-03 - [N+1 Anti-pattern in Dashboard Analytics]
**Learning:** Performing database aggregates (like `avg()`) inside a collection `filter()` or `each()` loop is a common N+1 performance killer in this codebase. It's often overlooked when the parent collection is already fetched.
**Action:** Use Eloquent power-ups like `withAvg()`, `withCount()`, or `withSum()` during the initial query to fetch all required aggregate data in a single SQL statement.
