import '../models/library_item.dart';

class LibraryStorage {
  static final List<LibraryItem> items = [];

  static void addItem(LibraryItem item) {
    items.insert(0, item);
  }

  static List<LibraryItem> getItems() {
    return items;
  }
}