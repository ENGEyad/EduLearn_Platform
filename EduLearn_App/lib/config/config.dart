import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static String get _ip {
    // لقراءة الـ IP الممرر عبر الـ Command Line لهاتف حقيقي
    const String envIp = String.fromEnvironment('SERVER_IP', defaultValue: '');
    if (envIp.isNotEmpty) return envIp;

    if (kIsWeb) return '127.0.0.1';
    
    // ✅ نستخدم الـ IP الخاص بجهازك المسجل في الشبكة ليدعم المحاكي والجوال الحقيقي معاً
    if (Platform.isAndroid) return '192.168.1.108'; 
    return '127.0.0.1'; // محاكي iOS أو بيئة أخرى
  }

  static String get baseUrl => 'http://$_ip:8000'; 
  static String get aiBaseUrl => 'http://$_ip:8001'; 
}