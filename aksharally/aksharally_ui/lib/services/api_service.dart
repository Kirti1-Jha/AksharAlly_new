import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {

  /// ================================
  /// 🌐 BASE URL (IMPORTANT)
  /// ================================

  // ✅ REAL PHONE (same WiFi)
  static const String baseUrl = "http://192.168.1.7:5000";

  // ✅ ANDROID EMULATOR (use this if emulator)
  // static const String baseUrl = "http://10.0.2.2:5000";


  /// ================================
  /// 🔐 GET AUTH HEADER
  /// ================================
  static Future<Map<String, String>> _getHeaders() async {
    final auth = AuthService();
    final token = await auth.getToken();

    print("🔑 Firebase Token: $token");

    return {
      "Authorization": "Bearer $token",
    };
  }


  /// ================================
  /// 🖼 IMAGE OCR + SIMPLIFICATION
  /// ================================
  static Future<String> processImage(File imageFile) async {
    final uri = Uri.parse('$baseUrl/api/format-text');           // ✅ correct endpoint

    try {
      print("📡 Sending IMAGE request to: $uri");
      print("🖼 Image path: ${imageFile.path}");

      // No auth header — /api/format-text is unauthenticated
      final request = http.MultipartRequest('POST', uri);

      request.fields['language'] = 'hi';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',                                                 // ✅ correct field name
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 30));                  // ✅ 30-second timeout
      final response = await http.Response.fromStream(streamedResponse);

      print("📥 Status Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      final data = json.decode(response.body);

      if (response.statusCode == 200) {                          // ✅ HTTP status check only
        return data['processedText'] ?? "No text returned";      // ✅ correct response key
      } else {
        throw Exception(data['error'] ?? "Unknown backend error");
      }

    } catch (e) {
      print("❌ IMAGE API ERROR: $e");
      throw Exception('Connection failed: $e');
    }
  }


  /// ================================
  /// 📝 TEXT SIMPLIFICATION
  /// ================================
  static Future<String> simplifyText(String text) async {
  final auth = AuthService();
  final token = await auth.getToken();

  final uri = Uri.parse('$baseUrl/process/text-format');

  try {
    print("📡 Sending TEXT request to: $uri");
    print("📝 Input text: $text");

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode({
        "text": text,
        "language": "hi",
      }),
    );

    print("📥 Status Code: ${response.statusCode}");
    print("📥 Response Body: ${response.body}");

    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['formatted_text'];
    } else {
      throw Exception(data['error']);
    }

  } catch (e) {
    print("❌ TEXT API ERROR: $e");
    throw Exception("Connection failed: $e");
  }
}
}