import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_settings.dart';
import '../services/library_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double fontSize    = AppSettings.fontSize;
  double lineSpacing = AppSettings.lineSpacing;
  int    selectedTheme    = AppSettings.themeMode;
  String selectedLanguage = AppSettings.language;

  Color getBackgroundColor() {
    if (selectedTheme == 1) return const Color(0xFF1E1E1E);
    if (selectedTheme == 2) return const Color(0xFFF4ECD8);
    return Colors.white;
  }

  Color getTextColor() =>
      selectedTheme == 1 ? Colors.white : Colors.black;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        Text("Accessibility Settings", style: AppTheme.headingStyle),

        const SizedBox(height: 25),

        // ── FONT SIZE ────────────────────────────────────────────────────
        const Text("Font Size"),
        Slider(
          value:     fontSize,
          min:       14,
          max:       30,
          divisions: 8,
          label:     fontSize.toStringAsFixed(0),
          onChanged: (value) {
            setState(() {
              fontSize = value;
              AppSettings.fontSize = value;
            });
          },
        ),

        const SizedBox(height: 10),

        // ── LINE SPACING ─────────────────────────────────────────────────
        const Text("Line Spacing"),
        Slider(
          value:     lineSpacing,
          min:       1.0,
          max:       2.5,
          divisions: 6,
          label:     lineSpacing.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              lineSpacing = value;
              AppSettings.lineSpacing = value;
            });
          },
        ),

        const SizedBox(height: 20),

        // ── READING THEME ────────────────────────────────────────────────
        const Text("Reading Theme"),
        const SizedBox(height: 10),
        Row(
          children: [
            _themeButton("Light", 0),
            const SizedBox(width: 10),
            _themeButton("Dark",  1),
            const SizedBox(width: 10),
            _themeButton("Sepia", 2),
          ],
        ),

        const SizedBox(height: 24),

        // ── LANGUAGE ─────────────────────────────────────────────────────
        const Text("Language"),
        const SizedBox(height: 10),
        Row(
          children: [
            _languageButton("English", "en"),
            const SizedBox(width: 10),
            _languageButton("हिंदी",   "hi"),
          ],
        ),

        const SizedBox(height: 30),

        // ── PREVIEW ──────────────────────────────────────────────────────
        const Text("Preview"),
        const SizedBox(height: 10),
        Container(
          width:   double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        getBackgroundColor(),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            selectedLanguage == 'hi'
                ? "यह आपके पढ़ने का टेक्स्ट ऐसा दिखेगा।"
                : "This is how your reading text will look.",
            style: TextStyle(
              fontSize: fontSize,
              height:   lineSpacing,
              color:    getTextColor(),
            ),
          ),
        ),

        const SizedBox(height: 30),

        // ── READING HISTORY ───────────────────────────────────────────────
        Text("Reading History", style: AppTheme.titleStyle),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon:  const Icon(Icons.delete_sweep_outlined,
                color: Colors.redAccent),
            label: const Text(
              "Clear Reading History",
              style: TextStyle(color: Colors.redAccent),
            ),
            style: OutlinedButton.styleFrom(
              side:    const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape:   RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
            onPressed: _confirmClearHistory,
          ),
        ),
      ],
    );
  }

  // ── clear history dialog ──────────────────────────────────────────────────

  Future<void> _confirmClearHistory() async {
    final count = LibraryStorage.getItems().length;

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reading history is already empty.")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear reading history?"),
        content: Text(
          "This will permanently delete all $count saved "
          "${count == 1 ? 'reading' : 'readings'}. "
          "This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      LibraryStorage.clearAll();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reading history cleared.")),
      );
    }
  }

  // ── theme button ──────────────────────────────────────────────────────────
  Widget _themeButton(String title, int index) {
    final bool isSelected = selectedTheme == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedTheme      = index;
            AppSettings.themeMode = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── language button ───────────────────────────────────────────────────────
  Widget _languageButton(String label, String code) {
    final bool isSelected = selectedLanguage == code;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedLanguage  = code;
            AppSettings.language = code;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
