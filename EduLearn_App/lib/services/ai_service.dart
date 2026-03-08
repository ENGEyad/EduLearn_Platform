import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../config/config.dart';

class AIService {
  static const String baseUrl = AppConfig.aiBaseUrl;

  /// Uploads a PDF file to the AI backend for extraction and chunking
  static Future<Map<String, dynamic>?> uploadPDF(PlatformFile file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-pdf/'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ),
      );

      print('Uploading file to AI server: ${file.name}');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Upload successful: ${data['message']}');
        return data;
      } else {
        print('Failed to upload PDF. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception during PDF upload: $e');
      return null;
    }
  }

  /// Sends a chat message to the AI Tutor
  static Future<Map<String, dynamic>?> sendChatMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to get response from AI. Status Code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception during chat request: $e');
      return null;
    }
  }
}
