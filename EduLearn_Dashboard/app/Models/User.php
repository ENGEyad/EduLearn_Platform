<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'school_id',
        'branch_id',
        'role',
        'theme_mode',
        'language',
        'is_temp_password',
        'last_password_change',
        'otp_plain',
    ];

    public function school()
    {
        return $this->belongsTo(School::class);
    }

    /**
     * The branch school this user directly manages (branch_admin role).
     */
    public function branch()
    {
        return $this->belongsTo(School::class, 'branch_id');
    }

    /**
     * The branch permissions assigned to this user.
     */
    public function branchPermissions()
    {
        return $this->hasMany(BranchPermission::class);
    }

    public function isSuperAdmin()
    {
        return $this->role === 'super_admin';
    }

    public function isSchoolAdmin()
    {
        return $this->role === 'school_admin';
    }

    public function isBranchAdmin()
    {
        return $this->role === 'branch_admin';
    }

    public function hasBranchPermission(string $permission): bool
    {
        if ($this->isSuperAdmin() || $this->isSchoolAdmin()) {
            return true;
        }
        
        if ($this->isBranchAdmin()) {
            return \App\Models\BranchPermission::userHas($this->id, $this->branch_id, $permission);
        }
        
        return false;
    }

    public function hasTempPassword(): bool
    {
        return (bool) $this->is_temp_password;
    }

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at'    => 'datetime',
            'password'             => 'hashed',
            'is_temp_password'     => 'boolean',
            'last_password_change' => 'datetime',
        ];
    }
}
