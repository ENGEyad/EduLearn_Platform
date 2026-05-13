import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ApiClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {'Accept': 'application/json'},
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static Dio get instance {
    _dio.interceptors.clear();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // التوكن غير صالح - تسجيل خروج تلقائي
          await _secureStorage.delete(key: 'auth_token');
          // يمكننا إضافة إعادة توجيه لكن سنعتمد على splash screen لاحقاً
        }
        return handler.next(e);
      },
    ));
    return _dio;
  }
}