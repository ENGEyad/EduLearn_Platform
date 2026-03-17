import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static String get _ip {
    // لقراءة الـ IP الممرر عبر الـ Command Line لهاتف حقيقي
    const String envIp = String.fromEnvironment('SERVER_IP', defaultValue: '');
    if (envIp.isNotEmpty) return envIp;

    if (kIsWeb) return '127.0.0.1';
    if (Platform.isAndroid) return '10.0.2.2'; // الـ IP الثابت لمحاكي الأندرويد للوصول للكمبيوتر
    return '127.0.0.1'; // محاكي iOS أو بيئة أخرى
  }

  static String get baseUrl => 'http://$_ip:8000'; 
  static String get aiBaseUrl => 'http://$_ip:8001'; 
}