import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../services/library_storage.dart';
import '../models/library_item.dart';
import '../services/tts_service.dart';
import '../theme/app_settings.dart';

class ReaderScreen extends StatefulWidget {
  final String? initialText;

  const ReaderScreen({super.key, this.initialText});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  File? selectedImage;
  String simplifiedText = '';
  bool isLoading = false;

  final TTSService _tts = TTSService();

  double speechRate = 0.4;
  bool autoRead = true;

  List<String> words = [];
  int currentIndex = -1;
  Timer? _timer;

  static const blueGradient = [
    Color(0xFF1565C0),
    Color(0xFF42A5F5),
  ];

  static const creamGradient = [
    Color(0xFFFFF3E0),
    Color(0xFFFFE0B2),
  ];

  static const yellowGradient = [
    Color(0xFFFFF59D),
    Color(0xFFFFF176),
  ];

  @override
  void initState() {
    super.initState();
    _tts.init();

    if (widget.initialText != null) {
      simplifyInitialText(); // ✅ NEW LINE
    }
  }
  Future<void> simplifyInitialText() async {
  setState(() {
    isLoading = true;
  });

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
    setState(() {
      simplifiedText = "❌ Error: $e";
    });
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  Color getBackgroundColor() {
    if (AppSettings.themeMode == 1) {
      return const Color(0xFF1E1E1E);
    }
    if (AppSettings.themeMode == 2) {
      return const Color(0xFFF4ECD8);
    }
    return Colors.white;
  }

  Color getTextColor() {
    return AppSettings.themeMode == 1 ? Colors.white : Colors.black;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
        simplifiedText = '';
        words = [];
      });
    }
  }

  Future<void> onSimplifyPressed() async {
    if (selectedImage == null) {
      setState(() {
        simplifiedText = "⚠️ Please select an image first.";
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.processImage(selectedImage!);

      setState(() {
        simplifiedText = result;
        words = result.split(" ");
      });

      if (autoRead) {
        await _tts.setRate(speechRate);
        startReading();
      }
    } catch (e) {
      setState(() {
        simplifiedText = "❌ Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void startReading() async {
    if (simplifiedText.isEmpty) return;

    await _tts.setRate(speechRate);
    currentIndex = 0;

    await _tts.speak(simplifiedText);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (currentIndex < words.length - 1) {
        setState(() {
          currentIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void stopReading() async {
    await _tts.stop();
    _timer?.cancel();

    setState(() {
      currentIndex = -1;
    });
  }

  Widget buildHighlightedText() {
    if (simplifiedText.isEmpty) {
      return Text(
        'Simplified text will appear here...',
        style: TextStyle(
          fontSize: AppSettings.fontSize,
          color: getTextColor(),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 10,
      children: List.generate(words.length, (index) {
        return Text(
          words[index],
          style: TextStyle(
            fontSize: AppSettings.fontSize,
            height: AppSettings.lineSpacing,
            color: index == currentIndex ? Colors.red : getTextColor(),
            fontWeight:
                index == currentIndex ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBackgroundColor(),

      /// HEADER
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
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            /// IMAGE
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
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

            /// BUTTONS
            _yellowButton("Choose Image", pickImage),

            const SizedBox(height: 10),

            _yellowButton(
              "Simplify Text",
              isLoading ? () {} : onSimplifyPressed,
              isLoading: isLoading,
            ),

            const SizedBox(height: 10),

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

            /// AUTO READ
            SwitchListTile(
              title: Text(
                "Auto Read",
                style: TextStyle(color: getTextColor()),
              ),
              value: autoRead,
              onChanged: (v) => setState(() => autoRead = v),
            ),

            const SizedBox(height: 20),

            /// OUTPUT BOX
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
          ],
        ),
      ),
    );
  }

  /// 🔥 UPDATED BUTTON WITH ICON SUPPORT
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
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}