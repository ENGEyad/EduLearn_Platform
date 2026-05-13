<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SupportMessage extends Model
{
    protected $fillable = ['ticket_id', 'user_id', 'message', 'is_admin_reply'];
    protected $casts = ['is_admin_reply' => 'boolean'];

    public function ticket() { return $this->belongsTo(SupportTicket::class); }
    public function user() { return $this->belongsTo(User::class); }
}
