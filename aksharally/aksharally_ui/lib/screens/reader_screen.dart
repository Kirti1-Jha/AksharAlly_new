import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../services/library_storage.dart';
import '../models/library_item.dart';
import '../models/format_result.dart';
import '../services/tts_service.dart';
import '../theme/app_settings.dart';

class ReaderScreen extends StatefulWidget {
  final String? initialText;

  const ReaderScreen({super.key, this.initialText});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {

  // ── image & text state ────────────────────────────────────────────────────
  File? selectedImage;
  String simplifiedText = '';
  bool isLoading = false;

  // ── profile & format result ───────────────────────────────────────────────
  String _selectedProfile = 'moderate';
  FormatResult? _formatResult;

  // ── TTS ───────────────────────────────────────────────────────────────────
  final TTSService _tts = TTSService();
  double speechRate = 0.4;
  bool autoRead = true;

  List<String> words = [];
  int currentIndex = -1;
  Timer? _timer;

  // ── theme colours ─────────────────────────────────────────────────────────
  static const blueGradient   = [Color(0xFF1565C0), Color(0xFF42A5F5)];
  static const creamGradient  = [Color(0xFFFFF3E0), Color(0xFFFFE0B2)];
  static const yellowGradient = [Color(0xFFFFF59D), Color(0xFFFFF176)];

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tts.init();
    if (widget.initialText != null) {
      simplifyInitialText();
    }
  }

  // ── initial-text path (AI simplify — unchanged) ───────────────────────────
  Future<void> simplifyInitialText() async {
    setState(() { isLoading = true; });
    try {
      final result = await ApiService.simplifyText(widget.initialText!);
      setState(() {
        simplifiedText = result;
        words = result.split(" ");
      });
      if (autoRead) {
        await _tts.setRate(speechRate);
        startReading();
      }
    } catch (e) {
      setState(() { simplifiedText = "❌ Error: $e"; });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  // ── theme helpers ─────────────────────────────────────────────────────────
  Color getBackgroundColor() {
    if (AppSettings.themeMode == 1) return const Color(0xFF1E1E1E);
    if (AppSettings.themeMode == 2) return const Color(0xFFF4ECD8);
    return Colors.white;
  }

  Color getTextColor() {
    return AppSettings.themeMode == 1 ? Colors.white : Colors.black;
  }

  // ── image picker ──────────────────────────────────────────────────────────
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImage  = File(picked.path);
        simplifiedText = '';
        words          = [];
        _formatResult  = null;
      });
    }
  }

  // ── Format Text (OCR + dyslexia formatting, no AI) ────────────────────────
  Future<void> _onFormatPressed() async {
    if (selectedImage == null) {
      setState(() { simplifiedText = "⚠️ Please select an image first."; });
      return;
    }
    setState(() { isLoading = true; });
    try {
      final result = await ApiService.processImage(
        selectedImage!,
        profile: _selectedProfile,
      );
      setState(() {
        _formatResult  = result;
        simplifiedText = result.processedText;
        words          = result.processedText.split(" ");
      });
      if (autoRead) {
        await _tts.setRate(speechRate);
        startReading();
      }
    } catch (e) {
      setState(() { simplifiedText = "❌ Error: $e"; });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  // ── Simplify (AI) — Gemini rewrite of already-formatted text ─────────────
  Future<void> _onSimplifyPressed() async {
    if (simplifiedText.isEmpty ||
        simplifiedText.startsWith("⚠️") ||
        simplifiedText.startsWith("❌")) {
      setState(() {
        simplifiedText = "⚠️ Format an image first, then use Simplify.";
      });
      return;
    }
    setState(() { isLoading = true; });
    try {
      final result = await ApiService.simplifyText(simplifiedText);
      setState(() {
        simplifiedText = result;
        words          = result.split(" ");
      });
      if (autoRead) {
        await _tts.setRate(speechRate);
        startReading();
      }
    } catch (e) {
      setState(() { simplifiedText = "❌ Simplify error: $e"; });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  // ── TTS ───────────────────────────────────────────────────────────────────
  void startReading() async {
    if (simplifiedText.isEmpty) return;
    await _tts.setRate(speechRate);
    currentIndex = 0;
    await _tts.speak(simplifiedText);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (currentIndex < words.length - 1) {
        setState(() { currentIndex++; });
      } else {
        timer.cancel();
      }
    });
  }

  void stopReading() async {
    await _tts.stop();
    _timer?.cancel();
    setState(() { currentIndex = -1; });
  }

  // ── text display with FormatResult typography ─────────────────────────────
  Widget buildHighlightedText() {
    if (simplifiedText.isEmpty) {
      return Text(
        'Formatted text will appear here...',
        style: TextStyle(
          fontSize: AppSettings.fontSize,
          color: getTextColor(),
        ),
      );
    }

    return Wrap(
      spacing:    _formatResult?.wordSpacing ?? 6.0,
      runSpacing: 10,
      children: List.generate(words.length, (index) {
        return Text(
          words[index],
          style: TextStyle(
            fontFamily:    _formatResult?.recommendedFont,
            fontSize:      _formatResult?.fontSize      ?? AppSettings.fontSize,
            height:        _formatResult?.lineHeight    ?? AppSettings.lineSpacing,
            letterSpacing: _formatResult?.letterSpacing,
            color: index == currentIndex ? Colors.red : getTextColor(),
            fontWeight:
                index == currentIndex ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }),
    );
  }

  // ── profile selector ──────────────────────────────────────────────────────
  Widget _profileSelector() {
    const profiles = ['mild', 'moderate', 'severe'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: profiles.map((p) {
        final isSelected = _selectedProfile == p;
        return GestureDetector(
          onTap: () => setState(() => _selectedProfile = p),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(colors: blueGradient)
                  : null,
              color: isSelected ? null : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${p[0].toUpperCase()}${p.substring(1)}',
              style: TextStyle(
                color:      isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize:   13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── formatting info bar ───────────────────────────────────────────────────
  Widget _formattingInfoBar() {
    final r = _formatResult!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: Colors.blue.shade100),
      ),
      child: Wrap(
        spacing:    8,
        runSpacing: 6,
        children: [
          _infoBadge('Font',  r.recommendedFont),
          _infoBadge('Size',  '${r.fontSize.toInt()}px'),
          _infoBadge('Line',  '${r.lineHeight}×'),
          _infoBadge('Word',  '${r.wordSpacing}px'),
          _infoBadge('Para',  '${r.paragraphSpacing}px'),
        ],
      ),
    );
  }

  Widget _infoBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: Colors.blue.shade200),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text:  '$label: ',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            TextSpan(
              text:  value,
              style: const TextStyle(
                fontSize:   11,
                color:      Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── button helper ─────────────────────────────────────────────────────────
  Widget _yellowButton(
    String text,
    VoidCallback onTap, {
    bool isLoading = false,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient:     const LinearGradient(colors: yellowGradient),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.black)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.black),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      text,
                      style: const TextStyle(
                        color:      Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBackgroundColor(),

      appBar: AppBar(
        elevation:       0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: creamGradient),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) =>
              const LinearGradient(colors: blueGradient).createShader(bounds),
          child: const Text(
            'AksharAlly',
            style: TextStyle(
              fontSize:   24,
              fontWeight: FontWeight.w900,
              color:      Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            // ── IMAGE PREVIEW ────────────────────────────────────────────
            Container(
              height: 180,
              decoration: BoxDecoration(
                color:        Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: selectedImage == null
                  ? const Center(child: Text("📷 No image selected"))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(selectedImage!, fit: BoxFit.cover),
                    ),
            ),

            const SizedBox(height: 10),

            // ── CHOOSE IMAGE ─────────────────────────────────────────────
            _yellowButton("Choose Image", pickImage),

            const SizedBox(height: 12),

            // ── PROFILE SELECTOR ─────────────────────────────────────────
            _profileSelector(),

            const SizedBox(height: 10),

            // ── FORMAT TEXT ──────────────────────────────────────────────
            _yellowButton(
              "Format Text",
              isLoading ? () {} : _onFormatPressed,
              isLoading: isLoading,
            ),

            const SizedBox(height: 10),

            // ── SIMPLIFY (AI) ────────────────────────────────────────────
            _yellowButton(
              "Simplify (AI)",
              isLoading ? () {} : _onSimplifyPressed,
            ),

            const SizedBox(height: 10),

            // ── FORMATTING INFO BAR (visible after first format) ─────────
            if (_formatResult != null) ...[
              _formattingInfoBar(),
              const SizedBox(height: 10),
            ],

            // ── START / STOP ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _yellowButton(
                    "Start",
                    startReading,
                    icon: Icons.play_arrow,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _yellowButton(
                    "Stop",
                    stopReading,
                    icon: Icons.stop,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── AUTO READ SWITCH ─────────────────────────────────────────
            SwitchListTile(
              title: Text(
                "Auto Read",
                style: TextStyle(color: getTextColor()),
              ),
              value:     autoRead,
              onChanged: (v) => setState(() => autoRead = v),
            ),

            const SizedBox(height: 20),

            // ── OUTPUT BOX ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        getBackgroundColor(),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:     Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: buildHighlightedText(),
            ),
          ],
        ),
      ),
    );
  }
}
