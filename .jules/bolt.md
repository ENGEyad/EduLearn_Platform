## 2025-05-18 - Deduplicating Relations and Column Attribute Fallbacks in Teacher Model

**Learning:** In `Teacher` model accessors, `optional($as->subject)->name` returned `null` because `Subject` model lacks a `name` column/accessor (using `display_name`, `name_en`, and `name_ar` instead). Furthermore, `getTotalAssignedStudentsAttribute()` iterated over raw `TeacherClassSubject` assignments without deduplicating class sections by ID, causing student counts to be multiplied if a teacher taught multiple subjects to the same section, and calling `$cs->students->count()` when `students_count` was omitted would execute N+1 database queries.

**Action:** Deduplicate relations using `pluck('classSection')->unique('id')` before aggregating child counts, and call relationship query methods `students()->count()` rather than dynamic property accesses when hydrated counts are missing.
