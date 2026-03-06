<?php

use App\Models\Conversation;
use Illuminate\Support\Facades\Broadcast;

/**
 * Private channel authorization for:
 * private-conversation.{conversationId}
 *
 * In Laravel, you define it as:
 * conversation.{conversationId}
 * and the client subscribes to:
 * private-conversation.{conversationId}
 */
Broadcast::channel('conversation.{conversationId}', function ($user, $conversationId) {
    $conversation = Conversation::find($conversationId);
    if (!$conversation) {
        return false;
    }

    // We expect $user to be injected by our custom BroadcastAuthController
    $role = $user->role ?? null;

    if ($role === 'teacher') {
        return (int) $conversation->teacher_id === (int) $user->id;
    }

    if ($role === 'student') {
        return (int) $conversation->student_id === (int) $user->id;
    }

    return false;
});
