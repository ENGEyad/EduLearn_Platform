<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>لوحة تحكم الدعم الفني - Super Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <style>
        body {
            font-family: 'Cairo', sans-serif;
            background-color: #f8fafc;
            color: #1e293b;
        }
        .sidebar {
            width: 280px;
            background: #0f172a;
            color: #fff;
            min-height: 100vh;
            position: fixed;
            right: 0;
            padding: 20px;
        }
        .main-content {
            margin-right: 280px;
            padding: 40px;
        }
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
        }
        .status-badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
        }
        .status-pending { background: #fef3c7; color: #92400e; }
        .status-active { background: #dcfce7; color: #166534; }
        .status-suspended { background: #fee2e2; color: #991b1b; }
        
        .school-row:hover { background-color: #f1f5f9; }
        .btn-action { margin-left: 5px; }
    </style>
</head>
<body>
    <div class="sidebar">
        <h3 class="mb-4 fw-bold text-info">EduLearn Support</h3>
        <ul class="nav flex-column">
            <li class="nav-item mb-2">
                <a href="#" class="nav-link text-white active bg-primary rounded">
                    <i class="bi bi-grid-fill me-2"></i> إدارة المدارس
                </a>
            </li>
            <li class="nav-item mb-2">
                <a href="#" class="nav-link text-white">
                    <i class="bi bi-bell me-2"></i> الإشعارات العامة
                </a>
            </li>
            <li class="nav-item mb-2">
                <a href="#" class="nav-link text-white">
                    <i class="bi bi-gear me-2"></i> الإعدادات
                </a>
            </li>
            <hr>
            <li class="nav-item">
                <a href="{{ url('/') }}" class="nav-link text-secondary">
                    <i class="bi bi-box-arrow-right me-2"></i> خروج
                </a>
            </li>
        </ul>
    </div>

    <div class="main-content">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h2 class="fw-bold">إدارة المدارس والمنصات</h2>
            <div class="text-secondary text-sm">إجمالي المسجلين: {{ $schools->count() }}</div>
        </div>

        @if(session('success'))
            <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
        @endif

        <div class="card p-3">
            <table class="table align-middle mt-3">
                <thead class="table-light">
                    <tr>
                        <th>المدرسة</th>
                        <th>مدير النظام</th>
                        <th>التواصل</th>
                        <th>تاريخ التسجيل</th>
                        <th>الحالة</th>
                        <th class="text-center">الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($schools as $school)
                    <tr class="school-row">
                        <td>
                            <div class="fw-bold">{{ $school->name }}</div>
                            <small class="text-secondary">Slug: {{ $school->slug }}</small>
                        </td>
                        <td>{{ $school->email }}</td>
                        <td>{{ $school->phone }}</td>
                        <td>{{ $school->created_at->format('Y-m-d') }}</td>
                        <td>
                            <span class="status-badge status-{{ $school->status }}">
                                {{ strtoupper($school->status) }}
                            </span>
                        </td>
                        <td class="text-center">
                            @if($school->status === 'pending')
                                <form action="{{ route('super-admin.schools.activate', $school) }}" method="POST" class="d-inline">
                                    @csrf
                                    <button class="btn btn-sm btn-success btn-action" title="تفعيل">
                                        <i class="bi bi-check-circle"></i> تفعيل
                                    </button>
                                </form>
                            @endif

                            <form action="{{ route('super-admin.schools.suspend', $school) }}" method="POST" class="d-inline">
                                @csrf
                                <button class="btn btn-sm {{ $school->status === 'suspended' ? 'btn-info' : 'btn-danger' }} btn-action" title="{{ $school->status === 'suspended' ? 'فك التعليق' : 'إيقاف' }}">
                                    <i class="bi {{ $school->status === 'suspended' ? 'bi-play-fill' : 'bi-pause-fill' }}"></i>
                                </button>
                            </form>

                            <button class="btn btn-sm btn-outline-primary btn-action" data-bs-toggle="modal" data-bs-target="#notifyModal{{ $school->id }}">
                                <i class="bi bi-send"></i>
                            </button>
                        </td>
                    </tr>

                    <!-- Notification Modal -->
                    <div class="modal fade" id="notifyModal{{ $school->id }}" tabindex="-1">
                        <div class="modal-dialog">
                            <form action="{{ route('super-admin.schools.notify', $school) }}" method="POST">
                                @csrf
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <h5 class="modal-title">إرسال تنبيه إلى {{ $school->name }}</h5>
                                        <button type="button" class="btn-close m-0" data-bs-dismiss="modal"></button>
                                    </div>
                                    <div class="modal-body">
                                        <textarea name="message" class="form-control" rows="4" placeholder="اكتب رسالة التنبيه هنا..."></textarea>
                                    </div>
                                    <div class="modal-footer">
                                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">إلغاء</button>
                                        <button type="submit" class="btn btn-primary">إرسال الآن</button>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
