import 'dart:io';
import 'package:flutter/foundation.dart';

/// ✅ اكتشاف العنوان المناسب (المحاكي يحتاج 10.0.2.2 أحياناً، لكن الـ IP المحلي يعمل للكل)
String get _host {
  // لقراءة الـ IP الممرر عبر الـ Command Line لهاتف حقيقي أو جهاز آخر
  const String envIp = String.fromEnvironment('SERVER_IP', defaultValue: '');
  if (envIp.isNotEmpty) return envIp;

  if (kIsWeb) return '127.0.0.1';
  
  // ✅ فحص المحاكي:
  // في أندرويد 10.0.2.2 هو الكمبيوتر المضيف
  if (Platform.isAndroid) {
    // حاولنا 10.0.2.2 للمحاكي كأولوية، وإذا كان هاتف حقيقي نستخدم الـ IP الخاص بك والشبكة
    // لكن الأفضل والأسلم للطرفين (بما أنهم على نفس الـ Wi-Fi) هو استخدام الـ IP المباشر:
    return '192.168.1.108'; 
  }
  
  return '127.0.0.1'; // محاكي iOS أو بيئات أخرى
}

const String _port = '8000';
const String _aiPort = '8001';

/// ✅ جذر السيرفر (Laravel)
String get serverRoot => 'http://$_host:$_port';

/// ✅ جذر الـ API (Laravel)
String get baseUrl => '$serverRoot/api';

/// ✅ جذر سيرفر الذكاء الاصطناعي (Python)
String get aiBaseUrl => 'http://$_host:$_aiPort';
