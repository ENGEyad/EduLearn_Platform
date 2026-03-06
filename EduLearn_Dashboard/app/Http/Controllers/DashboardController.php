<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index()
    {
        // هنا بعدين بنجيب الإحصائيات من قاعدة البيانات
        // مثلاً:
        // $teachersCount = Teacher::count();
        // لكن الآن بنرسل قيم ثابتة نفس اللي في الـ HTML

        return view('dashboard', [
            'pageTitle' => 'Dashboard',
            'pageSubtitle' => 'Welcome, Admin!',
            'stats' => [
                'teachers' => 52,
                'students' => 850,
                'classes'  => 32,
                'subjects' => 15,
                'attendance' => 92,
            ],
        ]);
    }
}
