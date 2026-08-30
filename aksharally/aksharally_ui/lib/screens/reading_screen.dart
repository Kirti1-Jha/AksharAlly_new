import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/format_result.dart';
import 'output_screen.dart';

/// Public enum so HomeScreen can specify which tab opens by default.
enum ReadingTab { scan, type, upload }

enum _ProcessMode { formatOnly, simplifyFormat }

class ReadingScreen extends StatefulWidget {
  final ReadingTab initialTab;

  const ReadingScreen({
    super.key,
    this.initialTab = ReadingTab.scan,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {

  // ── Local UI state ─────────────────────────────────────────────────────────
  late ReadingTab _tab;
  _ProcessMode _mode = _ProcessMode.formatOnly;

  // Language and profile are LOCAL to this screen.
  // They are NEVER written to AppSettings — they are only passed into API
  // calls via the optional language: and profile: parameters.
  String _language = 'en';
  String _profile  = 'moderate';

  // Input state
  final _textController = TextEditingController();
  final _picker         = ImagePicker();
  File?   _pickedFile;
  String? _pickedFileName;

  // Processing state
  bool    _isLoading = false;
  String? _error;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;

    // Recover an image if Android recreated MainActivity
    // while the camera/gallery picker was open.
    _retrieveLostImage();
  }

  Future<void> _retrieveLostImage() async {
  try {
    final LostDataResponse response = await _picker.retrieveLostData();

    if (response.isEmpty) return;

    if (response.files != null && response.files!.isNotEmpty) {
      final XFile xf = response.files!.first;
      final file = File(xf.path);

      if (!await file.exists()) return;
      if (await file.length() == 0) return;

      if (!mounted) return;

      setState(() {
        _pickedFile = file;
        _pickedFileName = xf.name;
        _error = null;
      });
    } else if (response.exception != null) {
      if (!mounted) return;

      setState(() {
        _error = response.exception.toString();
      });
    }
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _error = e.toString().replaceFirst('Exception: ', '');
    });
  }
}

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ── Input helpers ───────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? xf = await _picker.pickImage(
        source: source,
        // Keep the camera's full-resolution capture. JPEG compression here
        // can remove small characters, punctuation, prices, and table lines.
        preferredCameraDevice: CameraDevice.rear,
      );
      if (xf == null) return;

      final file = File(xf.path);
      if (!await file.exists()) {
        throw Exception('The camera did not return a readable image.');
      }
      if (await file.length() == 0) {
        throw Exception('The captured image is empty. Please scan it again.');
      }

      setState(() {
        _pickedFile     = file;
        _pickedFileName = xf.name;
        _error          = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type:              FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'txt', 'png', 'jpg', 'jpeg'],
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.first;
      if (picked.path == null) return;
      setState(() {
        _pickedFile     = File(picked.path!);
        _pickedFileName = picked.name;
        _error          = null;
      });
    } catch (e) {
      setState(() => _error = 'Could not open file picker.');
    }
  }

  void _clearPick() => setState(() {
    _pickedFile     = null;
    _pickedFileName = null;
  });

  // ── Continue action ─────────────────────────────────────────────────────────

  Future<void> _onContinue() async {
    if (_tab == ReadingTab.type && _textController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter some text before continuing.');
      return;
    }
    if (_tab != ReadingTab.type && _pickedFile == null) {
      setState(() => _error = _tab == ReadingTab.scan
          ? 'Please capture or select an image first.'
          : 'Please select a file first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error     = null;
    });

    try {
      await _runPipelineAndNavigate();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error     = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  /// Executes the correct pipeline for the current tab + mode combination
  /// and pushes the result to ReaderScreen.
  ///
  /// Language and profile are passed EXPLICITLY to every API call.
  /// AppSettings is never mutated here.
  Future<void> _runPipelineAndNavigate() async {

    // ── Typed text ──────────────────────────────────────────────────────────
    if (_tab == ReadingTab.type) {
      final text = _textController.text.trim();

      if (_mode == _ProcessMode.formatOnly) {
        // No API call — text passed directly to the reader.
        _push(OutputScreen(displayText: text, saveOnLoad: true));
        return;
      }

      // Simplify + Format: Gemini call with local language, then show result.
      final simplified = await ApiService.simplifyText(
        text,
        language: _language,   // local state — AppSettings untouched
      );
      _push(OutputScreen(displayText: simplified, saveOnLoad: true));
      return;
    }

    // ── Image or file ───────────────────────────────────────────────────────
    final file = _pickedFile!;
    if (!await file.exists() || await file.length() == 0) {
      throw Exception('The selected image is no longer available. Please scan it again.');
    }

    if (_mode == _ProcessMode.formatOnly) {
      // OCR + dyslexia formatting (no Gemini).
      final result = await ApiService.processImage(
        file,
        language: _language,   // local state — AppSettings untouched
        profile:  _profile,    // local state — AppSettings untouched
      );
      _push(OutputScreen(initialFormatResult: result));
      return;
    }

    // Simplify + Format: retain structured OCR. Gemini can simplify prose
    // fields, but must not flatten tables or menus into a paragraph.
    final formatResult = await ApiService.processImage(
      file,
      language: _language,
      profile:  _profile,
    );
    final blocks = formatResult.structuredContent?['blocks'] as List?;
    final hasStructuredLayout = blocks?.any((block) =>
            block is Map && block['type'] != 'paragraph') ??
        false;
    if (hasStructuredLayout) {
      final simplified = await ApiService.simplifyStructuredText(
        formatResult.rawText,
        formatResult.structuredContent!,
        language: _language,
      );
      _push(OutputScreen(
        initialFormatResult: formatResult.copyWith(
          processedText: simplified.formattedText,
          structuredContent: simplified.structuredContent,
        ),
      ));
      return;
    }

    final simplified = await ApiService.simplifyText(
      formatResult.rawText,
      language: _language,
    );
    _push(OutputScreen(displayText: simplified, saveOnLoad: true));
  }

  void _push(Widget screen) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:          _buildAppBar(),
      body: Column(
        children: [
          _buildTabStrip(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputArea(),
                  const SizedBox(height: AppTheme.spaceLG),
                  _buildControlsPanel(),
                  if (_error != null) ...[
                    const SizedBox(height: AppTheme.spaceMD),
                    _buildErrorBanner(),
                  ],
                  const SizedBox(height: AppTheme.spaceLG),
                  _buildContinueButton(),
                  const SizedBox(height: AppTheme.spaceMD),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation:       0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.creamGradient,
        ),
      ),
      leading: IconButton(
        icon:      const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: ShaderMask(
        shaderCallback: (bounds) =>
            AppTheme.brandGradient.createShader(bounds),
        child: const Text(
          'AksharAlly',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize:   22,
            color:      Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Tab strip ───────────────────────────────────────────────────────────────

  Widget _buildTabStrip() {
    return Container(
      color: AppTheme.accentCream,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical:   AppTheme.spaceSM,
      ),
      child: Row(
        children: [
          _tabItem(ReadingTab.scan,   Icons.document_scanner_outlined, 'Scan'),
          const SizedBox(width: AppTheme.spaceXS),
          _tabItem(ReadingTab.type,   Icons.edit_outlined,             'Type'),
          const SizedBox(width: AppTheme.spaceXS),
          _tabItem(ReadingTab.upload, Icons.upload_file_outlined,      'Upload'),
        ],
      ),
    );
  }

  Widget _tabItem(ReadingTab tab, IconData icon, String label) {
    final selected = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _tab            = tab;
          _pickedFile     = null;
          _pickedFileName = null;
          _error          = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:        selected ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17,
                  color: selected ? Colors.white : AppTheme.primaryBlue),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color:      selected ? Colors.white : AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Input areas ─────────────────────────────────────────────────────────────

  Widget _buildInputArea() {
    switch (_tab) {
      case ReadingTab.scan:   return _buildScanArea();
      case ReadingTab.type:   return _buildTypeArea();
      case ReadingTab.upload: return _buildUploadArea();
    }
  }

  Widget _buildScanArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _outlineButton(
                icon:  Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: _outlineButton(
                icon:  Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMD),
        if (_pickedFile != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: Image.file(_pickedFile!, height: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          _selectedFileRow(),
        ] else
          _emptyStatePlaceholder(
            icon:    Icons.image_search_outlined,
            message: 'No image selected yet.\nUse Camera or Gallery above.',
          ),
      ],
    );
  }

  Widget _buildTypeArea() {
    return TextField(
      controller: _textController,
      maxLines:   null,
      minLines:   7,
      decoration: InputDecoration(
        hintText:    'Type or paste your text here…',
        filled:      true,
        fillColor:   AppTheme.lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide:   BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(AppTheme.spaceMD),
      ),
      style: AppTheme.bodyStyle,
    );
  }

  Widget _buildUploadArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _outlineButton(
          icon:  Icons.attach_file_outlined,
          label: 'Choose File  (PDF · DOCX · TXT · Image)',
          onTap: _pickFile,
        ),
        const SizedBox(height: AppTheme.spaceMD),
        if (_pickedFile != null)
          _fileCard()
        else
          _emptyStatePlaceholder(
            icon:    Icons.folder_open_outlined,
            message: 'No file selected yet.\nSupports PDF, DOCX, TXT, and images.',
          ),
      ],
    );
  }

  // ── Controls panel ──────────────────────────────────────────────────────────

  Widget _buildControlsPanel() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color:        AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Language
          Text('Language', style: AppTheme.labelStyle),
          const SizedBox(height: AppTheme.spaceSM),
          _segmentRow(
            options:  const [
              ('en', 'English'),
              ('hi', 'हिन्दी'),
              ('mr', 'मराठी'),
            ],
            selected: _language,
            onSelect: (v) => setState(() => _language = v),
          ),

          const SizedBox(height: AppTheme.spaceMD),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spaceMD),

          // Processing mode
          Text('Processing Mode', style: AppTheme.labelStyle),
          const SizedBox(height: AppTheme.spaceXS),
          _modeRadio(
            value:    _ProcessMode.formatOnly,
            title:    'Format Only',
            subtitle: 'Dyslexia-friendly layout. No AI. Words never changed.',
          ),
          _modeRadio(
            value:    _ProcessMode.simplifyFormat,
            title:    'Simplify + Format',
            subtitle: 'AI simplifies the text, then formats it for easier reading.',
          ),
        ],
      ),
    );
  }

  // ── Error banner ────────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color:        AppTheme.error.withOpacity(0.07),
        border:       Border.all(color: AppTheme.error.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(
              _error!,
              style: AppTheme.captionStyle.copyWith(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  // ── Continue button ─────────────────────────────────────────────────────────

  Widget _buildContinueButton() {
    return SizedBox(
      height: AppTheme.buttonHeight,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor:         AppTheme.primaryBlue,
          foregroundColor:         Colors.white,
          disabledBackgroundColor: AppTheme.primaryBlue.withOpacity(0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width:  22,
                height: 22,
                child: CircularProgressIndicator(
                  color:       Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  // ── Reusable sub-widgets ────────────────────────────────────────────────────

  Widget _outlineButton({
    required IconData    icon,
    required String      label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, color: AppTheme.primaryBlue, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          color:      AppTheme.primaryBlue,
          fontWeight: FontWeight.w600,
          fontSize:   13,
        ),
      ),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical:   AppTheme.spaceMD,
          horizontal: AppTheme.spaceSM,
        ),
        side:  const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
      ),
    );
  }

  Widget _emptyStatePlaceholder({
    required IconData icon,
    required String   message,
  }) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        border:       Border.all(color: AppTheme.primaryBlue.withOpacity(0.18)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        color:        AppTheme.accentCream.withOpacity(0.35),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30,
                color: AppTheme.primaryBlue.withOpacity(0.35)),
            const SizedBox(height: AppTheme.spaceSM),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTheme.captionStyle),
          ],
        ),
      ),
    );
  }

  Widget _selectedFileRow() {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
        const SizedBox(width: AppTheme.spaceXS),
        Expanded(
          child: Text(
            _pickedFileName ?? 'Image selected',
            style:    AppTheme.captionStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: _clearPick,
          child: const Text('Clear',
              style: TextStyle(color: AppTheme.primaryBlue)),
        ),
      ],
    );
  }

  Widget _fileCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border:       Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined,
              color: AppTheme.primaryBlue, size: 28),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pickedFileName ?? 'File selected',
                  style:    AppTheme.bodyStrongStyle,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('Ready to process', style: AppTheme.captionStyle),
              ],
            ),
          ),
          IconButton(
            icon:      const Icon(Icons.close, size: 20),
            onPressed: _clearPick,
            tooltip:   'Remove',
          ),
        ],
      ),
    );
  }

  Widget _segmentRow({
    required List<(String, String)> options,
    required String                 selected,
    required void Function(String)  onSelect,
  }) {
    return Row(
      children: options.map((opt) {
        final isSelected = opt.$1 == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              margin:   const EdgeInsets.symmetric(horizontal: 2),
              padding:  const EdgeInsets.symmetric(vertical: AppTheme.spaceSM),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.primaryBlue.withOpacity(0.3),
                ),
              ),
              child: Text(
                opt.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _modeRadio({
    required _ProcessMode value,
    required String       title,
    required String       subtitle,
  }) {
    final isSelected = _mode == value;
    return GestureDetector(
      onTap: () => setState(() => _mode = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<_ProcessMode>(
              value:                value,
              groupValue:           _mode,
              onChanged:            (v) => setState(() => _mode = v!),
              activeColor:          AppTheme.primaryBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity:        VisualDensity.compact,
            ),
            const SizedBox(width: AppTheme.spaceXS),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyStrongStyle.copyWith(
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.textDark,
                      ),
                    ),
                    Text(subtitle, style: AppTheme.captionStyle),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
