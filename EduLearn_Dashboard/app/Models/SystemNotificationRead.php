<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SystemNotificationRead extends Model
{
    protected $fillable = ['system_notification_id', 'user_id', 'read_at', 'interacted'];
    
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
