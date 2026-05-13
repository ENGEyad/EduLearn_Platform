import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ReverbService {
  ReverbService._();

  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static ReverbClient? _client;
  static String? _mode; // 'student' | 'teacher'
  static Future<ReverbClient>? _connecting;

  static String _buildAuthEndpoint() {
    return '$serverRoot/api/broadcasting/auth';
  }

  static Future<Map<String, String>> _tokenAuthorizer(
    String channelName,
    String socketId,
  ) async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No auth token available for broadcasting');
    }
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ✅ الآن لا حاجة لتمرير academicId (يُستخدم فقط للتوافق مع الاستدعاءات القديمة)
  static Future<ReverbClient> getStudentClient({
    String? academicId, // أصبح اختياريًا – لن يُستخدم
    int port = 8080,
  }) async {
    if (_client != null && _mode == 'student') {
      return _ensureConnected(port: port);
    }
    if (_client != null && _mode != 'student') {
      await disconnectAll();
    }
    _mode = 'student';
    return _ensureConnected(port: port);
  }

  // ✅ الآن لا حاجة لتمرير teacherCode (يُستخدم فقط للتوافق)
  static Future<ReverbClient> getTeacherClient({
    String? teacherCode,
    int port = 8080,
  }) async {
    if (_client != null && _mode == 'teacher') {
      return _ensureConnected(port: port);
    }
    if (_client != null && _mode != 'teacher') {
      await disconnectAll();
    }
    _mode = 'teacher';
    return _ensureConnected(port: port);
  }

  static Future<ReverbClient> _ensureConnected({required int port}) async {
    if (_connecting != null) return _connecting!;

    _connecting = () async {
      final backendUri = Uri.parse(serverRoot);
      final host = backendUri.host;

      if (_client == null) {
        _client = ReverbClient.instance(
          host: host,
          port: port,
          appKey: pusherApiKey, // تأكد من وجود هذا الثابت أو انقله من AuthService
          authEndpoint: _buildAuthEndpoint(),
          authorizer: (channelName, socketId) async {
            return _tokenAuthorizer(channelName, socketId);
          },
          onConnected: (socketId) {
            print('✅ Reverb connected. socketId=$socketId mode=$_mode host=$host:$port');
          },
          onDisconnected: () {
            print('⚠️ Reverb disconnected. mode=$_mode');
          },
          onReconnecting: () {
            print('🔄 Reverb reconnecting... mode=$_mode');
          },
          onError: (error) {
            print('❌ Reverb error: $error');
          },
        );
      }
      await _client!.connect();
      return _client!;
    }();

    try {
      return await _connecting!;
    } finally {
      _connecting = null;
    }
  }

  static Future<void> disconnectAll() async {
    final c = _client;
    _client = null;
    _mode = null;
    if (c == null) return;
    try {
      c.disconnect();
    } catch (_) {}
  }

  static Future<void> disconnectStudent() async {
    if (_mode == 'student') await disconnectAll();
  }

  static Future<void> disconnectTeacher() async {
    if (_mode == 'teacher') await disconnectAll();
  }
}