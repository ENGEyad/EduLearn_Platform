import 'dart:convert';
import 'api_config.dart';

class ApiHelpers {
  /// Helper موحّد لفك JSON والتأكد أنه Map<String, dynamic>
  static Map<String, dynamic> decodeJsonAsMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    } else if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw Exception('Invalid response format from server.');
  }

  /// Helper (اختياري) لفك JSON والتأكد أنه List
  static List<dynamic> decodeJsonAsList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    throw Exception('Invalid response format from server.');
  }

  // ==================== Helpers خاصة بالـ Media ====================

  static String buildFullMediaUrl(String rawOrPath) {
    if (rawOrPath.isEmpty) return '';
    final v = rawOrPath.trim();
    if (v.isEmpty) return '';

    if (v.startsWith('http://') || v.startsWith('https://')) return v;

    if (v.startsWith('/storage/')) {
      return '$serverRoot${v.startsWith('/') ? '' : '/'}$v';
    }

    if (v.contains('storage/')) {
      final idx = v.indexOf('storage/');
      final normalized = v.substring(idx); // storage/...
      return '$serverRoot/${normalized.replaceFirst(RegExp(r'^/+'), '')}';
    }

    final normalizedPath = v.startsWith('/') ? v.substring(1) : v;
    return '$serverRoot/storage/$normalizedPath';
  }

  /// ✅ Alias متوافق مع الشاشات القديمة/الحالية
  static String buildMediaUrl(String rawOrPath) => buildFullMediaUrl(rawOrPath);

  static String extractMediaPath(String urlOrPath) {
    if (urlOrPath.isEmpty) return '';
    var value = urlOrPath.trim();
    if (value.isEmpty) return '';

    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      if (uri != null) {
        value = uri.path; // مثل: /storage/lessons/x.mp4
      }
    }

    value = value.replaceFirst(RegExp(r'^/+'), '');

    if (value.startsWith('storage/')) {
      value = value.substring('storage/'.length);
    } else {
      final idx = value.indexOf('storage/');
      if (idx >= 0) {
        value = value.substring(idx + 'storage/'.length);
      }
    }

    return value;
  }

  static String pickMediaValueFromBlock(Map<String, dynamic> block) {
    final p = (block['media_path'] ?? '').toString().trim();
    if (p.isNotEmpty) return p;

    final u = (block['media_url'] ?? '').toString().trim();
    if (u.isNotEmpty) return u;

    final alt1 = (block['path'] ?? '').toString().trim();
    if (alt1.isNotEmpty) return alt1;

    final alt2 = (block['url'] ?? '').toString().trim();
    if (alt2.isNotEmpty) return alt2;

    return '';
  }
}
