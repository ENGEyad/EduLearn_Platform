<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SystemNotification extends Model
{
    protected $fillable = [
        'title', 'message', 'target_role', 'priority', 'action_url', 
        'scheduled_at', 'read_count', 'icon', 'color', 'is_active', 'expires_at'
    ];
    protected $casts = [
        'is_active' => 'boolean', 
        'expires_at' => 'datetime',
        'scheduled_at' => 'datetime'
    ];

    public function reads()
    {
        return $this->hasMany(SystemNotificationRead::class);
    }
}
