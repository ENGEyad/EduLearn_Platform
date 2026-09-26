## 2025-05-18 - Teacher Assigned Students Count Deduplication
**Learning:** In multi-assignment relationships (e.g. `TeacherClassSubject` where a teacher teaches multiple subjects to the same class section), aggregating counts over assignments directly leads to duplicate counts and unnecessary lazy queries on the underlying models.
**Action:** Deduplicate target models/IDs (e.g., `unique('class_section_id')`) prior to performing count aggregations, and prefer preloaded counts or relationLoaded checks over hydrating full Eloquent model instances.
