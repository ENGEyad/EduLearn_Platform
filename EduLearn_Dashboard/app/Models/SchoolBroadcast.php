<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SchoolBroadcast extends Model
{
    protected $fillable = ['school_id', 'title', 'message', 'target', 'image'];

    public function school()
    {
        return $this->belongsTo(School::class);
    }
}
