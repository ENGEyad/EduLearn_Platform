<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SupportTicket extends Model
{
    protected $fillable = ['school_id', 'subject', 'status', 'priority'];

    public function school() { return $this->belongsTo(School::class); }
    public function messages() { return $this->hasMany(SupportMessage::class, 'ticket_id'); }
}
