<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>الحساب موقوف - EduLearn Platform</title>
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
            border-top: 5px solid #ef4444;
        }
        .icon-circle {
            width: 80px;
            height: 80px;
            background: #fef2f2;
            color: #ef4444;
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
        <div class="icon-circle">🚫</div>
        <h2 class="fw-bold mb-3 text-danger">عذراً، تم إيقاف الحساب</h2>
        <p class="text-secondary mb-4">
            لقد تم تعليق وصول مدرستكم إلى المنصة لأسباب تتعلق بالاشتراك أو سياسة الاستخدام. <br>
            يرجى التواصل مع الشركة الرسمية (الدعم الفني) لتسوية وضع الحساب وإعادة التفعيل.
        </p>
        <button onclick="window.location.reload()" class="btn btn-primary px-4">تحديث الصفحة</button>
        <div class="mt-4 text-secondary small">Support: support@edulearn.com</div>
    </div>
</body>
</html>
