## 2025-05-20 - Dashboard N+1 Query Anti-pattern
**Learning:** The dashboard analytics was performing a separate `avg()` query for each class section within a PHP `filter()` loop to identify low-attendance classes. This resulted in an N+1 query pattern where $N$ is the number of classes.
**Action:** Use Eloquent's `withAvg('relationship', 'column')` to eager-load averages in a single query when fetching parent models.

## 2025-05-20 - Missing Eloquent Factories
**Learning:** Many core models (School, ClassSection, Student, Subject, StudentExerciseAttempt) in the `EduLearn_Dashboard` project lack Eloquent factories, causing `factory()->create()` to fail in tests.
**Action:** Use `Model::create([...])` directly in test setup or create the missing factories if many tests require them.
