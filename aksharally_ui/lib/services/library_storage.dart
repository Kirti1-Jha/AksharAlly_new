import 'package:shared_preferences/shared_preferences.dart';
import '../models/library_item.dart';

/// Manages the in-memory list of saved readings and their persistence.
///
/// Usage:
///   • Call [load] once in main() alongside AppSettings.load().
///   • Call [addItem] + [save] when the user saves a reading.
///   • Call [removeItem] + [save] when the user deletes an item.
///   • Call [getItems] anywhere to read the current list.
class LibraryStorage {
  static const _kKey = 'library_items';

  // Private backing list — mutated only through the public API.
  static final List<LibraryItem> _items = [];

  // ── Read ───────────────────────────────────────────────────────────────

  /// Returns an unmodifiable view of the current items (newest first).
  static List<LibraryItem> getItems() => List.unmodifiable(_items);

  // ── Write ──────────────────────────────────────────────────────────────

  /// Prepend a new item to the list (newest first).
  /// Call [save] afterwards to persist.
  static void addItem(LibraryItem item) {
    _items.insert(0, item);
  }

  /// Remove a specific [item] from the list by identity.
  /// Call [save] afterwards to persist.
  static void removeItem(LibraryItem item) {
    _items.remove(item);
  }

  // ── Persistence ────────────────────────────────────────────────────────

  /// Load saved items from SharedPreferences into [_items].
  /// Must be awaited once in main() before runApp.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return;

      _items
        ..clear()
        ..addAll(LibraryItem.decodeList(raw));
    } catch (_) {
      // Corrupt or incompatible stored data — start with an empty list.
      _items.clear();
    }
  }

  /// Serialise the current list to SharedPreferences.
  /// Call this after every [addItem] or [removeItem].
  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, LibraryItem.encodeList(_items));
  }
}
