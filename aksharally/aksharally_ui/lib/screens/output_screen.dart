import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../services/library_storage.dart';
import '../models/library_item.dart';
import '../models/format_result.dart';
import '../services/tts_service.dart';
import '../theme/accessibility_settings.dart';
import '../widgets/highlighted_text_view.dart';
import '../widgets/reading_customize_sheet.dart';

/// OutputScreen — Phase 3A migration target for ReaderScreen.
///
/// This is a behavioral-parity port, not a redesign: same constructor
/// contract, same load paths, same playback/highlighting/customize logic.
/// Rendering and the customize sheet are delegated to extracted widgets
/// (HighlightedTextView, showReadingCustomizeSheet); everything else,
/// including all TTS/timer/playback state, lives directly on this
/// screen's State exactly as it did in ReaderScreen.
///
/// ReaderScreen itself is left completely untouched as rollback
/// protection — it is simply no longer referenced by navigation.
class OutputScreen extends StatefulWidget {
  /// Path A — Enter Text screen: AI-simplifies the text on open.
  final String? initialText;

  /// Path B — Upload File screen: displays a pre-formatted result immediately,
  ///           no extra API call.
  final FormatResult? initialFormatResult;

  /// Path C — Library screen: displays saved content directly, no API call,
  ///           no re-simplification.
  final String? displayText;

  const OutputScreen({
    super.key,
    this.initialText,
    this.initialFormatResult,
    this.displayText,
  });

  @override
  State<OutputScreen> createState() => _OutputScreenState();
}

class _OutputScreenState extends State<OutputScreen> {

  // ── image & text state ────────────────────────────────────────────────────
  File? selectedImage;
  String simplifiedText = '';
  bool isLoading = false;

  // ── profile & format result ───────────────────────────────────────────────
  // _selectedProfile is the profile sent to the backend (always mild/moderate/severe).
  // _isCustomize tracks whether the 'Customize' chip is visually active.
  String _selectedProfile = 'moderate';
  bool   _isCustomize     = false;
  FormatResult? _formatResult;

  // ── TTS ───────────────────────────────────────────────────────────────────
  final TTSService _tts = TTSService();
  double speechRate = 0.4;
  bool autoRead = true;

  List<String> words = [];
  int currentIndex = -1;
  Timer? _timer;

  // ── gradients ─────────────────────────────────────────────────────────────
  static const blueGradient   = [Color(0xFF1565C0), Color(0xFF42A5F5)];
  static const creamGradient  = [Color(0xFFFFF3E0), Color(0xFFFFE0B2)];
  static const yellowGradient = [Color(0xFFFFF59D), Color(0xFFFFF176)];

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tts.init();

    // Restore active profile from persisted accessibility settings.
    _selectedProfile = (AccessibilitySettings.profile == 'customize')
        ? 'moderate'
        : AccessibilitySettings.profile;
    _isCustomize = AccessibilitySettings.profile == 'customize';

    if (widget.initialFormatResult != null) {
      // Path B: pre-formatted result from ReadingScreen (image/file, format-only)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialFormatResult(widget.initialFormatResult!);
      });
    } else if (widget.displayText != null) {
      // Path C: saved library content or already-processed text — display
      // as-is, no API call.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDisplayText(widget.displayText!);
      });
    } else if (widget.initialText != null) {
      // Path A: run AI simplification
      simplifyInitialText();
    }
  }

  // ── word-splitting — removes embedded \n / \n\n ───────────────────────────
  List<String> _splitToWords(String text) => HighlightedTextView.splitToWords(text);

  // ── Path B: load pre-formatted result ────────────────────────────────────
  void _loadInitialFormatResult(FormatResult r) {
    setState(() {
      _formatResult  = r;
      simplifiedText = r.processedText;
      words          = _splitToWords(r.processedText);
    });
    _saveToLibrary(r.processedText, r.sourceType);
    if (autoRead) _tts.setRate(speechRate).then((_) => startReading());
  }

  // ── Path C: load saved library text — no API call ─────────────────────────
  void _loadDisplayText(String text) {
    setState(() {
      simplifiedText = text;
      words          = _splitToWords(text);
    });
    // Do NOT call _saveToLibrary here — already in library.
    // Do NOT call any backend endpoint.
    if (autoRead) _tts.setRate(speechRate).then((_) => startReading());
  }

  // ── Path A: AI simplify on open (Enter Text flow) ─────────────────────────
  Future<void> simplifyInitialText() async {
    setState(() { isLoading = true; });
    try {
      final result = await ApiService.simplifyText(widget.initialText!);
      setState(() {
        simplifiedText = result;
        words          = _splitToWords(result);
      });
      _saveToLibrary(result, 'text');
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

  // ── library save ──────────────────────────────────────────────────────────
  void _saveToLibrary(String content, String sourceType) {
    if (content.isEmpty ||
        content.startsWith('❌') ||
        content.startsWith('⚠️')) return;

    final wordCount = content.split(' ').where((w) => w.isNotEmpty).length;
    final now       = DateTime.now();
    final label     = sourceType.isEmpty ? 'Document' : _cap(sourceType);

    LibraryStorage.addItem(LibraryItem(
      title:      '$label · ${wordCount}w · ${now.day}/${now.month}/${now.year}',
      content:    content,
      date:       now,
      sourceType: sourceType,
    ));
  }

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  // ── accessibility theme helpers ───────────────────────────────────────────
  Color getBackgroundColor() => AccessibilitySettings.backgroundColor();
  Color getTextColor()       => AccessibilitySettings.textColor();

  // ── image picker ──────────────────────────────────────────────────────────
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
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
        profile: _selectedProfile,   // always mild/moderate/severe
      );
      setState(() {
        _formatResult  = result;
        simplifiedText = result.processedText;
        words          = _splitToWords(result.processedText);
      });
      _saveToLibrary(result.processedText, 'image');
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

  // ── Simplify (AI) ─────────────────────────────────────────────────────────
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
        words          = _splitToWords(result);
      });
      _saveToLibrary(result, 'simplified');
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

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    super.dispose();
  }

  // ── profile chip selector ─────────────────────────────────────────────────
  Widget _profileSelector() {
    const presets = ['mild', 'moderate', 'severe'];
    // Active chip is 'customize' if _isCustomize, else _selectedProfile.
    final activeChip = _isCustomize ? 'customize' : _selectedProfile;

    Widget chip(String value, {IconData? icon}) {
      final isSelected = activeChip == value;
      final label      = '${value[0].toUpperCase()}${value.substring(1)}';
      return GestureDetector(
        onTap: () => _onProfileChanged(value),
        child: Container(
          margin:  const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: blueGradient)
                : null,
            color:        isSelected ? null : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                  size:  14,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color:      isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      alignment:  WrapAlignment.center,
      spacing:    4,
      runSpacing: 4,
      children: [
        for (final p in presets) chip(p),
        chip('customize', icon: Icons.tune),
      ],
    );
  }

  // ── profile changed ───────────────────────────────────────────────────────
  Future<void> _onProfileChanged(String profile) async {
    if (profile == 'customize') {
      // Customize is purely client-side. Backend profile stays unchanged.
      setState(() => _isCustomize = true);
      AccessibilitySettings.profile = 'customize';
      await showReadingCustomizeSheet(
        context,
        onChanged: () { if (mounted) setState(() {}); },
      );
      return;
    }

    // Preset selected — apply client-side settings and update backend profile.
    AccessibilitySettings.applyPreset(profile);
    await AccessibilitySettings.save();

    setState(() {
      _selectedProfile = profile;
      _isCustomize     = false;
    });
    // Backend is only called when the user presses "Format Text" or "Simplify";
    // simply updating _selectedProfile is sufficient — no API call here.
  }

  // ── formatting info bar ───────────────────────────────────────────────────
  Widget _formattingInfoBar() {
    final activeProfile = _isCustomize ? 'customize' : _selectedProfile;
    final font          = AccessibilitySettings.fontFamily == 'Atkinson Hyperlegible'
        ? 'Atkinson'
        : AccessibilitySettings.fontFamily;
    final theme = AccessibilitySettings
        .themeLabels[AccessibilitySettings.colorTheme] ?? 'Custom';

    return Container(
      padding:   const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: Colors.blue.shade100),
      ),
      child: Wrap(
        spacing:    8,
        runSpacing: 6,
        children: [
          _infoBadge('Profile', _cap(activeProfile)),
          _infoBadge('Font',    font),
          _infoBadge('Size',
            '${AccessibilitySettings.fontSize.toStringAsFixed(0)}px'),
          _infoBadge('Letter',
            '${AccessibilitySettings.letterSpacing.toStringAsFixed(1)}'),
          _infoBadge('Word',
            '${AccessibilitySettings.wordSpacing.toStringAsFixed(1)}px'),
          _infoBadge('Line',
            '${AccessibilitySettings.lineHeight.toStringAsFixed(1)}×'),
          _infoBadge('Para',
            '${AccessibilitySettings.paragraphSpacing.toStringAsFixed(0)}px'),
          _infoBadge('Theme',   theme),
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

            // ── IMAGE PREVIEW ──────────────────────────────────────────────
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

            // ── CHOOSE IMAGE ───────────────────────────────────────────────
            _yellowButton("Choose Image", pickImage),

            const SizedBox(height: 12),

            // ── PROFILE SELECTOR (mild / moderate / severe / customize) ────
            _profileSelector(),

            const SizedBox(height: 10),

            // ── FORMAT TEXT ────────────────────────────────────────────────
            _yellowButton(
              "Format Text",
              isLoading ? () {} : _onFormatPressed,
              isLoading: isLoading,
            ),

            const SizedBox(height: 10),

            // ── SIMPLIFY (AI) ──────────────────────────────────────────────
            _yellowButton(
              "Simplify (AI)",
              isLoading ? () {} : _onSimplifyPressed,
            ),

            const SizedBox(height: 10),

            // ── FORMATTING INFO BAR (always visible) ──────────────────────
            _formattingInfoBar(),

            const SizedBox(height: 10),

            // ── START / STOP ───────────────────────────────────────────────
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

            // ── AUTO READ SWITCH ───────────────────────────────────────────
            SwitchListTile(
              title: Text(
                "Auto Read",
                style: TextStyle(color: getTextColor()),
              ),
              value:     autoRead,
              onChanged: (v) => setState(() => autoRead = v),
            ),

            const SizedBox(height: 20),

            // ── OUTPUT BOX ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        getBackgroundColor(),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: HighlightedTextView(
                text:         simplifiedText,
                words:        words,
                currentIndex: currentIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
