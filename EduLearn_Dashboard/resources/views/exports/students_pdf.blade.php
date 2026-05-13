<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>تقرير الطلاب</title>
    <style>
        body {
            font-family: 'DejaVu Sans', sans-serif; /* Needs DejaVu Sans for UTF-8 fallback in dompdf */
            direction: rtl;
            text-align: right;
            font-size: 12px;
        }
        .header {
            text-align: center;
            margin-bottom: 20px;
            border-bottom: 2px solid #135bec;
            padding-bottom: 10px;
        }
        .school-name {
            font-size: 20px;
            font-weight: bold;
            color: #135bec;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            border: 1px solid #ccc;
            padding: 8px;
            text-align: right;
        }
        th {
            background-color: #f3f4f6;
            color: #1f2937;
            font-weight: bold;
        }
        tr:nth-child(even) {
            background-color: #f9fafb;
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 10px;
            color: #6b7280;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="school-name">{{ $school->name ?? 'EduLearn Dashboard' }}</div>
        <div>{{ $school->district ?? '' }} - {{ $school->city ?? '' }}</div>
        <h3>قائمة الطلاب - التقرير الشامل</h3>
        <p>تاريخ الإصدار: {{ date('Y-m-d') }}</p>
    </div>

    <table>
        <thead>
            <tr>
                <th>م</th>
                <th>اسم الطالب</th>
                <th>الرقم القومي</th>
                <th>الفصل</th>
                <th>نسبة الحضور</th>
                <th>الأداء الأكاديمي</th>
            </tr>
        </thead>
        <tbody>
            @foreach($students as $index => $student)
            <tr>
                <td>{{ $index + 1 }}</td>
                <td>{{ $student->user->name ?? $student->first_name . ' ' . $student->last_name }}</td>
                <td>{{ $student->national_id }}</td>
                <td>{{ $student->classSection->name ?? 'غير محدد' }}</td>
                <td>{{ $student->attendance_rate }}%</td>
                <td>{{ $student->performance_avg }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <div class="footer">
        تم إنشاء هذا التقرير تلقائياً بواسطة نظام EduLearn. © {{ date('Y') }}
    </div>
</body>
</html>
