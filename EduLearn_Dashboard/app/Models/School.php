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
    ];

    protected $casts = [
        'features' => 'array',
    ];

    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function admin()
    {
        return $this->users()->where('role', 'school_admin')->first();
    }
}
