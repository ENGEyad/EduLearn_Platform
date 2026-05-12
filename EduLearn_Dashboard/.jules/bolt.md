
## 2026-05-12 - Optimizing nested relationship counts
**Learning:** In Laravel, accessing relationship counts on nested models (e.g., $teacher->assignments->classSection->students_count) triggers N+1 queries if not explicitly eager-loaded. Using $this->loadMissing() or $this->relation->count() in model accessors is a common performance anti-pattern that masks these queries.
**Action:** Eager load nested counts using the closure syntax: `with(['nested.relation' => fn($q) => $q->withCount('child')])`. In the model accessor, check if the attribute exists before falling back to a query, and always use the relationship method `relation()->count()` instead of the collection `relation->count()` to avoid loading the entire collection into memory.
