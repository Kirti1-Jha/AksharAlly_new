import 'package:flutter/material.dart';

import '../theme/app_localizations.dart';

class NarrationSpeakerButton extends StatelessWidget {
  const NarrationSpeakerButton({
    super.key,
    required this.text,
    required this.onSpeak,
    this.color,
    this.iconSize = 20,
  });

  final String text;
  final Future<void> Function(String text) onSpeak;
  final Color? color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.text('Listen to explanation'),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      onPressed: text.trim().isEmpty ? null : () => onSpeak(text),
      icon: Icon(
        Icons.volume_up_outlined,
        size: iconSize,
        color: color,
      ),
    );
  }
}
