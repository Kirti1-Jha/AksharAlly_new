import 'package:flutter/material.dart';
import '../models/library_item.dart';
import '../services/library_storage.dart';
import 'output_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

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
        final LibraryItem item = items[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(item.title),
            subtitle: Text(
              item.content,
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // B1 FIX: use displayText — opens saved content directly
              // without calling any backend endpoint or running Gemini AI.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OutputScreen(displayText: item.content),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
