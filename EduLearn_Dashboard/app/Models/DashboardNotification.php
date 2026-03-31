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
        'is_read',
        'data'
    ];

    protected $casts = [
        'data' => 'array',
        'is_read' => 'boolean'
    ];

    public static function logEvent($type, $title, $message, $actor = null, $icon = 'bi-bell', $data = null)
    {
        return self::create([
            'type' => $type,
            'title' => $title,
            'message' => $message,
            'actor_name' => $actor,
            'icon' => $icon,
            'data' => $data
        ]);
    }
}
