<!DOCTYPE html>
<html>
<head>
    <title>School Approved – EduLearn</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 20px auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px; }
        .header { background: #4e73df; color: white; padding: 15px; border-radius: 8px 8px 0 0; text-align: center; }
        .content { padding: 20px; }
        .footer { font-size: 0.8em; color: #777; text-align: center; margin-top: 20px; }
        .button { display: inline-block; padding: 12px 24px; background-color: #4e73df; color: white; text-decoration: none; border-radius: 5px; font-weight: bold; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>Welcome to EduLearn!</h2>
        </div>
        <div class="content">
            <p>Hello <strong>{{ $school->admin_name }}</strong>,</p>
            <p>We are excited to inform you that your school, <strong>{{ $school->name }}</strong>, has been approved by the EduLearn support team.</p>
            <p>Your account is now active. You can log in to your dashboard to complete the system initialization and start managing your school.</p>
            <p style="text-align: center;">
                <a href="{{ route('login') }}" class="button">Log In to Dashboard</a>
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
