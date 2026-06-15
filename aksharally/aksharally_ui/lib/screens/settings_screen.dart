import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double fontSize = AppSettings.fontSize;
  double lineSpacing = AppSettings.lineSpacing;
  int selectedTheme = AppSettings.themeMode;

  Color getBackgroundColor() {
    if (selectedTheme == 1) return const Color(0xFF1E1E1E);
    if (selectedTheme == 2) return const Color(0xFFF4ECD8);
    return Colors.white;
  }

  Color getTextColor() {
    return selectedTheme == 1 ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        Text(
          "Accessibility Settings",
          style: AppTheme.headingStyle,
        ),

        const SizedBox(height: 25),

        /// FONT SIZE
        const Text("Font Size"),
        Slider(
          value: fontSize,
          min: 14,
          max: 30,
          divisions: 8,
          label: fontSize.toStringAsFixed(0),
          onChanged: (value) {
            setState(() {
              fontSize = value;
              AppSettings.fontSize = value;
            });
          },
        ),

        const SizedBox(height: 10),

        /// LINE SPACING
        const Text("Line Spacing"),
        Slider(
          value: lineSpacing,
          min: 1.0,
          max: 2.5,
          divisions: 6,
          label: lineSpacing.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              lineSpacing = value;
              AppSettings.lineSpacing = value;
            });
          },
        ),

        const SizedBox(height: 20),

        /// THEME
        const Text("Reading Theme"),
        const SizedBox(height: 10),

        Row(
          children: [
            _themeButton("Light", 0),
            const SizedBox(width: 10),
            _themeButton("Dark", 1),
            const SizedBox(width: 10),
            _themeButton("Sepia", 2),
          ],
        ),

        const SizedBox(height: 30),

        /// PREVIEW
        const Text("Preview"),
        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: getBackgroundColor(),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            "This is how your reading text will look.",
            style: TextStyle(
              fontSize: fontSize,
              height: lineSpacing,
              color: getTextColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _themeButton(String title, int index) {
    final bool isSelected = selectedTheme == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedTheme = index;
            AppSettings.themeMode = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? AppTheme.primaryGreen : Colors.grey.shade200,
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
}