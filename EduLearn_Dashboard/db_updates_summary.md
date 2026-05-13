# Database Updates Summary - Branch Management Feature

**Date:** 2026-04-04
**Phase:** Phase 1 — Database Migrations

---

## Migrations Executed

| File | Status | Description |
|---|---|---|
| `2026_04_04_214621_add_branch_fields_to_schools_table` | ✅ Ran | Adds `parent_school_id` to schools |
| `2026_04_04_214648_add_branch_fields_to_users_table` | ✅ Ran | Adds branch auth fields to users |
| `2026_04_04_214649_create_branch_permissions_table` | ✅ Ran | New granular permissions table |

---

## Schema Changes

### Table: `schools`

| Column | Type | Default | Notes |
|---|---|---|---|
| `parent_school_id` | BIGINT UNSIGNED | NULL | Self-referencing FK → `schools.id`. `NULL` = main school, populated = branch. |

**Behavior on parent deletion:** `CASCADE` — if a main school is deleted, all its branches are deleted automatically.

> **Note:** `status` and `rejection_reason` were already added in migration `2026_04_03_010000`. No changes needed for these fields.

---

### Table: `users`

| Column | Type | Default | Notes |
|---|---|---|---|
| `branch_id` | BIGINT UNSIGNED | NULL | FK → `schools.id`. Points to the branch this user manages (branch_admin role). SET NULL on branch deletion. |
| `is_temp_password` | BOOLEAN | `false` | Set to `true` when a branch admin account is created. Forces password change on first login. |
| `last_password_change` | TIMESTAMP | NULL | Updated every time the user changes their password. |

---

### Table: `branch_permissions` (NEW)

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT (PK) | Auto-increment |
| `user_id` | BIGINT (FK) | → `users.id`. The branch admin. |
| `branch_id` | BIGINT (FK) | → `schools.id`. The branch school. |
| `permission` | VARCHAR(100) | Permission key. See list below. |
| `granted` | BOOLEAN | `true` = allowed, `false` = denied. |
| Unique | `(user_id, branch_id, permission)` | Prevents duplicate permission records. |

**Available Permission Keys:**

| Key | Description (Arabic) |
|---|---|
| `manage_students` | إدارة الطلاب |
| `manage_teachers` | إدارة المعلمين |
| `manage_classes` | إدارة الصفوف |
| `view_reports` | عرض التقارير |
| `manage_subjects` | إدارة المواد |
| `manage_settings` | إدارة إعدادات الفرع |

---

## Models Updated

| Model | Changes |
|---|---|
| `School.php` | Added `parent_school_id` to `$fillable`. Added `parentSchool()`, `branches()`, `branchAdmin()` relationships. Added `isBranch()`, `isMainSchool()`, `isBranchPending()` helpers. |
| `User.php` | Added `branch_id`, `is_temp_password`, `last_password_change` to `$fillable`. Added `branch()`, `branchPermissions()` relationships. Added `isBranchAdmin()`, `hasTempPassword()` helpers. Added casts for new fields. |
| `BranchPermission.php` | **NEW** — Full model with `grant()`, `revoke()`, `userHas()` static helpers. Defines `PERMISSIONS` constant. |

---

## Ready for Phase 2

The database is now fully prepared for:
- Creating branch school records (`parent_school_id` populated)
- Creating branch admin users (`role = branch_admin`, `is_temp_password = true`)
- Super Admin approval workflow (using existing `status` field on `schools`)
- Granular permission management via `branch_permissions` table
