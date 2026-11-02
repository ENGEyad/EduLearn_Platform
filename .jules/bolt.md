# Bolt's Performance Journal

Critical learnings only.

## 2026-10-10 - Eloquent Model Accessors & Unit Testing Without Dual-Database Migrations
**Learning:** Testing Eloquent models and accessors (such as `Teacher::getTotalAssignedStudentsAttribute`) does not require hitting real database connections or running dual migrations (`mysql` and `app_mysql`) when relationships and attributes are mocked using `$model->setRelation(...)` or `withCount`.
**Action:** For model accessors and collection transforms, unit test in isolation by mocking relation collections on instantiated models.
