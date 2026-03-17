<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>بانتظار التفعيل - EduLearn Platform</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Cairo', sans-serif;
            background: #f8fafc;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
        }
        .status-container {
            max-width: 500px;
            padding: 40px;
            background: white;
            border-radius: 20px;
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
        }
        .icon-circle {
            width: 80px;
            height: 80px;
            background: #fff7ed;
            color: #f97316;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 40px;
            margin: 0 auto 20px;
        }
    </style>
</head>
<body>
    <div class="status-container">
        <div class="icon-circle">⏳</div>
        <h2 class="fw-bold mb-3">بانتظار مراجعة الإدارة</h2>
        <p class="text-secondary mb-4">
            شكراً لتسجيل مدرستك في منصة **EduLearn**. <br>
            طلبك قيد المراجعة حالياً من قبل فريق الدعم الفني. سيتم تفعيل حسابك والوصول للوحة التحكم فور الموافقة على البيانات.
        </p>
        <a href="{{ url('/') }}" class="btn btn-outline-primary px-4">العودة للرئيسية</a>
        <div class="mt-4 text-secondary small">إذا كان لديك استفسار، يرجى التواصل معنا عبر support@edulearn.com</div>
    </div>
</body>
</html>
