<?php

namespace App\Http\Controllers\SuperAdmin;

use App\Http\Controllers\Controller;
use App\Models\School;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AnalyticsController extends Controller
{
    public function index()
    {
        $stats = [
            'total_schools' => School::count(),
            'active_schools' => School::where('status', 'active')->count(),
            'total_students' => Student::count(),
            'total_teachers' => Teacher::count(),
            'total_subjects' => Subject::count(),
        ];

        // Growth data (last 6 months)
        $growth = School::select(DB::raw('COUNT(*) as count'), DB::raw("DATE_FORMAT(created_at, '%Y-%m') as month"))
            ->groupBy('month')
            ->orderBy('month', 'desc')
            ->limit(6)
            ->get()
            ->reverse();

        return view('super_admin.analytics.index', compact('stats', 'growth'));
    }
}
