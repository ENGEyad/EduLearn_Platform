import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'auth_service.dart';

/// ✅ ReverbService مضبوط: Client واحد فقط + await connect + logs
/// السبب: ReverbClient.instance() عادة Singleton، وإنشاء عميلين يسبب تلخبط بالـ authorizer
class ReverbService {
  ReverbService._();

  static ReverbClient? _client;

  /// لمعرفة الدور الحالي للعميل
  static String? _mode; // 'student' | 'teacher'
  static String? _studentAcademicId;
  static String? _teacherCode;

  /// لمنع تكرار محاولات connect بنفس الوقت
  static Future<ReverbClient>? _connecting;

  static String _buildAuthEndpoint() {
    // ✅ endpoint الصحيح حسب Laravel routes/api.php:
    // POST /api/broadcasting/auth
    return '${AuthService.rootUrl}/api/broadcasting/auth';
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

  /// ✅ عميل المدرس (Client واحد في الجلسة)
  static Future<ReverbClient> getTeacherClient({
    required String teacherCode,
    int port = 8080,
  }) async {
    // إذا موجود عميل بنفس الوضع رجّعه
    if (_client != null && _mode == 'teacher' && _teacherCode == teacherCode) {
      return _client!;
    }

    // إذا موجود عميل لكن بوضع مختلف (طالب) لازم نفصله أولاً
    if (_client != null && _mode != 'teacher') {
      await disconnectAll();
    }

    _mode = 'teacher';
    _teacherCode = teacherCode;
    _studentAcademicId = null;

    return _ensureConnected(port: port);
  }

  /// ✅ عميل الطالب (Client واحد في الجلسة)
  static Future<ReverbClient> getStudentClient({
    required String academicId,
    int port = 8080,
  }) async {
    if (_client != null && _mode == 'student' && _studentAcademicId == academicId) {
      return _client!;
    }

    if (_client != null && _mode != 'student') {
      await disconnectAll();
    }

    _mode = 'student';
    _studentAcademicId = academicId;
    _teacherCode = null;

    return _ensureConnected(port: port);
  }

  static Future<ReverbClient> _ensureConnected({required int port}) async {
    // لو فيه connect شغال بالفعل، انتظر نفس الـ Future
    if (_connecting != null) return _connecting!;

    _connecting = () async {
      final backendUri = Uri.parse(AuthService.rootUrl);

      // أنشئ عميل إذا مش موجود
      if (_client == null) {
        // ✅ DEBUG: Log EXACT host and port being used
        print('📡 REVERB INIT: host=${backendUri.host}, port=$port, useTLS=false');

        _client = ReverbClient.instance(
          host: backendUri.host,
          port: port,
          useTLS: false, // ✅ Important: Disable SSL for local dev (reverb:start --port=8080)
          appKey: AuthService.pusherApiKey,
          authEndpoint: _buildAuthEndpoint(),
          authorizer: (channelName, socketId) async {
            // ✅ authorizer حسب الوضع الحالي
            if (_mode == 'teacher') {
              final code = _teacherCode;
              if (code == null || code.isEmpty) {
                throw Exception('Teacher code is missing for authorizer');
              }
              return _teacherAuthorizer(channelName, socketId, teacherCode: code);
            }

            if (_mode == 'student') {
              final id = _studentAcademicId;
              if (id == null || id.isEmpty) {
                throw Exception('Academic ID is missing for authorizer');
              }
              return _studentAuthorizer(channelName, socketId, academicId: id);
            }

            throw Exception('Reverb mode is not set (student/teacher)');
          },

          // ✅ Logs للتشخيص (مهم جدًا)
          onConnected: (socketId) {
            // ignore: avoid_print
            print('✅ Reverb connected. socketId=$socketId mode=$_mode host=${backendUri.host}:$port');
          },
          onDisconnected: () {
            // ignore: avoid_print
            print('⚠️ Reverb disconnected. mode=$_mode');
          },
          onReconnecting: () {
            // ignore: avoid_print
            print('🔄 Reverb reconnecting... mode=$_mode');
          },
          onError: (error) {
            // ignore: avoid_print
            print('❌ Reverb error: $error');
          },
        );
      }

      // ✅ الأهم: انتظر الاتصال فعلاً
      await _client!.connect();
      return _client!;
    }();

    try {
      return await _connecting!;
    } finally {
      _connecting = null;
    }
  }

  /// ✅ فصل العميل الحالي فقط (سواء طالب أو مدرس)
  static Future<void> disconnectAll() async {
    final c = _client;
    _client = null;
    _mode = null;
    _studentAcademicId = null;
    _teacherCode = null;

    if (c == null) return;

    try {
      c.disconnect();
    } catch (_) {}
  }

  /// للتوافق (إذا كودك يناديها)
  static Future<void> disconnectStudent() async {
    if (_mode == 'student') {
      await disconnectAll();
    }
  }

  /// للتوافق (إذا كودك يناديها)
  static Future<void> disconnectTeacher() async {
    if (_mode == 'teacher') {
      await disconnectAll();
    }
  }
}