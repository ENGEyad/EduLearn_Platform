## 2026-04-11 - Identified N+1 in ReportsController::list
**Learning:** The ReportsController::list endpoint currently iterates through classes and performs a count query for each, leading to O(N) queries where N is the number of distinct classes.
**Action:** Replace the loop with a single grouped Eloquent query and consolidate search logic into the database query.
