<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DashboardNotification extends Model
{
    protected $table = 'dashboard_notifications';

    protected $fillable = [
        'type',
        'title',
        'message',
        'actor_name',
        'icon',
        'is_read'
    ];

    public static function logEvent($type, $title, $message, $actor = null, $icon = 'bi-bell')
    {
        return self::create([
            'type' => $type,
            'title' => $title,
            'message' => $message,
            'actor_name' => $actor,
            'icon' => $icon
        ]);
    }
}
