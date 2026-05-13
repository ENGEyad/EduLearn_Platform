<?php

namespace App\Events;

use App\Models\Conversation;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class TypingStatusChanged implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public Conversation $conversation;
    public string $actorType;
    public string $state;
    public ?string $actorName;

    public function __construct(
        Conversation $conversation,
        string $actorType,
        string $state,
        ?string $actorName = null
    ) {
        $this->conversation = $conversation;
        $this->actorType = $actorType;
        $this->state = $state;
        $this->actorName = $actorName;
    }

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('conversation.' . $this->conversation->id);
    }

    public function broadcastAs(): string
    {
        return 'typing.status.changed';
    }

    public function broadcastWith(): array
    {
        return [
            'conversation_id' => (int) $this->conversation->id,
            'actor_type' => $this->actorType,
            'actor_name' => $this->actorName,
            'state' => $this->state,
            'is_typing' => $this->state === 'start',
            'server_time' => now()->toIso8601String(),
        ];
    }
}
