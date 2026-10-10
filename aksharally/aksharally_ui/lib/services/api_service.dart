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
  static const String baseUrl = "http://192.168.1.3:5000";

  // ✅ ANDROID EMULATOR
  // static const String baseUrl = "http://10.0.2.2:5000";

  /// ================================
  /// ⏱️ REQUEST TIMEOUTS
  /// ================================

  // EasyOCR runs on CPU, so large images can take a long time.
  // 180 seconds gives the backend enough time to process
  // images containing a lot of text.
  static const Duration imageRequestTimeout = Duration(seconds: 180);

  // Text simplification normally shouldn't take nearly as long.
  static const Duration textRequestTimeout = Duration(seconds: 30);

  /// ================================
  /// 🖼 IMAGE / FILE OCR + DYSLEXIA FORMATTING
  ///
  /// Calls POST /api/format-text
  ///
  /// Accepts:
  /// - JPG
  /// - PNG
  /// - WEBP
  /// - PDF
  /// - DOCX
  ///
  /// [language] — optional override.
  /// When null, falls back to AppSettings.language.
  /// ================================

  static Future<FormatResult> processImage(
    File file, {
    String profile = 'moderate',
    String? language,
  }) async {
    if (_inFlightImageRequest != null) {
      print(
        "⚠️ OCR request already in-flight; "
        "awaiting the active request instead of queuing a duplicate.",
      );

      return _inFlightImageRequest!;
    }

    final requestFuture = _processImageInternal(
      file,
      profile: profile,
      language: language,
    );

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
      print("⏱️ timeout: ${imageRequestTimeout.inSeconds} seconds");

      final request = http.MultipartRequest('POST', uri);

      request.fields['language'] = lang;
      request.fields['profile'] = profile;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      print("📤 sending image to backend...");

      final streamed = await request.send().timeout(
        imageRequestTimeout,
      );

      print("📥 response received from backend");

      final response = await http.Response.fromStream(streamed);

      final elapsedMs = DateTime.now()
          .difference(requestStartedAt)
          .inMilliseconds;

      final contentType =
          response.headers['content-type'] ?? 'unknown';

      final bodyLength = response.bodyBytes.length;

      print("⏱️ request completed in ${elapsedMs}ms");
      print("📥 status: ${response.statusCode}");
      print("📥 content-type: $contentType");
      print("📥 body length: $bodyLength");

      final bodyPreview = response.body.length > 400
          ? response.body.substring(0, 400)
          : response.body;

      print("📥 body preview: $bodyPreview");

      /// --------------------------------
      /// HTTP ERROR
      /// --------------------------------

      if (response.statusCode != 200) {
        print(
          "⚠️ non-200 response received; "
          "body: ${response.body}",
        );

        throw Exception(
          response.body.isNotEmpty
              ? response.body
              : 'Unknown backend error',
        );
      }

      /// --------------------------------
      /// RESPONSE FORMAT VALIDATION
      /// --------------------------------

      if (!contentType
              .toLowerCase()
              .contains('application/json') &&
          !response.body.trimLeft().startsWith('{')) {
        print(
          "⚠️ response content type/body "
          "does not look like JSON",
        );

        throw const FormatException(
          'Backend response was not JSON.',
        );
      }

      /// --------------------------------
      /// JSON PARSING
      /// --------------------------------

      final data = json.decode(response.body);

      print(
        "📦 parsed json type: ${data.runtimeType}",
      );

      if (data is! Map<String, dynamic>) {
        final mapData =
            Map<String, dynamic>.from(data as Map);

        print(
          "📦 coerced json keys: "
          "${mapData.keys.toList()}",
        );

        return FormatResult.fromJson(mapData);
      }

      print(
        "📦 json keys: ${data.keys.toList()}",
      );

      return FormatResult.fromJson(data);
    }

    /// --------------------------------
    /// TIMEOUT
    /// --------------------------------

    on TimeoutException catch (e) {
      final elapsedSeconds = DateTime.now()
          .difference(requestStartedAt)
          .inSeconds;

      print(
        "⏰ OCR request timed out after "
        "$elapsedSeconds seconds",
      );

      print(
        "⏰ Timeout details: "
        "${e.runtimeType} :: ${e.message}",
      );

      throw Exception(
        'The OCR server took too long to process this image. '
        'Please try a smaller or clearer image.',
      );
    }

    /// --------------------------------
    /// NETWORK ERROR
    /// --------------------------------

    on SocketException catch (e) {
      print("❌ SocketException: $e");

      throw Exception(
        'Could not reach the OCR server. '
        'Check that the phone and computer are on the same Wi-Fi '
        'and try again.',
      );
    }

    /// --------------------------------
    /// FILE ERROR
    /// --------------------------------

    on FileSystemException catch (e) {
      print("❌ FileSystemException: $e");

      throw Exception(
        'The captured image is no longer available. '
        'Please scan it again.',
      );
    }

    /// --------------------------------
    /// JSON / RESPONSE FORMAT ERROR
    /// --------------------------------

    on FormatException catch (e) {
      print(
        "❌ FormatException while decoding OCR response: $e",
      );

      throw Exception(
        'The OCR server returned an invalid response. '
        'Please try again.',
      );
    }

    /// --------------------------------
    /// TYPE ERROR
    /// --------------------------------

    on TypeError catch (e) {
      print(
        "❌ TypeError while building FormatResult: $e",
      );

      throw Exception(
        'The OCR server returned a response '
        'in an unexpected format.',
      );
    }

    /// --------------------------------
    /// EVERYTHING ELSE
    /// --------------------------------

    catch (e) {
      print("❌ FILE API ERROR: $e");

      throw Exception(
        'Unable to process the image: $e',
      );
    }
  }

  /// ================================
  /// 📝 TEXT SIMPLIFICATION
  /// ================================
  ///
  /// Calls POST /process/text-format
  ///
  /// Uses Gemini AI on the backend.
  ///
  /// [language] — optional override.
  /// When null, falls back to AppSettings.language.
  /// ================================

  static Future<String> simplifyText(
    String text, {
    String? language,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/process/text-format',
    );

    final lang = language ?? AppSettings.language;

    try {
      print("📡 Sending text to: $uri");

      print(
        "📝 Input (first 200): "
        "${text.length > 200 ? text.substring(0, 200) : text}",
      );

      print("🌐 Language: $lang");

      final response = await http
          .post(
            uri,
            headers: {
              "Content-Type": "application/json",
            },
            body: json.encode({
              "text": text,
              "language": lang,
            }),
          )
          .timeout(textRequestTimeout);

      print("📥 Status: ${response.statusCode}");
      print("📥 Body: ${response.body}");

      final data = json.decode(response.body);

      if (response.statusCode == 200 &&
          data['success'] == true) {
        return data['formatted_text'] as String;
      } else {
        throw Exception(
          data['error'] ?? "Simplification failed",
        );
      }
    } on TimeoutException catch (e) {
      print(
        "⏰ TEXT API TIMEOUT: "
        "${e.runtimeType} :: ${e.message}",
      );

      throw Exception(
        "Text simplification took too long. "
        "Please try again.",
      );
    } on SocketException catch (e) {
      print("❌ TEXT API SOCKET ERROR: $e");

      throw Exception(
        "Could not reach the backend server.",
      );
    } catch (e) {
      print("❌ TEXT API ERROR: $e");

      throw Exception(
        "Connection failed: $e",
      );
    }
  }

  /// ================================
  /// 📊 STRUCTURED TEXT SIMPLIFICATION
  /// ================================
  ///
  /// Simplifies a table/menu/column model without allowing
  /// Gemini to flatten it into prose.
  ///
  /// The server validates the returned shape and falls back
  /// to the original model when the AI response is unsafe.
  /// ================================

  static Future<StructuredSimplifyResult>
      simplifyStructuredText(
    String text,
    Map<String, dynamic> structuredContent, {
    String? language,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/process/text-format',
    );

    final lang = language ?? AppSettings.language;

    try {
      print(
        "📡 Sending structured text to: $uri",
      );

      final response = await http
          .post(
            uri,
            headers: {
              "Content-Type": "application/json",
            },
            body: json.encode({
              "text": text,
              "language": lang,
              "structured_content": structuredContent,
            }),
          )
          .timeout(textRequestTimeout);

      print(
        "📥 Structured response status: "
        "${response.statusCode}",
      );

      final data =
          json.decode(response.body)
              as Map<String, dynamic>;

      if (response.statusCode == 200 &&
          data['success'] == true) {
        final returned =
            data['structured_content'];

        return StructuredSimplifyResult(
          formattedText:
              data['formatted_text'] as String? ?? text,
          structuredContent:
              returned is Map
                  ? Map<String, dynamic>.from(returned)
                  : structuredContent,
        );
      }

      throw Exception(
        data['error'] ??
            "Structured simplification failed",
      );
    } on TimeoutException catch (e) {
      print(
        "⏰ STRUCTURED TEXT TIMEOUT: "
        "${e.runtimeType} :: ${e.message}",
      );

      throw Exception(
        "Structured text processing took too long. "
        "Please try again.",
      );
    } on SocketException catch (e) {
      print(
        "❌ STRUCTURED TEXT SOCKET ERROR: $e",
      );

      throw Exception(
        "Could not reach the backend server.",
      );
    } catch (e) {
      print(
        "❌ STRUCTURED TEXT API ERROR: $e",
      );

      throw Exception(
        "Connection failed: $e",
      );
    }
  }
}

/// =======================================
/// 📦 STRUCTURED SIMPLIFY RESULT
/// =======================================

class StructuredSimplifyResult {
  final String formattedText;

  final Map<String, dynamic> structuredContent;

  const StructuredSimplifyResult({
    required this.formattedText,
    required this.structuredContent,
  });
}