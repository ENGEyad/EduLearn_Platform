<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class School extends Model
{
    protected $fillable = [
        'name',
        'slug',
        'email',
        'phone',
        'address',
        'logo_path',
        'status',
        'features',
        'activation_code',
        'academic_year',
        'school_type',
        'section',
        'country',
        'city',
        'directorate',
        'website',
        'admin_name',
        'num_students',
        'rejection_reason',
        'is_initialized',
        'parent_school_id', // Branch management: NULL for main schools, school ID for branches.
    ];

    protected $casts = [
        'features'       => 'array',
        'is_initialized' => 'boolean',
    ];

    protected $appends = [
        'logo_url',
        'logo_thumb_url',
    ];

    // ─── Accessors ───────────────────────────────────────

    public function getLogoUrlAttribute(): ?string
    {
        return $this->logo_path ? asset('storage/' . $this->logo_path) : null;
    }

    public function getLogoThumbUrlAttribute(): ?string
    {
        if (!$this->logo_path) {
            return null;
        }
        $dir = dirname($this->logo_path);
        $file = basename($this->logo_path);
        return asset('storage/' . $dir . '/thumbs/' . $file);
    }

    // ─── Relationships ───────────────────────────────────

    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function admin()
    {
        return $this->users()->where('role', 'school_admin')->first();
    }

    /**
     * Parent school (only populated for branch schools).
     */
    public function parentSchool()
    {
        return $this->belongsTo(School::class, 'parent_school_id');
    }

    /**
     * All branches belonging to this main school.
     */
    public function branches()
    {
        return $this->hasMany(School::class, 'parent_school_id');
    }

    /**
     * The branch admin user for this branch school.
     */
    public function branchAdmin()
    {
        return $this->users()->where('role', 'branch_admin')->first();
    }

    public function students()
    {
        return $this->hasMany(Student::class);
    }

    public function teachers()
    {
        return $this->hasMany(Teacher::class);
    }

    public function classSections()
    {
        return $this->hasMany(ClassSection::class);
    }

    /**
     * Subjects enabled for this school (via school_subjects pivot).
     */
    public function subjects()
    {
        return $this->belongsToMany(Subject::class, 'school_subjects')
            ->withPivot('is_active')
            ->withTimestamps();
    }

    /**
     * SchoolSubject pivot records (useful for direct queries).
     */
    public function schoolSubjects()
    {
        return $this->hasMany(SchoolSubject::class);
    }

    // ─── Helpers ─────────────────────────────────────────

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    public function isPending(): bool
    {
        return $this->status === 'pending';
    }

    public function isSuspended(): bool
    {
        return $this->status === 'suspended';
    }

    public function isRejected(): bool
    {
        return $this->status === 'rejected';
    }

    public function isBranch(): bool
    {
        return !is_null($this->parent_school_id);
    }

    public function isMainSchool(): bool
    {
        return is_null($this->parent_school_id);
    }

    public function isBranchPending(): bool
    {
        return $this->isBranch() && $this->status === 'pending';
    }
}
