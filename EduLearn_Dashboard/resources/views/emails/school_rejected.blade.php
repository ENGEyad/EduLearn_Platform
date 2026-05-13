<!DOCTYPE html>
<html>
<head>
    <title>Registration Update – EduLearn</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 20px auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px; }
        .header { background: #e74a3b; color: white; padding: 15px; border-radius: 8px 8px 0 0; text-align: center; }
        .content { padding: 20px; }
        .reason-box { background: #fdf2f2; border-left: 4px solid #e74a3b; padding: 15px; margin: 15px 0; }
        .footer { font-size: 0.8em; color: #777; text-align: center; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>Registration Status Update</h2>
        </div>
        <div class="content">
            <p>Hello <strong>{{ $school->admin_name }}</strong>,</p>
            <p>Thank you for your interest in the EduLearn Platform. We have reviewed your registration for <strong>{{ $school->name }}</strong>.</p>
            <p>Unfortunately, your application has been rejected at this time for the following reason:</p>
            <div class="reason-box">
                {{ $reason }}
            </div>
            <p>If you believe this is an error or would like to provide more information, please contact our support team.</p>
            <p>Best regards,<br>The EduLearn Team</p>
        </div>
        <div class="footer">
            &copy; {{ date('Y') }} EduLearn Platform. All rights reserved.
        </div>
    </div>
</body>
</html>
