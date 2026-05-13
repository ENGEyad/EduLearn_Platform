<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DashboardNotification extends Model
{
    protected $table = 'dashboard_notifications';

    protected $fillable = [
        'school_id',
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

    public static function logEvent($type, $title, $message, $actor = null, $icon = 'bi-bell', $schoolId = null, $data = null)
    {
        return self::create([
            'school_id' => $schoolId,
            'type' => $type,
            'title' => $title,
            'message' => $message,
            'actor_name' => $actor,
            'icon' => $icon,
            'data' => $data
        ]);
    }
}
