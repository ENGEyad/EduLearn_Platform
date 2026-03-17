<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تسجيل مدرسة جديدة - EduLearn Platform</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Cairo', sans-serif;
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
            padding: 20px;
        }
        .register-card {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            padding: 40px;
            width: 100%;
            max-width: 600px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
        }
        .register-header h2 {
            font-weight: 700;
            margin-bottom: 10px;
            background: linear-gradient(to left, #60a5fa, #a855f7);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .form-label { font-weight: 600; color: #cbd5e1; }
        .form-control {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.1);
            color: #fff;
            border-radius: 10px;
            padding: 12px;
        }
        .form-control:focus {
            background: rgba(255, 255, 255, 0.1);
            border-color: #6366f1;
            box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.2);
            color: #fff;
        }
        .btn-register {
            background: linear-gradient(to left, #6366f1, #a855f7);
            border: none;
            padding: 12px;
            border-radius: 10px;
            font-weight: 700;
            margin-top: 20px;
            transition: transform 0.2s;
        }
        .btn-register:hover {
            transform: translateY(-2px);
            opacity: 0.9;
        }
        .login-link { color: #818cf8; text-decoration: none; }
        .login-link:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="register-card text-end">
        <div class="register-header mb-4">
            <h2>EduLearn Platform</h2>
            <p class="text-secondary">قم بتهيئة بيانات مدرستك للانضمام إلى منصتنا المتطورة</p>
        </div>

        @if(session('success'))
            <div class="alert alert-success bg-success text-white border-0">{{ session('success') }}</div>
        @endif

        <form action="{{ route('register-school.post') }}" method="POST">
            @csrf
            <div class="row">
                <div class="col-md-12 mb-3">
                    <label class="form-label">اسم المدرسة</label>
                    <input type="text" name="school_name" class="form-control" placeholder="مثال: مدرسة النور الدولية" required>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">البريد الإلكتروني للإدارة</label>
                    <input type="email" name="email" class="form-control" placeholder="admin@school.com" required>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">رقم التواصل</label>
                    <input type="text" name="phone" class="form-control" placeholder="00966..." required>
                </div>
                <div class="col-md-12 mb-3">
                    <label class="form-label">اسم مدير النظام</label>
                    <input type="text" name="admin_name" class="form-control" placeholder="الاسم الكامل" required>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">كلمة المرور</label>
                    <input type="password" name="password" class="form-control" required>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">تأكيد كلمة المرور</label>
                    <input type="password" name="password_confirmation" class="form-control" required>
                </div>
            </div>

            <button type="submit" class="btn btn-primary btn-register w-full">إرسال طلب الانضمام</button>
            
            <div class="text-center mt-4 text-secondary">
                <span>لديك حساب بالفعل؟ </span>
                <a href="{{ url('/login') }}" class="login-link">تسجيل الدخول</a>
            </div>
        </form>
    </div>
</body>
</html>
