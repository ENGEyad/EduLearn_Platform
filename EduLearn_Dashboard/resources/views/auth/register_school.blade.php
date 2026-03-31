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
        .form-control, .form-select {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.1);
            color: #fff;
            border-radius: 10px;
            padding: 12px;
        }
        .form-control:focus, .form-select:focus {
            background: rgba(255, 255, 255, 0.1);
            border-color: #6366f1;
            box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.2);
            color: #fff;
        }
        select option {
            background-color: #1e293b;
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

        <form action="{{ route('register-school.post') }}" method="POST" enctype="multipart/form-data">
            @csrf
            <div class="row">
                <div class="col-md-12 mb-3 text-center">
                    <label class="form-label d-block text-center">شعار المدرسة</label>
                    <div class="d-flex justify-content-center">
                        <input type="file" name="logo" class="form-control w-75" accept="image/*">
                    </div>
                    <small class="text-secondary">يفضل أن يكون الشعار بصيغة PNG أو JPG (بحد أقصى 2MB)</small>
                </div>

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

                <div class="col-md-6 mb-3">
                    <label class="form-label">السنة الدراسية <span class="text-danger">*</span></label>
                    <input type="text" name="academic_year" class="form-control" placeholder="مثال: 2025/2026" required>
                </div>

                <div class="col-md-6 mb-3">
                    <label class="form-label">نوع المدرسة <span class="text-danger">*</span></label>
                    <select name="school_type" class="form-select dynamic-other-select" required>
                        <option value="">اختر النوع...</option>
                        <option value="التعليم العام (حكومي)">التعليم العام (حكومي)</option>
                        <option value="تعليم خاص (لغات/عربي)">تعليم خاص (لغات/عربي)</option>
                        <option value="أزهري">أزهري</option>
                        <option value="other">آخر</option>
                    </select>
                </div>

                <div class="col-md-6 mb-3">
                    <label class="form-label">الدولة <span class="text-danger">*</span></label>
                    <select class="form-select" name="country" id="countrySelector" data-placeholder="اختر الدولة..." required>
                        <!-- populated by JS -->
                    </select>
                </div>

                <div class="col-md-6 mb-3">
                    <label class="form-label">المدينة / المحافظة <span class="text-danger">*</span></label>
                    <select class="form-select" name="city" id="citySelector" data-placeholder="اختر المدينة..." required>
                        <!-- populated by JS -->
                    </select>
                </div>

                <div class="col-md-6 mb-3">
                    <label class="form-label">المديرية / الإدارة التعليمية <span class="text-danger">*</span></label>
                    <select class="form-select" name="directorate" id="dirSelector" data-placeholder="اختر المديرية..." required>
                        <!-- populated by JS -->
                    </select>
                </div>

                <div class="col-md-6 mb-3">
                    <label class="form-label">العنوان التفصيلي <span class="text-danger">*</span></label>
                    <input type="text" name="address" class="form-control" placeholder="123 شارع السلام..." required>
                </div>

                <div class="col-md-12 mb-3">
                    <label class="form-label">الموقع الإلكتروني <span class="text-danger">*</span></label>
                    <input type="url" name="website" class="form-control" placeholder="https://school.com" required>
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

            <button type="submit" class="btn btn-primary btn-register w-100">إرسال طلب الانضمام</button>
            
            <div class="text-center mt-4 text-secondary">
                <span>لديك حساب بالفعل؟ </span>
                <a href="{{ url('/login') }}" class="login-link">تسجيل الدخول</a>
            </div>
        </form>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="{{ asset('js/locations.js') }}"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Initialize cascade locations
            const cSelector = document.getElementById('countrySelector');
            const ciSelector = document.getElementById('citySelector');
            const dSelector = document.getElementById('dirSelector');
            
            initDynamicLocations(cSelector, ciSelector, dSelector, "{{ old('country') }}", "{{ old('city') }}", "{{ old('directorate') }}");

            if ("{{ old('country') }}" && !document.querySelector('#countrySelector option[value="{{ old('country') }}"]')) {
                let opt = document.createElement('option');
                opt.value = "{{ old('country') }}";
                opt.text = "{{ old('country') }}";
                cSelector.add(opt, cSelector.options[cSelector.selectedIndex]);
                cSelector.value = "{{ old('country') }}";
            }
            if ("{{ old('city') }}" && !document.querySelector('#citySelector option[value="{{ old('city') }}"]')) {
                let opt = document.createElement('option');
                opt.value = "{{ old('city') }}";
                opt.text = "{{ old('city') }}";
                ciSelector.add(opt, ciSelector.options[ciSelector.selectedIndex]);
                ciSelector.value = "{{ old('city') }}";
            }
            if ("{{ old('directorate') }}" && !document.querySelector('#dirSelector option[value="{{ old('directorate') }}"]')) {
                let opt = document.createElement('option');
                opt.value = "{{ old('directorate') }}";
                opt.text = "{{ old('directorate') }}";
                dSelector.add(opt, dSelector.options[dSelector.selectedIndex]);
                dSelector.value = "{{ old('directorate') }}";
            }

            document.querySelectorAll('.dynamic-other-select').forEach(function(select) {
                // Initial check for previously loaded values not in the standard list
                let initialVal = "{{ old('school_type') }}"; // Can be expanded for others if needed
                
                select.addEventListener('change', async function() {
                    let val = this.value;
                    if (val === 'other') {
                        let newVal = "";
                        if (typeof Swal !== 'undefined') {
                            const result = await Swal.fire({
                                title: "الرجاء إدخال القيمة الجديدة",
                                input: 'text',
                                background: '#1e293b',
                                color: '#fff',
                                confirmButtonColor: '#6366f1',
                                inputPlaceholder: 'اكتب هنا...',
                                showCancelButton: true,
                                confirmButtonText: 'تأكيد',
                                cancelButtonText: 'إلغاء',
                                customClass: { popup: 'border border-primary' }
                            });
                            newVal = result.value;
                        } else {
                            newVal = prompt("الرجاء إدخال القيمة الجديدة / Please enter the new value:");
                        }

                        if (newVal && newVal.trim() !== "") {
                            newVal = newVal.trim();
                            let opt = document.createElement('option');
                            opt.value = newVal;
                            opt.text = newVal;
                            this.add(opt, this.options[this.selectedIndex]);
                            this.value = newVal;
                            this.style.backgroundColor = '#e0f2fe';
                            this.style.color = '#0369a1';
                        } else {
                            this.value = '';
                            this.style.backgroundColor = '';
                            this.style.color = '';
                        }
                    } else {
                        this.style.backgroundColor = '';
                        this.style.color = '';
                    }
                });
                
                // Trigger change to set correct colors if loaded with custom value
                if (select.value && select.value !== '' && select.value !== 'other' && select.querySelector('option[value="' + select.value + '"]') === null) {
                    // This handles when the value is already injected via blade (though the select only has static options natively)
                }
            });
        });
    </script>
</body>
</html>
