import 'package:flutter/material.dart';
import '../models/library_item.dart';
import '../services/library_storage.dart';
import '../theme/app_theme.dart';
import '../theme/ui_accessibility.dart';
import 'output_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {

  // ── UIAccessibility helpers (re-read on every build after Apply) ──────────
  Color get _bg    => UIAccessibility.backgroundColor;
  Color get _txt   => UIAccessibility.textColor;
  Color get _muted => UIAccessibility.textColor.withOpacity(0.55);

  Color get _cardBg {
    return _bg.computeLuminance() < 0.3
        ? const Color(0xFF2E2E2E)
        : Colors.white;
  }

  Color get _iconChipBg {
    return _bg.computeLuminance() < 0.3
        ? const Color(0xFF3A3A3A)
        : AppTheme.accentCream;
  }

  TextStyle _ts(double size, FontWeight weight, Color color) =>
      UIAccessibility.previewStyleFor(UIAccessibility.fontFamily).copyWith(
        fontSize:           UIAccessibility.fontSize * (size / 15),
        fontWeight:         UIAccessibility.boldTextEnabled ? FontWeight.bold : weight,
        color:              color,
        letterSpacing:      UIAccessibility.letterSpacing,
        wordSpacing:        UIAccessibility.wordSpacing,
        height:             UIAccessibility.lineHeight,
        fontFamilyFallback: const ['Noto Sans', 'sans-serif'],
      );

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(int index, LibraryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reading?'),
        content: Text(
          '"${item.title}" will be permanently removed from your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      LibraryStorage.removeItem(index);
      setState(() {});
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final items = LibraryStorage.getItems();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_outlined,
                size: 48, color: _txt.withOpacity(0.35)),
            const SizedBox(height: 12),
            Text(
              'No saved readings yet',
              style: _ts(14, FontWeight.w500, _muted),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Library', style: _ts(18, FontWeight.w700, _txt)),
        const SizedBox(height: AppTheme.spaceSM),
        ...List.generate(
          items.length,
          (index) => _libraryTile(index, items[index]),
        ),
      ],
    );
  }

  // ── Tile ──────────────────────────────────────────────────────────────────

  Widget _libraryTile(int index, LibraryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      decoration: BoxDecoration(
        color:        _cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD,
          vertical:   AppTheme.spaceXS,
        ),
        leading:  _sourceIcon(item.sourceType),
        title: Text(
          item.title,
          style:    _ts(14, FontWeight.w700, _txt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style:    _ts(12, FontWeight.w400, _muted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward_ios, size: 14, color: _muted),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _confirmDelete(index, item),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.delete_outline,
                    size: 20, color: Colors.redAccent),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OutputScreen(displayText: item.content),
            ),
          );
        },
      ),
    );
  }

  // ── Source icon chip ──────────────────────────────────────────────────────

  Widget _sourceIcon(String sourceType) {
    final IconData icon;
    switch (sourceType) {
      case 'image':      icon = Icons.camera_alt_outlined;     break;
      case 'pdf':        icon = Icons.picture_as_pdf_outlined; break;
      case 'docx':       icon = Icons.description_outlined;    break;
      case 'text':       icon = Icons.edit_outlined;           break;
      case 'simplified': icon = Icons.auto_awesome_outlined;   break;
      default:           icon = Icons.menu_book_outlined;
    }
    return Container(
      padding:    const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:        _iconChipBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
    );
  }
}
