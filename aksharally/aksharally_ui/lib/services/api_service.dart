import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/format_result.dart';
import '../theme/app_settings.dart';

class ApiService {

  /// ================================
  /// 🌐 BASE URL
  /// ================================

  // ✅ REAL PHONE (same WiFi)

  static const String baseUrl = "http://192.168.0.102:5000";


  // ✅ ANDROID EMULATOR
  // static const String baseUrl = "http://10.0.2.2:5000";


  /// ================================
  /// 🖼 IMAGE / FILE OCR + DYSLEXIA FORMATTING
  /// Calls POST /api/format-text — no auth required.
  /// Accepts images (.jpg .png .webp), PDFs, and DOCX files.
  /// Language is read from AppSettings.language (set in Settings screen).
  /// ================================
  static Future<FormatResult> processImage(
    File file, {
    String profile = 'moderate',
  }) async {
    final uri = Uri.parse('$baseUrl/api/format-text');

    try {
      print("📡 Sending file request to: $uri");
      print("📄 File path: ${file.path}");
      print("📐 Profile: $profile  |  🌐 Language: ${AppSettings.language}");

      final request = http.MultipartRequest('POST', uri);
      request.fields['language'] = AppSettings.language;
      request.fields['profile']  = profile;

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamed  = await request.send().timeout(const Duration(seconds: 30));
      final response  = await http.Response.fromStream(streamed);

      print("📥 Status: ${response.statusCode}");
      print("📥 Body:   ${response.body}");

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return FormatResult.fromJson(data);
      } else {
        throw Exception(data['error'] ?? "Unknown backend error");
      }

    } catch (e) {
      print("❌ FILE API ERROR: $e");
      throw Exception('Connection failed: $e');
    }
  }


  /// ================================
  /// 📝 TEXT SIMPLIFICATION (Gemini AI)
  /// Calls POST /process/text-format — no auth required.
  /// Language is read from AppSettings.language.
  /// ================================
  static Future<String> simplifyText(String text) async {
    final uri = Uri.parse('$baseUrl/process/text-format');

    try {
      print("📡 Sending text to: $uri");
      print("📝 Input (first 200): ${text.length > 200 ? text.substring(0, 200) : text}");
      print("🌐 Language: ${AppSettings.language}");

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "text":     text,
          "language": AppSettings.language,
        }),
      ).timeout(const Duration(seconds: 30));

      print("📥 Status: ${response.statusCode}");
      print("📥 Body:   ${response.body}");

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['formatted_text'] as String;
      } else {
        throw Exception(data['error'] ?? "Simplification failed");
      }

    } catch (e) {
      print("❌ TEXT API ERROR: $e");
      throw Exception("Connection failed: $e");
    }
  }
}
