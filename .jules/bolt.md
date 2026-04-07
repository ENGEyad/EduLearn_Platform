
## 2026-04-07 - [N+1 Student Count in Teacher List]
**Learning:** Found a classic N+1 bottleneck where an appended Model attribute (`total_assigned_students`) was calling `$cs->students->count()` inside a loop. This loaded the full student collection for every class section of every teacher.
**Action:** Always use `withCount()` when eager-loading and prefer the query-based `students()->count()` as a fallback in accessors to avoid hydrating models just for a count.
