<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentResponse extends Model
{
    protected $connection = 'app_mysql';
    protected $table = 'student_responses';
    protected $guarded = [];

    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    public function exercise()
    {
        return $this->belongsTo(Exercise::class);
    }
}
