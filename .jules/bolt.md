## 2025-05-22 - Optimized Reports Listing N+1 Query
**Learning:** The Reports listing was performing a separate student count query for every class/section pair in a loop, leading to O(N) queries where N is the number of classes. Moving this to a single `groupBy` query with `count(*)` reduced it to 1 query.
**Action:** Use grouped aggregate queries instead of loops with individual counts. When searching across grouped data, use `whereRaw` for combined field matches and `orWhereExists` for matches within the group.
