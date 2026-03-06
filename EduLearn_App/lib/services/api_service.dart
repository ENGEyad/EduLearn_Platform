export 'api_helpers.dart';
export 'api_config.dart';

<<<<<<< HEAD
/// ============================================================
/// ✅ إعدادات الـ API
///
/// مهم جدًا في التشغيل المحلي:
/// - لا تستخدم localhost على الجوال.
/// - استخدم IP جهاز السيرفر على نفس الشبكة.
/// ============================================================

/// ✅ جذر السيرفر (بدون /api)
// ✅ LDPlayer / Android emulator: use your PC's LAN IP, NOT 127.0.0.1
// 127.0.0.1 inside LDPlayer points to the emulator itself, not the host PC.
// Run `ipconfig` on your PC and paste your IPv4 address here.
const String serverRoot = 'http://192.168.138.54:8000';
// const String serverRoot = '127.0.0.1';

/// ✅ جذر الـ API (مع /api)
const String baseUrl = '$serverRoot/api';

class ApiService {
  // ==================== إعدادات عامة ====================

  /// جذر السيرفر بدون /api
  static String get rootUrl => serverRoot;

  /// (اختياري) مفاتيح Pusher Channels إن حبيت توحّدها هنا
  /// استبدل القيم الحقيقية من لوحة تحكم Pusher
  static const String pusherApiKey = 'qvgof2dxcwduaq9zvnyq'; // REVERB_APP_KEY
  static const String pusherCluster = 'mt1'; // Reverb لا يهتم بها

  // ==================== Helpers عامة ====================

  /// Helper موحّد لفك JSON والتأكد أنه Map<String, dynamic>
  static Map<String, dynamic> _decodeJsonAsMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    } else if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw Exception('Invalid response format from server.');
  }

  /// Helper (اختياري) لفك JSON والتأكد أنه List
  static List<dynamic> _decodeJsonAsList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    throw Exception('Invalid response format from server.');
  }

  // ==================== Helpers خاصة بالـ Media ====================

  /// يبني رابط كامل للملف من path أو url جزئي
  ///
  /// - lessons/x.mp4           =>  {rootUrl}/storage/lessons/x.mp4
  /// - storage/lessons/x.mp4   =>  {rootUrl}/storage/lessons/x.mp4
  /// - /storage/lessons/x.mp4  =>  {rootUrl}/storage/lessons/x.mp4
  /// - http(s)://...           =>  نفسها
  static String buildFullMediaUrl(String rawOrPath) {
    if (rawOrPath.isEmpty) return '';
    final v = rawOrPath.trim();
    if (v.isEmpty) return '';

    // URL كاملة
    if (v.startsWith('http://') || v.startsWith('https://')) return v;

    // لو جاء /storage/...
    if (v.startsWith('/storage/')) {
      return '$rootUrl${v.startsWith('/') ? '' : '/'}$v';
    }

    // لو يحتوي storage/ في أي مكان
    if (v.contains('storage/')) {
      final idx = v.indexOf('storage/');
      final normalized = v.substring(idx); // storage/...
      return '$rootUrl/${normalized.replaceFirst(RegExp(r'^/+'), '')}';
    }

    // مجرد path مثل lessons/xyz.mp4
    final normalizedPath = v.startsWith('/') ? v.substring(1) : v;
    return '$rootUrl/storage/$normalizedPath';
  }

  /// ✅ Alias متوافق مع الشاشات القديمة/الحالية
  static String buildMediaUrl(String rawOrPath) => buildFullMediaUrl(rawOrPath);

  /// يسحب مسار نظيف للتخزين في DB من URL كامل أو path
  ///
  /// أمثلة:
  ///  http://host/storage/lessons/x.mp4 => lessons/x.mp4
  ///  /storage/lessons/x.mp4           => lessons/x.mp4
  ///  storage/lessons/x.mp4            => lessons/x.mp4
  ///  lessons/x.mp4                    => lessons/x.mp4
  static String extractMediaPath(String urlOrPath) {
    if (urlOrPath.isEmpty) return '';
    var value = urlOrPath.trim();
    if (value.isEmpty) return '';

    // إذا كان URL كامل
    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      if (uri != null) {
        value = uri.path; // مثل: /storage/lessons/x.mp4
      }
    }

    // إزالة أي / بالبداية
    value = value.replaceFirst(RegExp(r'^/+'), '');

    // إذا يبدأ بـ storage/ احذفها
    if (value.startsWith('storage/')) {
      value = value.substring('storage/'.length);
    } else {
      // إذا يحتوي /storage/ في المنتصف
      final idx = value.indexOf('storage/');
      if (idx >= 0) {
        value = value.substring(idx + 'storage/'.length);
      }
    }

    // الناتج النهائي: lessons/x.mp4
    return value;
  }

  /// استخراج أفضل مسار/رابط للميديا من كائن block
  ///
  /// الأفضلية:
  /// media_path -> media_url -> أي حقل آخر محتمل
  static String pickMediaValueFromBlock(Map<String, dynamic> block) {
    final p = (block['media_path'] ?? '').toString().trim();
    if (p.isNotEmpty) return p;

    final u = (block['media_url'] ?? '').toString().trim();
    if (u.isNotEmpty) return u;

    // احتياط إذا جاءت مفاتيح مختلفة
    final alt1 = (block['path'] ?? '').toString().trim();
    if (alt1.isNotEmpty) return alt1;

    final alt2 = (block['url'] ?? '').toString().trim();
    if (alt2.isNotEmpty) return alt2;

    return '';
  }

  // ==================== المصادقة (طالب / أستاذ) ====================

  static Future<Map<String, dynamic>> authStudent({
    required String fullName,
    required String academicId,
    String? email,
    String? password,
  }) async {
    final url = Uri.parse('$baseUrl/student/auth');

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'full_name': fullName,
        'academic_id': academicId,
        if (email != null && email.isNotEmpty) 'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
      },
    );

    late final Map<String, dynamic> data;
    try {
      data = _decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['student'] is Map<String, dynamic>) {
      return data;
    } else {
      final msg = data['message']?.toString() ?? 'Auth failed';
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> authTeacher({
    required String fullName,
    required String teacherCode,
    String? email,
    String? password,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/auth');

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'full_name': fullName,
        'teacher_code': teacherCode,
        if (email != null && email.isNotEmpty) 'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
      },
    );

    late final Map<String, dynamic> data;
    try {
      data = _decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['teacher'] is Map<String, dynamic>) {
      return data;
    } else {
      final msg = data['message']?.toString() ?? 'Auth failed';
      throw Exception(msg);
    }
  }

  // ==================== بيانات الطالب ====================

  static Future<List<dynamic>> fetchStudentSubjects({
    required String academicId,
  }) async {
    final url = Uri.parse('$baseUrl/student/subjects?academic_id=$academicId');

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return (data['subjects'] as List?) ?? <dynamic>[];
    } else {
      throw Exception(data['message'] ?? 'Failed to load subjects');
    }
  }

  // ==================== بيانات الأستاذ ====================

  static Future<List<dynamic>> fetchTeacherAssignments({
    required String teacherCode,
  }) async {
    final url =
        Uri.parse('$baseUrl/teacher/assignments?teacher_code=$teacherCode');

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return (data['assignments'] as List?) ?? <dynamic>[];
    } else {
      throw Exception(data['message'] ?? 'Failed to load assignments');
    }
  }

  // ==================== ميديا الدروس ====================

  /// 🔹 رفع ميديا (صورة / صوت / فيديو) للدرس
  ///
  /// POST /api/teacher/lessons/media
  ///
  /// ✅ يرجّع السيرفر دائماً:
  /// - media_path: lessons/xxx.ext  (مصدر الحقيقة للتخزين في DB)
  /// - media_url : رابط كامل للعرض الفوري في Flutter Preview
  /// - media_mime: نوع الملف
  /// - media_size: حجم الملف بالبايت
  static Future<Map<String, dynamic>> uploadLessonMedia({
    required String filePath,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/lessons/media');

    // ✅ تجهيز رفع Multipart
    final request = http.MultipartRequest('POST', url)
      ..headers['Accept'] = 'application/json'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    // ✅ تنفيذ الطلب
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    // ✅ فك JSON بشكل آمن
    late final Map<String, dynamic> data;
    try {
      data = _decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    // ✅ التحقق من النجاح
    final okStatus = response.statusCode >= 200 && response.statusCode < 300;
    final okBody = data['success'] == true;

    if (!okStatus || !okBody) {
      final msg = data['message']?.toString() ?? 'Media upload failed';
      throw Exception(msg);
    }

    // ✅ اعتماد العقدة الرسمية من السيرفر:
    final rawPath = (data['media_path'] ?? data['path'] ?? '').toString().trim();
    final rawUrl = (data['media_url'] ?? data['url'] ?? '').toString().trim();

    // ✅ استخراج/تطبيع media_path
    String mediaPath = '';
    if (rawPath.isNotEmpty) {
      mediaPath = rawPath;
    } else if (rawUrl.isNotEmpty) {
      mediaPath = extractMediaPath(rawUrl);
    }

    mediaPath = mediaPath.trim();
    mediaPath = mediaPath.replaceFirst(RegExp(r'^/+'), '');
    if (mediaPath.startsWith('storage/')) {
      mediaPath = mediaPath.substring('storage/'.length);
    }

    // ✅ بناء media_url للعرض
    // - إن رجع من السيرفر نأخذه كما هو
    // - وإلا نبنيه من mediaPath
    final String mediaUrl =
        rawUrl.isNotEmpty ? rawUrl : (mediaPath.isNotEmpty ? buildFullMediaUrl(mediaPath) : '');

    // ✅ تطبيع الميتاداتا
    final String? mime = (data['media_mime'] ?? data['mime'])?.toString();

    final int? size = (data['media_size'] is int)
        ? data['media_size'] as int
        : (data['media_size'] is num)
            ? (data['media_size'] as num).toInt()
            : (data['size'] is int)
                ? data['size'] as int
                : (data['size'] is num)
                    ? (data['size'] as num).toInt()
                    : null;

    // ✅ نرجّع نفس الـ payload لكن مع ضمان وجود المفاتيح الموحدة
    return {
      ...data,
      'media_path': mediaPath.isNotEmpty ? mediaPath : '',
      'media_url': mediaUrl,
      'media_mime': mime,
      'media_size': size,
    };
  }

  // ==================== الموديولات (Class Modules) ====================

  static Future<List<dynamic>> fetchLessonModules({
    required String teacherCode,
    required int assignmentId,
    required int classSectionId,
    required int subjectId,
  }) async {
    final queryParams = <String, String>{
      'teacher_code': teacherCode,
      'assignment_id': assignmentId.toString(),
      'class_section_id': classSectionId.toString(),
      'subject_id': subjectId.toString(),
    };

    final uri = Uri.parse('$baseUrl/teacher/class-modules')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return (data['modules'] as List?) ?? <dynamic>[];
    } else {
      throw Exception(data['message'] ?? 'Failed to load lesson modules');
    }
  }

  static Future<Map<String, dynamic>> createLessonModule({
    required String teacherCode,
    required int assignmentId,
    required int classSectionId,
    required int subjectId,
    required String title,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/class-modules');

    final payload = {
      'teacher_code': teacherCode,
      'assignment_id': assignmentId,
      'class_section_id': classSectionId,
      'subject_id': subjectId,
      'title': title,
    };

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode >= 201 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return (data['module'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    } else {
      throw Exception(data['message'] ?? 'Failed to create lesson module');
    }
  }

  static Future<void> updateLessonModule({
    required int moduleId,
    required String title,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/class-modules/$moduleId');

    final payload = {'title': title};

    final response = await http.put(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update lesson module');
    }
  }

  static Future<void> deleteLessonModule({
    required int moduleId,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/class-modules/$moduleId');

    final response = await http.delete(
      url,
      headers: {'Accept': 'application/json'},
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete lesson module');
    }
  }

  static Future<List<dynamic>> fetchLessonsForModule({
    required int moduleId,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/class-modules/$moduleId/lessons');

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return (data['lessons'] as List?) ?? <dynamic>[];
    } else {
      throw Exception(data['message'] ?? 'Failed to load module lessons');
    }
  }

  // ==================== حفظ / عرض الدروس (Lesson) ====================

  static Future<Map<String, dynamic>> saveLesson({
    required String teacherCode,
    required int assignmentId,
    required int classModuleId,
    required int classSectionId,
    required int subjectId,
    int? lessonId,
    required String title,
    required bool publish,
    List<Map<String, dynamic>> modules = const [],
    List<Map<String, dynamic>> topics = const [],
    required List<Map<String, dynamic>> blocks,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/lessons/save');

    final normalizedBlocks = blocks.asMap().entries.map((entry) {
      final i = entry.key;
      final b = entry.value;

      final block = Map<String, dynamic>.from(b);
      final type = (block['type'] ?? '').toString();

      final isMedia = type == 'image' || type == 'video' || type == 'audio';

      if (isMedia) {
        final rawPath = (block['media_path'] ?? '').toString();
        final rawUrl = (block['media_url'] ?? '').toString();

        var mediaPath = rawPath.trim();
        if (mediaPath.isEmpty && rawUrl.trim().isNotEmpty) {
          mediaPath = extractMediaPath(rawUrl);
        }

        mediaPath = mediaPath.replaceFirst(RegExp(r'^/+'), '');
        if (mediaPath.startsWith('storage/')) {
          mediaPath = mediaPath.substring('storage/'.length);
        }

        block['media_path'] = mediaPath.isNotEmpty ? mediaPath : null;
      }

      block['module_id'] = null;
      block['topic_id'] = null;

      if (block['position'] == null) {
        block['position'] = i + 1;
      }

      return block;
    }).toList();

    final payload = {
      'teacher_code': teacherCode,
      'assignment_id': assignmentId,
      'class_module_id': classModuleId,
      'class_section_id': classSectionId,
      'subject_id': subjectId,
      if (lessonId != null) 'lesson_id': lessonId,
      'title': title,
      'status': publish ? 'published' : 'draft',
      'modules': modules,
      'topics': topics,
      'blocks': normalizedBlocks,
    };

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data['success'] == true) {
        if (data['lesson'] is Map) return Map<String, dynamic>.from(data);
        if (data['lesson_id'] != null) return Map<String, dynamic>.from(data);
        throw Exception('Invalid save response payload');
      }
      throw Exception(data['message'] ?? 'Lesson save failed');
    } else {
      throw Exception(data['message'] ?? 'Lesson save failed');
    }
  }

  static Future<Map<String, dynamic>> fetchLessonDetail({
    required int lessonId,
    required String teacherCode,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher/lessons/$lessonId')
        .replace(queryParameters: {'teacher_code': teacherCode});

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['lesson'] is Map) {
      return Map<String, dynamic>.from(data['lesson'] as Map);
    } else {
      throw Exception(data['message'] ?? 'Failed to load lesson detail');
    }
  }

  static Future<List<dynamic>> fetchTeacherLessons({
    required String teacherCode,
    int? assignmentId,
    int? classSectionId,
    int? subjectId,
    int? classModuleId,
  }) async {
    final queryParams = <String, String>{
      'teacher_code': teacherCode,
      if (assignmentId != null) 'assignment_id': assignmentId.toString(),
      if (classSectionId != null) 'class_section_id': classSectionId.toString(),
      if (subjectId != null) 'subject_id': subjectId.toString(),
      if (classModuleId != null) 'class_module_id': classModuleId.toString(),
    };

    final uri = Uri.parse('$baseUrl/teacher/lessons')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return (data['lessons'] as List?) ?? <dynamic>[];
    } else {
      throw Exception(data['message'] ?? 'Failed to load teacher lessons');
    }
  }

  static Future<void> deleteLesson({
    required int lessonId,
    required String teacherCode,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher/lessons/$lessonId')
        .replace(queryParameters: {'teacher_code': teacherCode});

    final response = await http.delete(
      uri,
      headers: {'Accept': 'application/json'},
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete lesson');
    }
  }

  static Future<void> deleteLessons({
    required String teacherCode,
    required List<int> lessonIds,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/lessons/bulk-delete');

    final payload = {
      'teacher_code': teacherCode,
      'lesson_ids': lessonIds,
    };

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete lessons');
    }
  }

  // ==================== واجهة الطالب للدروس ====================

  static Future<List<dynamic>> fetchStudentLessonsForSubject({
    required String academicId,
    required int subjectId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/student/lessons?academic_id=$academicId&subject_id=$subjectId',
    );

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return (data['lessons'] as List?) ?? <dynamic>[];
    } else {
      throw Exception(data['message'] ?? 'Failed to load lessons');
    }
  }

  static Future<Map<String, dynamic>> fetchStudentLessonDetail({
    required String academicId,
    required int lessonId,
  }) async {
    final uri = Uri.parse('$baseUrl/student/lessons/$lessonId')
        .replace(queryParameters: {'academic_id': academicId});

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      if (data['lesson'] is Map) {
        return Map<String, dynamic>.from(data['lesson'] as Map);
      }
      if (data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      throw Exception('Invalid lesson detail payload');
    } else {
      throw Exception(data['message'] ?? 'Failed to load lesson detail');
    }
  }

  static Future<void> updateStudentLessonStatus({
    required String academicId,
    required int lessonId,
    required String status,
  }) async {
    final url = Uri.parse('$baseUrl/student/lessons/update-status');

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'academic_id': academicId,
        'lesson_id': lessonId.toString(),
        'status': status,
      },
    );

    final data = _decodeJsonAsMap(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update lesson status');
    }
  }

  // ==================== الدردشة (كما هي) ====================

  static Future<Map<String, dynamic>> openTeacherConversation({
    required String teacherCode,
    required String academicId,
    int? classSectionId,
    int? subjectId,
  }) async {
    final url = Uri.parse('$baseUrl/chat/conversations/open');

    final body = <String, String>{
      'teacher_code': teacherCode,
      'academic_id': academicId,
      'as': 'teacher',
      if (classSectionId != null) 'class_section_id': classSectionId.toString(),
      if (subjectId != null) 'subject_id': subjectId.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: body,
    );

    late final Map<String, dynamic> data;
    try {
      data = _decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['conversation'] is Map) {
      return Map<String, dynamic>.from(
          data['conversation'] as Map<dynamic, dynamic>);
    } else {
      final msg = data['message']?.toString() ?? 'Failed to open conversation';
      throw Exception(msg);
    }
  }

  static Future<List<dynamic>> fetchTeacherConversations({
    required String teacherCode,
  }) async {
    final uri =
        Uri.parse('$baseUrl/chat/conversations/teacher?teacher_code=$teacherCode');

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    late final Map<String, dynamic> data;
    try {
      data = _decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['conversations'] is List) {
      return data['conversations'] as List<dynamic>;
    } else {
      final msg =
          data['message']?.toString() ?? 'Failed to load teacher conversations';
      throw Exception(msg);
    }
  }

  static Future<List<dynamic>> fetchConversationMessagesAsTeacher({
    required int conversationId,
    required String teacherCode,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/chat/conversations/$conversationId/messages'
      '?as=teacher&teacher_code=$teacherCode',
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    late final Map<String, dynamic> data;
    try {
      data = _decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['messages'] is List) {
      return data['messages'] as List<dynamic>;
    } else {
      final msg = data['message']?.toString() ?? 'Failed to load messages';
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> sendMessageAsTeacher({
    required int conversationId,
    required String teacherCode,
    required String messageBody,
  }) async {
    final url =
        Uri.parse('$baseUrl/chat/conversations/$conversationId/messages');

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'sender_type': 'teacher',
        'teacher_code': teacherCode,
        'body': messageBody,
      },
    );

    late final Map<String, dynamic> data;
    try {
      data = _decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['message'] is Map) {
      return Map<String, dynamic>.from(
          data['message'] as Map<dynamic, dynamic>);
    } else {
      final msg = data['message']?.toString() ?? 'Failed to send message';
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> openStudentConversation({
    required String academicId,
    required String teacherCode,
    int? classSectionId,
    int? subjectId,
  }) async {
    final url = Uri.parse('$baseUrl/chat/conversations/open');

    final body = <String, String>{
      'academic_id': academicId,
      'teacher_code': teacherCode,
      'as': 'student',
      if (classSectionId != null) 'class_section_id': classSectionId.toString(),
      if (subjectId != null) 'subject_id': subjectId.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: body,
    );

    late final Map<String, dynamic> data;
    try {
      data = _decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['conversation'] is Map) {
      return Map<String, dynamic>.from(
          data['conversation'] as Map<dynamic, dynamic>);
    } else {
      final msg = data['message']?.toString() ?? 'Failed to open conversation';
      throw Exception(msg);
    }
  }

  static Future<List<dynamic>> fetchStudentConversations({
    required String academicId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/chat/conversations/student?academic_id=$academicId',
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    late final Map<String, dynamic> data;
    try {
      data = _decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['conversations'] is List) {
      return data['conversations'] as List<dynamic>;
    } else {
      final msg =
          data['message']?.toString() ?? 'Failed to load student conversations';
      throw Exception(msg);
    }
  }

  static Future<List<dynamic>> fetchConversationMessagesAsStudent({
    required int conversationId,
    required String academicId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/chat/conversations/$conversationId/messages'
      '?as=student&academic_id=$academicId',
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    late final Map<String, dynamic> data;
    try {
      data = _decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['messages'] is List) {
      return data['messages'] as List<dynamic>;
    } else {
      final msg = data['message']?.toString() ?? 'Failed to load messages';
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> sendMessageAsStudent({
    required int conversationId,
    required String academicId,
    required String messageBody,
  }) async {
    final url =
        Uri.parse('$baseUrl/chat/conversations/$conversationId/messages');

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'sender_type': 'student',
        'academic_id': academicId,
        'body': messageBody,
      },
    );

    late final Map<String, dynamic> data;
    try {
      data = _decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['message'] is Map) {
      return Map<String, dynamic>.from(
          data['message'] as Map<dynamic, dynamic>);
    } else {
      final msg = data['message']?.toString() ?? 'Failed to send message';
      throw Exception(msg);
    }
  }
}
=======
export 'auth_service.dart';
export 'student_service.dart';
export 'teacher_service.dart';
export 'lesson_service.dart';
export 'chat_service.dart';
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
