# Bolt's Performance Journal

This is Bolt's journal for the EduLearn_Dashboard project, tracking critical performance learnings and optimization patterns.

## 2025-02-18 - [Initial Setup]
**Learning:** Establishing the performance journal for the EduLearn codebase.
**Action:** Always document codebase-specific constraints and optimizations.

## 2025-02-18 - [ReportsController N+1 Query Optimization]
**Learning:** In list views containing groupings (such as distinct classes), performing `count()` and `exists()` checks within an in-memory loop creates severe $N+1$ query overhead. By utilizing Laravel's `selectSub` to eagerly aggregate relations and pushing search criteria directly to the database level using `orWhereExists` and platform-agnostic string concatenation, we can fully collapse $O(N)$ query loops down to exactly $O(1)$ query complexity.
**Action:** Always prefer database-level subqueries (`selectSub`) and conditional concatenation over iterating and querying inside PHP `foreach` loops.
