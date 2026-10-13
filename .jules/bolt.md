
## 2026-05-01 - Deduplicating class sections & using direct aggregate count queries in Teacher model
**Learning:** Accessing `$cs->students->count()` on Eloquent models without eager loading hydrates all student records into memory. Furthermore, teachers assigned to multiple subjects in the same class section were causing duplicate section count aggregations.
**Action:** Deduplicate assigned class sections by ID (`unique('id')`) and use `$cs->students()->count()` to issue lightweight SQL aggregate counts when `students_count` is absent.
