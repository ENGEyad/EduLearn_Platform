<?php

namespace App\Events;

use App\Models\SystemNotification;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class SystemAlertBroadcast implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $notification;

    /**
     * Create a new event instance.
     */
    public function __construct(SystemNotification $notification)
    {
        $this->notification = $notification;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        // General channel for everyone
        // Role-based channel for specific users
        $channelName = 'notifications.' . $this->notification->target_role;
        
        return [
            new Channel($channelName),
        ];
    }

    /**
     * The event name to broadcast as.
     */
    public function broadcastAs(): string
    {
        return 'system.alert';
    }
}
