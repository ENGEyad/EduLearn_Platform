<?php

namespace App\Events;

use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public Message $message;
    public Conversation $conversation;

    public function __construct(Message $message, Conversation $conversation)
    {
        $this->message = $message;
        $this->conversation = $conversation;
    }

    /**
     * Client subscribes to:
     * private-conversation.{id}
     */
    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('conversation.' . $this->conversation->id);
    }

    public function broadcastAs(): string
    {
        return 'message.sent';
    }

    public function broadcastWith(): array
    {
        $sentAt = $this->message->sent_at
            ? $this->message->sent_at->toIso8601String()
            : optional($this->message->created_at)->toIso8601String();

        $lastAt = $this->conversation->last_message_at
            ? $this->conversation->last_message_at->toIso8601String()
            : optional($this->conversation->updated_at)->toIso8601String();

        return [
            'conversation_id' => (int)$this->conversation->id,
            'server_time' => now()->toIso8601String(),

            'message' => [
                'id' => (int)$this->message->id,
                'conversation_id' => (int)$this->message->conversation_id,
                'body' => (string)$this->message->body,
                'sender_type' => (string)$this->message->sender_type,
                'sender_id' => (int)$this->message->sender_id,
                'sent_at' => $sentAt,
                'read_at' => optional($this->message->read_at)->toIso8601String(),
            ],

            'conversation' => [
                'id' => (int)$this->conversation->id,
                'last_message' => (string)($this->conversation->last_message ?? ''),
                'last_message_at' => $lastAt,

                'unread_for_teacher' => (int)$this->conversation->unread_for_teacher,
                'unread_for_student' => (int)$this->conversation->unread_for_student,

                // Compatibility: event is shared for both sides
                'unread_count' => (int)max(
                (int)$this->conversation->unread_for_teacher,
                (int)$this->conversation->unread_for_student
            ),
            ],
        ];
    }
}
