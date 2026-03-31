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
        'country',
        'city',
        'directorate',
        'website',
    ];

    protected $casts = [
        'features' => 'array',
    ];

    protected $appends = [
        'logo_url',
        'logo_thumb_url',
    ];

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

    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function admin()
    {
        return $this->users()->where('role', 'school_admin')->first();
    }
}
