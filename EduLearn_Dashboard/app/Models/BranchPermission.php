<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BranchPermission extends Model
{
    protected $fillable = [
        'user_id',
        'branch_id',
        'permission',
        'granted',
    ];

    protected $casts = [
        'granted' => 'boolean',
    ];

    /**
     * The branch admin user who holds this permission.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * The branch school this permission is scoped to.
     */
    public function branch()
    {
        return $this->belongsTo(School::class, 'branch_id');
    }

    /**
     * Convenience: check if a specific user has a specific permission for a given branch.
     */
    public static function userHas(int $userId, int $branchId, string $permission): bool
    {
        return self::where('user_id', $userId)
            ->where('branch_id', $branchId)
            ->where('permission', $permission)
            ->where('granted', true)
            ->exists();
    }

    /**
     * Grant a permission to a user for a branch (upsert-safe).
     */
    public static function grant(int $userId, int $branchId, string $permission): void
    {
        self::updateOrCreate(
            ['user_id' => $userId, 'branch_id' => $branchId, 'permission' => $permission],
            ['granted' => true]
        );
    }

    /**
     * Revoke a permission from a user for a branch.
     */
    public static function revoke(int $userId, int $branchId, string $permission): void
    {
        self::updateOrCreate(
            ['user_id' => $userId, 'branch_id' => $branchId, 'permission' => $permission],
            ['granted' => false]
        );
    }

    // ─── Available Permission Keys ──────────────────────────────
    public const PERMISSIONS = [
        'manage_students'  => 'إدارة الطلاب',
        'manage_teachers'  => 'إدارة المعلمين',
        'manage_classes'   => 'إدارة الصفوف',
        'view_reports'     => 'عرض التقارير',
        'manage_subjects'  => 'إدارة المواد',
        'manage_settings'  => 'إدارة إعدادات الفرع',
    ];
}
