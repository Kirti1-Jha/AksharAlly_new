import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../services/library_storage.dart';
import '../models/library_item.dart';
import '../models/format_result.dart';
import '../services/tts_service.dart';
import '../theme/app_settings.dart';

class ReaderScreen extends StatefulWidget {
  /// Raw text entered manually — passed through Gemini simplification.
  final String? initialText;

  /// Pre-processed library item — skips all API calls and loads instantly.
  final LibraryItem? libraryItem;

  const ReaderScreen({super.key, this.initialText, this.libraryItem});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  // ── Image / text state ──────────────────────────────────────────────────
  File? selectedImage;
  String simplifiedText = '';
  bool isLoading = false;

  // ── TTS ─────────────────────────────────────────────────────────────────
  final TTSService _tts = TTSService();
  double speechRate = 0.4;
  bool autoRead = true;

  // ── Word highlighting ────────────────────────────────────────────────────
  List<String> words = [];
  int currentIndex = -1;
  Timer? _timer;

  // ── Dyslexia formatting ──────────────────────────────────────────────────
  FormatResult? _formatResult;

  // Gemini-simplified text BEFORE formatting/chunking.
  // Always send this (not simplifiedText) to /api/format-text on re-calls.
  String _rawSimplifiedText = '';

  // Restored from AppSettings; updated and persisted on chip tap.
  String _selectedProfile = AppSettings.readingProfile;

  static const _profiles = ['mild', 'moderate', 'severe'];

  // ── Colour constants ─────────────────────────────────────────────────────
  static const blueGradient   = [Color(0xFF1565C0), Color(0xFF42A5F5)];
  static const creamGradient  = [Color(0xFFFFF3E0), Color(0xFFFFE0B2)];
  static const yellowGradient = [Color(0xFFFFF59D), Color(0xFFFFF176)];

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tts.init();
    _selectedProfile = AppSettings.readingProfile;

    if (widget.libraryItem != null) {
      // Load saved item directly — no API calls.
      _loadFromLibraryItem();
    } else if (widget.initialText != null) {
      // Manual text entry — run through Gemini + format pipeline.
      simplifyInitialText();
    }
    // Otherwise: OCR mode — user picks an image manually.
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Library load ─────────────────────────────────────────────────────────
  /// Populates state from a saved [LibraryItem] without any network calls.
  /// Typography is reconstructed via [FormatResult.fromProfile], which mirrors
  /// the backend profile values exactly — so the correct font size, spacing,
  /// and font family are applied on the first build.
  void _loadFromLibraryItem() {
    final item = widget.libraryItem!;
    // Direct assignment — setState not needed in initState (widget not yet built).
    _selectedProfile   = item.profile;
    _rawSimplifiedText = item.originalText;
    simplifiedText     = item.simplifiedText;
    _formatResult      = FormatResult.fromProfile(item.simplifiedText, item.profile);
    words = item.simplifiedText
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();
  }

  // ── Colour helpers ───────────────────────────────────────────────────────
  Color getBackgroundColor() {
    if (AppSettings.themeMode == 1) return const Color(0xFF1E1E1E);
    if (AppSettings.themeMode == 2) return const Color(0xFFF4ECD8);
    return Colors.white;
  }

  Color getTextColor() =>
      AppSettings.themeMode == 1 ? Colors.white : Colors.black;

  // ── Step 1 – simplify manual text ────────────────────────────────────────
  Future<void> simplifyInitialText() async {
    setState(() => isLoading = true);
    try {
      final simplified = await ApiService.simplifyText(widget.initialText!);
      await _applyFormatting(simplified);
      if (autoRead) {
        await _tts.setRate(speechRate);
        startReading();
      }
    } catch (e) {
      setState(() => simplifiedText = '❌ Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ── Step 1 – OCR + simplify image ────────────────────────────────────────
  Future<void> onSimplifyPressed() async {
    if (selectedImage == null) {
      setState(() => simplifiedText = '⚠️ Please select an image first.');
      return;
    }
    setState(() => isLoading = true);
    try {
      final simplified = await ApiService.processImage(selectedImage!);
      await _applyFormatting(simplified);
      if (autoRead) {
        await _tts.setRate(speechRate);
        startReading();
      }
    } catch (e) {
      setState(() => simplifiedText = '❌ Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ── Step 2 – format text with dyslexia profile ───────────────────────────
  /// POSTs [simplified] to /api/format-text and stores the result.
  /// Falls back gracefully — TTS and highlighting are never blocked.
  Future<void> _applyFormatting(String simplified) async {
    final result = await ApiService.formatText(simplified, _selectedProfile);
    setState(() {
      _rawSimplifiedText = simplified;
      _formatResult      = result;
      simplifiedText     = result.processedText;
      words = result.processedText
          .split(RegExp(r'\s+'))
          .where((w) => w.trim().isNotEmpty)
          .toList();
    });
  }

  // ── Profile chip change ───────────────────────────────────────────────────
  Future<void> _onProfileChanged(String profile) async {
    AppSettings.readingProfile = profile;
    await AppSettings.save();
    setState(() => _selectedProfile = profile);

    if (_rawSimplifiedText.isEmpty) return;

    setState(() => isLoading = true);
    try {
      await _applyFormatting(_rawSimplifiedText);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ── Save to Library ───────────────────────────────────────────────────────
  /// Saves the current reading (originalText + simplifiedText + profile) to
  /// [LibraryStorage] and persists to SharedPreferences immediately.
  Future<void> _saveToLibrary() async {
    if (simplifiedText.isEmpty) return;

    final item = LibraryItem(
      title:          _generateTitle(),
      originalText:   _rawSimplifiedText,
      simplifiedText: simplifiedText,
      profile:        _selectedProfile,
      date:           DateTime.now(),
    );

    LibraryStorage.addItem(item);
    await LibraryStorage.save();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to Library'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Auto-generates a title from the first 45 chars of the raw simplified
  /// text (collapses whitespace so newlines don't appear in the title).
  String _generateTitle() {
    final source = _rawSimplifiedText.isNotEmpty
        ? _rawSimplifiedText
        : simplifiedText;
    final cleaned = source.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return 'Saved Reading';
    // trimRight prevents a trailing space before the ellipsis when the
    // 45-character boundary falls mid-whitespace ("...word. " → "...word.")
    return cleaned.length <= 45
        ? cleaned
        : '${cleaned.substring(0, 45).trimRight()}...';
  }

  // ── Image picker ─────────────────────────────────────────────────────────
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImage      = File(picked.path);
        simplifiedText     = '';
        _rawSimplifiedText = '';
        words              = [];
        _formatResult      = null;
      });
    }
  }

  // ── TTS controls ─────────────────────────────────────────────────────────
  void startReading() async {
    if (simplifiedText.isEmpty) return;
    await _tts.setRate(speechRate);
    currentIndex = 0;
    await _tts.speak(simplifiedText);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (currentIndex < words.length - 1) {
        setState(() => currentIndex++);
      } else {
        timer.cancel();
      }
    });
  }

  void stopReading() async {
    await _tts.stop();
    _timer?.cancel();
    setState(() => currentIndex = -1);
  }

  // ── Text display ──────────────────────────────────────────────────────────
  Widget buildHighlightedText() {
    if (simplifiedText.isEmpty) {
      return Text(
        'Simplified text will appear here...',
        style: TextStyle(fontSize: AppSettings.fontSize, color: getTextColor()),
      );
    }

    final double fontSize      = _formatResult?.fontSize      ?? AppSettings.fontSize;
    final double lineHeight    = _formatResult?.lineHeight    ?? AppSettings.lineSpacing;
    final double letterSpacing = _formatResult?.letterSpacing ?? 0.0;
    final double wordSpacing   = _formatResult?.wordSpacing   ?? 0.0;
    final double paraSpacing   = _formatResult?.paragraphSpacing ?? 12.0;

    final paragraphs = simplifiedText.split('\n\n');
    int globalWordOffset = 0;
    final List<Widget> paraWidgets = [];

    for (int p = 0; p < paragraphs.length; p++) {
      final paraWords = paragraphs[p]
          .split(RegExp(r'\s+'))
          .where((w) => w.trim().isNotEmpty)
          .toList();

      final int offset = globalWordOffset;
      globalWordOffset += paraWords.length;

      paraWidgets.add(Wrap(
        spacing: wordSpacing + 4,
        runSpacing: (fontSize * lineHeight) - fontSize,
        children: List.generate(paraWords.length, (i) {
          final globalIdx    = offset + i;
          final isHighlighted = globalIdx == currentIndex;
          return Text(
            paraWords[i],
            style: GoogleFonts.lexend(
              fontSize:      fontSize,
              height:        lineHeight,
              letterSpacing: letterSpacing,
              wordSpacing:   wordSpacing,
              color:      isHighlighted ? Colors.red : getTextColor(),
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }),
      ));

      if (p < paragraphs.length - 1) {
        paraWidgets.add(SizedBox(height: paraSpacing));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paraWidgets,
    );
  }

  // ── Profile chip selector ─────────────────────────────────────────────────
  Widget _buildProfileSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading Profile',
          style: TextStyle(
            color: getTextColor(), fontSize: 13, fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: _profiles.map((profile) {
            final isSelected = profile == _selectedProfile;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  profile[0].toUpperCase() + profile.substring(1),
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.black : getTextColor(),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => _onProfileChanged(profile),
                selectedColor: const Color(0xFFFFF176),
                backgroundColor: Colors.grey.shade200,
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFFFFB300)
                      : Colors.transparent,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Profile metadata badge ────────────────────────────────────────────────
  Widget _buildProfileBadge() {
    if (_formatResult == null) return const SizedBox.shrink();
    final f = _formatResult!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _badgeStat('Font',   f.recommendedFont),
          _badgeStat('Size',   '${f.fontSize.toStringAsFixed(0)}px'),
          _badgeStat('Line',   '${f.lineHeight}×'),
          _badgeStat('Letter', '${f.letterSpacing}px'),
        ],
      ),
    );
  }

  Widget _badgeStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final canSave = simplifiedText.isNotEmpty && !isLoading;

    return Scaffold(
      backgroundColor: getBackgroundColor(),

      appBar: AppBar(
        elevation: 0,
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
              fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            /// IMAGE PREVIEW
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: selectedImage == null
                  ? const Center(child: Text('📷 No image selected'))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(selectedImage!, fit: BoxFit.cover),
                    ),
            ),

            const SizedBox(height: 10),

            /// PROFILE SELECTOR
            _buildProfileSelector(),

            const SizedBox(height: 14),

            /// OCR / SIMPLIFY BUTTONS
            _yellowButton('Choose Image', pickImage),
            const SizedBox(height: 10),
            _yellowButton(
              'Simplify Text',
              isLoading ? () {} : onSimplifyPressed,
              isLoading: isLoading,
            ),
            const SizedBox(height: 10),

            /// START / STOP ROW
            Row(
              children: [
                Expanded(
                  child: _yellowButton('Start', startReading,
                      icon: Icons.play_arrow),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _yellowButton('Stop', stopReading,
                      icon: Icons.stop),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// SAVE TO LIBRARY — enabled only when text is present
            Opacity(
              opacity: canSave ? 1.0 : 0.4,
              child: _yellowButton(
                'Save to Library',
                canSave ? _saveToLibrary : () {},
                icon: Icons.bookmark_add_outlined,
              ),
            ),

            const SizedBox(height: 16),

            /// AUTO READ TOGGLE
            SwitchListTile(
              title: Text('Auto Read',
                  style: TextStyle(color: getTextColor())),
              value: autoRead,
              onChanged: (v) => setState(() => autoRead = v),
            ),

            const SizedBox(height: 10),

            /// PROFILE METADATA BADGE
            _buildProfileBadge(),

            const SizedBox(height: 16),

            /// FORMATTED TEXT OUTPUT
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: getBackgroundColor(),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: buildHighlightedText(),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Shared button widget ─────────────────────────────────────────────────
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
          gradient: const LinearGradient(colors: yellowGradient),
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
                        color: Colors.black, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
