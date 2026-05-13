<?php

namespace App\Events;

use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Collection;

class MessageStatusUpdated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public Conversation $conversation;

    /** @var \Illuminate\Support\Collection<int, Message> */
    public Collection $messages;

    public string $status;

    /** @var array<string, mixed> */
    public array $conversationPayload;

    public function __construct(
        Conversation $conversation,
        Collection $messages,
        string $status,
        array $conversationPayload = []
    ) {
        $this->conversation = $conversation;
        $this->messages = $messages;
        $this->status = $status;
        $this->conversationPayload = $conversationPayload;
    }

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('conversation.' . $this->conversation->id);
    }

    public function broadcastAs(): string
    {
        return 'message.status.updated';
    }

    public function broadcastWith(): array
    {
        return [
            'conversation_id' => (int) $this->conversation->id,
            'status' => $this->status,
            'server_time' => now()->toIso8601String(),
            'conversation' => $this->conversationPayload,
            'messages' => $this->messages->map(function (Message $message) {
                return [
                    'id' => (int) $message->id,
                    'conversation_id' => (int) $message->conversation_id,
                    'sent_at' => optional($message->sent_at)->toIso8601String(),
                    'delivered_at' => optional($message->delivered_at)->toIso8601String(),
                    'read_at' => optional($message->read_at)->toIso8601String(),
                    'status' => $message->read_at
                        ? 'read'
                        : ($message->delivered_at ? 'delivered' : 'sent'),
                ];
            })->values(),
        ];
    }
}
