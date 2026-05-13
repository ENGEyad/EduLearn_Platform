<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Student;
use App\Models\Teacher;
use Barryvdh\DomPDF\Facade\Pdf;

class ExportController extends Controller
{
    /**
     * Export Students as CSV.
     */
    public function exportStudentsCsv()
    {
        $schoolId = auth()->user()->school_id;
        
        $students = Student::where('school_id', $schoolId)
            ->with(['classSection', 'user'])
            ->get();

        $filename = "students_export_" . date('Y-m-d') . ".csv";
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$filename",
            "Pragma"              => "no-cache",
            "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
            "Expires"             => "0"
        ];

        $columns = ['ID', 'Name', 'Email', 'National ID', 'Class Section', 'Status', 'Attendance Rate', 'Performance Avg'];

        $callback = function() use($students, $columns) {
            $file = fopen('php://output', 'w');
            
            // Add BOM for UTF-8 Arabic support in Excel
            fputs($file, $bom =(chr(0xEF) . chr(0xBB) . chr(0xBF)));
            fputcsv($file, $columns);

            foreach ($students as $student) {
                $row = [
                    $student->id,
                    $student->user->name ?? $student->first_name . ' ' . $student->last_name,
                    $student->user->email ?? 'N/A',
                    $student->national_id,
                    $student->classSection->name ?? 'N/A',
                    $student->status,
                    $student->attendance_rate . '%',
                    $student->performance_avg
                ];
                fputcsv($file, $row);
            }

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Export Teachers as CSV.
     */
    public function exportTeachersCsv()
    {
        $schoolId = auth()->user()->school_id;
        
        $teachers = Teacher::where('school_id', $schoolId)
            ->with(['user'])
            ->get();

        $filename = "teachers_export_" . date('Y-m-d') . ".csv";
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$filename",
            "Pragma"              => "no-cache",
            "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
            "Expires"             => "0"
        ];

        $columns = ['ID', 'Name', 'Email', 'Specialization', 'Status', 'Hire Date'];

        $callback = function() use($teachers, $columns) {
            $file = fopen('php://output', 'w');
            
            // Add BOM for UTF-8 Arabic support in Excel
            fputs($file, $bom =(chr(0xEF) . chr(0xBB) . chr(0xBF)));
            fputcsv($file, $columns);

            foreach ($teachers as $teacher) {
                $row = [
                    $teacher->id,
                    $teacher->user->name ?? $teacher->first_name . ' ' . $teacher->last_name,
                    $teacher->user->email ?? 'N/A',
                    $teacher->specialization ?? 'N/A',
                    $teacher->status,
                    $teacher->hire_date ?? 'N/A'
                ];
                fputcsv($file, $row);
            }

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Export Students list as PDF.
     */
    public function exportStudentsPdf()
    {
        $schoolId = auth()->user()->school_id;
        
        $students = Student::where('school_id', $schoolId)
            ->with(['classSection', 'user'])
            ->get();
            
        $school = auth()->user()->school;

        $pdf = Pdf::loadView('exports.students_pdf', [
            'students' => $students,
            'school' => $school
        ]);
        
        return $pdf->download('students_report_' . date('Y-m-d') . '.pdf');
    }

    /**
     * Export Teachers list as PDF.
     */
    public function exportTeachersPdf()
    {
        $schoolId = auth()->user()->school_id;
        
        $teachers = Teacher::where('school_id', $schoolId)
            ->with(['user'])
            ->get();
            
        $school = auth()->user()->school;

        $pdf = Pdf::loadView('exports.teachers_pdf', [
            'teachers' => $teachers,
            'school' => $school
        ]);
        
        return $pdf->download('teachers_report_' . date('Y-m-d') . '.pdf');
    }
}
