<!DOCTYPE html>
<html>
<head>
    <title>Modification Requested – EduLearn</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 20px auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px; }
        .header { background: #f6c23e; color: #333; padding: 15px; border-radius: 8px 8px 0 0; text-align: center; }
        .content { padding: 20px; }
        .instruction-box { background: #fffdf2; border-left: 4px solid #f6c23e; padding: 15px; margin: 15px 0; }
        .footer { font-size: 0.8em; color: #777; text-align: center; margin-top: 20px; }
        .button { display: inline-block; padding: 12px 24px; background-color: #f6c23e; color: #333; text-decoration: none; border-radius: 5px; font-weight: bold; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>Action Required: Modification Needed</h2>
        </div>
        <div class="content">
            <p>Hello <strong>{{ $school->admin_name }}</strong>,</p>
            <p>We have reviewed your registration for <strong>{{ $school->name }}</strong> and require some modifications before we can proceed with approval.</p>
            <p><strong>Instructions from Support:</strong></p>
            <div class="instruction-box">
                {{ $instructions }}
            </div>
            <p>Please log in to your account and update the required information as specified above.</p>
            <p style="text-align: center;">
                <a href="{{ route('login') }}" class="button">Log In to Update</a>
            </p>
            <p>If you have any questions, feel free to reply to this email.</p>
            <p>Best regards,<br>The EduLearn Team</p>
        </div>
        <div class="footer">
            &copy; {{ date('Y') }} EduLearn Platform. All rights reserved.
        </div>
    </div>
</body>
</html>
