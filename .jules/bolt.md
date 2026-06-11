## 2026-05-10 - Bulk optimization for Lesson saving
**Learning:** Saving complex models with multiple related children (blocks, exercises, options) using individual `save()` calls in a loop creates a significant N+1 write bottleneck. Using bulk `insert()` for child records drastically reduces query counts. Also, `clone` on a null value in PHP 8.3+ triggers a fatal error.
**Action:** Always prefer bulk `insert()` for child collections when Eloquent events are not required. Ensure null checks before using `clone` on model properties that might be null.
