import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/format_result.dart';
import '../theme/app_settings.dart';

class ApiService {

  /// ================================
  /// 🌐 BASE URL
  /// ================================

  /// The Replit HTTPS URL is reachable from a physical phone and emulator.
  ///
  /// Local builds can point at another server without editing source:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://3a0a4a87-af80-41d6-861b-e481bfbbe1dd-00-1t5vx5n7rb0xr.sisko.replit.dev',
  );


  /// ================================
  /// 🖼 IMAGE / FILE OCR + DYSLEXIA FORMATTING
  /// Calls POST /api/format-text — no auth required.
  /// Accepts images (.jpg .png .webp), PDFs, and DOCX files.
  ///
  /// [language] — optional override.  When null, falls back to
  /// AppSettings.language so all existing callers remain unchanged.
  /// ================================
  static Future<FormatResult> processImage(
    File file, {
    String profile = 'moderate',
    String? language,
  }) async {
    final uri = Uri.parse('$baseUrl/api/format-text');
    final lang = language ?? AppSettings.language;

    try {
      print("📡 Sending file request to: $uri");
      print("📄 File path: ${file.path}");
      print("📐 Profile: $profile  |  🌐 Language: $lang");

      final request = http.MultipartRequest('POST', uri);
      request.fields['language'] = lang;
      request.fields['profile']  = profile;

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamed  = await request.send().timeout(const Duration(seconds: 60));
      final response  = await http.Response.fromStream(streamed);

      print("📥 Status: ${response.statusCode}");
      print("📥 Body:   ${response.body}");

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return FormatResult.fromJson(data);
      } else {
        throw Exception(data['error'] ?? "Unknown backend error");
      }

    } on TimeoutException {
      throw Exception(
        'The image took too long to process. Please try a clearer or smaller image.',
      );
    } on SocketException {
      throw Exception(
        'Could not reach the OCR server. Check your connection and try again.',
      );
    } on FileSystemException {
      throw Exception('The captured image is no longer available. Please scan it again.');
    } on FormatException {
      throw Exception('The OCR server returned an invalid response. Please try again.');
    } on Exception {
      rethrow;
    } catch (e) {
      print("❌ FILE API ERROR: $e");
      throw Exception('Unable to process the image: $e');
    }
  }


  /// ================================
  /// 📝 TEXT SIMPLIFICATION (Gemini AI)
  /// Calls POST /process/text-format — no auth required.
  ///
  /// [language] — optional override.  When null, falls back to
  /// AppSettings.language so all existing callers remain unchanged.
  /// ================================
  static Future<String> simplifyText(String text, {String? language}) async {
    final uri = Uri.parse('$baseUrl/process/text-format');
    final lang = language ?? AppSettings.language;

    try {
      print("📡 Sending text to: $uri");
      print("📝 Input (first 200): ${text.length > 200 ? text.substring(0, 200) : text}");
      print("🌐 Language: $lang");

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "text":     text,
          "language": lang,
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

  /// Simplifies a table/menu/column model without allowing Gemini to flatten
  /// it into prose. The server validates the returned shape and falls back to
  /// the original model when the AI response is unsafe.
  static Future<StructuredSimplifyResult> simplifyStructuredText(
    String text,
    Map<String, dynamic> structuredContent, {
    String? language,
  }) async {
    final uri = Uri.parse('$baseUrl/process/text-format');
    final lang = language ?? AppSettings.language;
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "text": text,
          "language": lang,
          "structured_content": structuredContent,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        final returned = data['structured_content'];
        return StructuredSimplifyResult(
          formattedText: data['formatted_text'] as String? ?? text,
          structuredContent: returned is Map
              ? Map<String, dynamic>.from(returned)
              : structuredContent,
        );
      }
      throw Exception(data['error'] ?? "Structured simplification failed");
    } catch (e) {
      print("❌ STRUCTURED TEXT API ERROR: $e");
      throw Exception("Connection failed: $e");
    }
  }
}

class StructuredSimplifyResult {
  final String formattedText;
  final Map<String, dynamic> structuredContent;

  const StructuredSimplifyResult({
    required this.formattedText,
    required this.structuredContent,
  });
}
