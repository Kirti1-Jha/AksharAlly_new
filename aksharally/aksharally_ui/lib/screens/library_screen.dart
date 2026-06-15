import 'package:flutter/material.dart';
import '../models/library_item.dart';
import 'reader_screen.dart';
import '../services/library_storage.dart';
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  List<LibraryItem> getLibraryItems() {
    return [
      LibraryItem(
        title: "Sample Reading 1",
        content:
            "This is a saved simplified text example for library preview.",
        date: DateTime.now(),
      ),
      LibraryItem(
        title: "Sample Reading 2",
        content:
            "Library items will later be saved automatically after simplification.",
        date: DateTime.now(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = LibraryStorage.getItems();
    if (items.isEmpty) {
  return const Center(
    child: Text("No saved readings yet"),
  );
}

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(item.title),
            subtitle: Text(
              item.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ReaderScreen(initialText: item.content),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}