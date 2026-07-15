import 'package:flutter/material.dart';
import '../models/library_item.dart';
import '../services/library_storage.dart';
import '../theme/app_theme.dart';
import 'output_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {

  // ── delete ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(int index, LibraryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete reading?"),
        content: Text(
          '"${item.title}" will be permanently removed from your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      LibraryStorage.removeItem(index);
      setState(() {});
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final items = LibraryStorage.getItems();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_outlined,
                size: 48, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              "No saved readings yet",
              style: TextStyle(color: Colors.white.withOpacity(0.75)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Library",
          style: AppTheme.titleStyle.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        ...List.generate(items.length, (index) {
          final item = items[index];
          return _libraryTile(index, item);
        }),
      ],
    );
  }

  // ── tile ──────────────────────────────────────────────────────────────────

  Widget _libraryTile(int index, LibraryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      decoration: BoxDecoration(
        color:        Colors.white,
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
        leading: _sourceIcon(item.sourceType),
        title: Text(
          item.title,
          style: AppTheme.bodyStrongStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.content,
          maxLines:  2,
          overflow:  TextOverflow.ellipsis,
          style: AppTheme.captionStyle,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppTheme.textMuted),
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
          // Opens saved content — saveOnLoad defaults to false, no duplicate.
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

  // ── source icon chip ──────────────────────────────────────────────────────

  Widget _sourceIcon(String sourceType) {
    final IconData icon;
    switch (sourceType) {
      case 'image':      icon = Icons.camera_alt_outlined;    break;
      case 'pdf':        icon = Icons.picture_as_pdf_outlined; break;
      case 'docx':       icon = Icons.description_outlined;   break;
      case 'text':       icon = Icons.edit_outlined;          break;
      case 'simplified': icon = Icons.auto_awesome_outlined;  break;
      default:           icon = Icons.menu_book_outlined;
    }
    return Container(
      padding:    const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:        AppTheme.accentCream,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
    );
  }
}
