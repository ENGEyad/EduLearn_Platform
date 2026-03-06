import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'auth_service.dart';

/// Service واحد لتجنب تكرار كود Reverb في أكثر من شاشة
class ReverbService {
  ReverbService._();

  static ReverbClient? _studentClient;
  static ReverbClient? _teacherClient;

  static String _buildAuthEndpoint() {
    // ✅ endpoint الصحيح حسب Laravel routes
    return '${AuthService.rootUrl}/api/chat/broadcasting/auth';
  }

  static Future<Map<String, String>> _teacherAuthorizer(
    String channelName,
    String socketId, {
    required String teacherCode,
  }) async {
    return {
      'Accept': 'application/json',
      'X-Chat-As': 'teacher',
      'X-Teacher-Code': teacherCode,
    };
  }

  static Future<Map<String, String>> _studentAuthorizer(
    String channelName,
    String socketId, {
    required String academicId,
  }) async {
    return {
      'Accept': 'application/json',
      'X-Chat-As': 'student',
      'X-Academic-Id': academicId,
    };
  }

  static Future<ReverbClient> getTeacherClient({
    required String teacherCode,
    int port = 8080,
  }) async {
    if (_teacherClient != null) return _teacherClient!;

    final backendUri = Uri.parse(AuthService.rootUrl);

    _teacherClient = ReverbClient.instance(
      host: backendUri.host,
      port: port,
      appKey: AuthService.pusherApiKey,
      authEndpoint: _buildAuthEndpoint(),
      authorizer: (channelName, socketId) =>
          _teacherAuthorizer(channelName, socketId, teacherCode: teacherCode),
    );

    // connect() returns void in this package
    _teacherClient!.connect();
    return _teacherClient!;
  }

  static Future<ReverbClient> getStudentClient({
    required String academicId,
    int port = 8080,
  }) async {
    if (_studentClient != null) return _studentClient!;

    final backendUri = Uri.parse(AuthService.rootUrl);

    _studentClient = ReverbClient.instance(
      host: backendUri.host,
      port: port,
      appKey: AuthService.pusherApiKey,
      authEndpoint: _buildAuthEndpoint(),
      authorizer: (channelName, socketId) =>
          _studentAuthorizer(channelName, socketId, academicId: academicId),
    );

    _studentClient!.connect();
    return _studentClient!;
  }

  static Future<void> disconnectStudent() async {
    final c = _studentClient;
    if (c == null) {
      _studentClient = null;
      return;
    }

    try {
      c.disconnect();
    } catch (_) {}
    _studentClient = null;
  }

  static Future<void> disconnectTeacher() async {
    final c = _teacherClient;
    if (c == null) {
      _teacherClient = null;
      return;
    }

    try {
      c.disconnect();
    } catch (_) {}
    _teacherClient = null;
  }

  static Future<void> disconnectAll() async {
    await disconnectStudent();
    await disconnectTeacher();
  }
}
