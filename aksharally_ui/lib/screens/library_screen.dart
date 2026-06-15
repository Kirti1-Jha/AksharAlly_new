import 'package:flutter/material.dart';
import '../models/library_item.dart';
import '../services/library_storage.dart';
import 'reader_screen.dart';

/// Displays the user's saved readings.
///
/// Features:
///   - Newest item shown first.
///   - Swipe left (endToStart) to delete with a red bin background.
///   - Tapping an item reopens it in ReaderScreen with its saved profile and
///     formatted text applied instantly — no API calls on reopen.
///   - Save date displayed as "Jun 14, 2026".
///   - Rebuilds when items change (StatefulWidget + setState on delete).
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // Local working copy, refreshed from LibraryStorage every time this screen
  // mounts (i.e., every time the user switches to the Library tab).
  late List<LibraryItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(LibraryStorage.getItems());
  }

  // ── Date formatting ──────────────────────────────────────────────────────
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ── Delete ───────────────────────────────────────────────────────────────
  Future<void> _deleteItem(LibraryItem item) async {
    LibraryStorage.removeItem(item);
    await LibraryStorage.save();
    setState(() {
      _items.remove(item);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_outline, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No saved readings yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 6),
              Text(
                'Tap Save after simplifying text to add items here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item count header
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            '${_items.length} saved ${_items.length == 1 ? 'reading' : 'readings'}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        ...List.generate(_items.length, (index) {
          final item = _items[index];

          return Dismissible(
            // Use ISO date string as a stable, unique key per item.
            key: Key(item.date.toIso8601String()),
            direction: DismissDirection.endToStart,

            // Red delete background revealed on swipe.
            background: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, color: Colors.white, size: 26),
                  SizedBox(height: 4),
                  Text('Delete',
                      style: TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),

            // Remove from storage and rebuild the list on dismiss.
            onDismissed: (_) => _deleteItem(item),

            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _profileIcon(item.profile),
                title: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      item.simplifiedText.replaceAll('\n\n', ' '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    // Date + profile chip row
                    Row(
                      children: [
                        Text(
                          _formatDate(item.date),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        _profileChip(item.profile),
                      ],
                    ),
                  ],
                ),
                trailing:
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),

                // Reopen in ReaderScreen with saved profile and text.
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReaderScreen(libraryItem: item),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Profile helpers ───────────────────────────────────────────────────────

  Widget _profileIcon(String profile) {
    final color = _profileColor(profile);
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.15),
      child: Icon(_profileIconData(profile), color: color, size: 20),
    );
  }

  Widget _profileChip(String profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _profileColor(profile).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        profile[0].toUpperCase() + profile.substring(1),
        style: TextStyle(
          fontSize: 10,
          color: _profileColor(profile),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _profileColor(String profile) {
    switch (profile) {
      case 'mild':   return Colors.green.shade700;
      case 'severe': return Colors.red.shade700;
      default:       return Colors.orange.shade700;  // moderate
    }
  }

  IconData _profileIconData(String profile) {
    switch (profile) {
      case 'mild':   return Icons.accessibility_new;
      case 'severe': return Icons.accessibility;
      default:       return Icons.person_outline;
    }
  }
}
