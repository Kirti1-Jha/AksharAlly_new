import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/format_result.dart';
import '../theme/app_settings.dart';

class ApiService {
  static Future<FormatResult>? _inFlightImageRequest;

  /// ================================
  /// 🌐 BASE URL
  /// ================================

  // ✅ REAL PHONE (same WiFi)

  static const String baseUrl = "http://192.168.0.101:5000";


  // ✅ ANDROID EMULATOR
  // static const String baseUrl = "http://10.0.2.2:5000";


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
    if (_inFlightImageRequest != null) {
      print("⚠️ OCR request already in-flight; awaiting the active request instead of queuing a duplicate.");
      return _inFlightImageRequest!;
    }

    final requestFuture = _processImageInternal(file, profile: profile, language: language);
    _inFlightImageRequest = requestFuture;

    try {
      return await requestFuture;
    } finally {
      _inFlightImageRequest = null;
    }
  }

  static Future<FormatResult> _processImageInternal(
    File file, {
    String profile = 'moderate',
    String? language,
  }) async {
    final uri = Uri.parse('$baseUrl/api/format-text');
    final lang = language ?? AppSettings.language;
    final requestStartedAt = DateTime.now();

    try {
      print("📡 request started: $uri");
      print("📄 file path: ${file.path}");
      print("📐 profile: $profile | language: $lang");

      final request = http.MultipartRequest('POST', uri);
      request.fields['language'] = lang;
      request.fields['profile'] = profile;
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      final elapsedMs = DateTime.now().difference(requestStartedAt).inMilliseconds;
      final contentType = response.headers['content-type'] ?? 'unknown';
      final bodyLength = response.bodyBytes.length;

      print("⏱️ request completed in ${elapsedMs}ms");
      print("📥 status: ${response.statusCode}");
      print("📥 content-type: $contentType");
      print("📥 body length: $bodyLength");
      print("📥 body preview: ${response.body.substring(0, response.body.length > 400 ? 400 : response.body.length)}");

      if (response.statusCode != 200) {
        print("⚠️ non-200 response received; body: ${response.body}");
        throw Exception(response.body.isNotEmpty ? response.body : 'Unknown backend error');
      }

      if (!contentType.toLowerCase().contains('application/json') &&
          !response.body.trimLeft().startsWith('{')) {
        print("⚠️ response content type/body does not look like JSON");
        throw const FormatException('Backend response was not JSON.');
      }

      final data = json.decode(response.body);
      print("📦 parsed json type: ${data.runtimeType}");
      if (data is! Map<String, dynamic>) {
        final mapData = Map<String, dynamic>.from(data as Map);
        print("📦 coerced json keys: ${mapData.keys.toList()}");
        return FormatResult.fromJson(mapData);
      }

      print("📦 json keys: ${data.keys.toList()}");
      return FormatResult.fromJson(data);

    } on TimeoutException catch (e) {
      print("⏰ TimeoutException: ${e.runtimeType} :: ${e.message}");
      throw Exception(
        'The image took too long to process. Please try a clearer or smaller image.',
      );
    } on SocketException catch (e) {
      print("❌ SocketException: $e");
      throw Exception(
        'Could not reach the OCR server. Check your connection and try again.',
      );
    } on FileSystemException catch (e) {
      print("❌ FileSystemException: $e");
      throw Exception('The captured image is no longer available. Please scan it again.');
    } on FormatException catch (e) {
      print("❌ FormatException while decoding OCR response: $e");
      throw Exception('The OCR server returned an invalid response. Please try again.');
    } on TypeError catch (e) {
      print("❌ TypeError while building FormatResult: $e");
      throw Exception('The OCR server returned a response in an unexpected format.');
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
