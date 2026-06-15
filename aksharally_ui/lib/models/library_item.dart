import 'dart:convert';

/// A single saved reading in the user's library.
///
/// Fields:
///   [title]          — auto-generated from first 45 chars of [originalText].
///   [originalText]   — the Gemini-simplified text before formatting/chunking.
///                      Stored so profile changes can re-format on reopen.
///   [simplifiedText] — the formatted text (with \n\n paragraph breaks) that
///                      is displayed directly when the item is reopened.
///   [profile]        — the dyslexia reading profile active at save time.
///   [date]           — timestamp of when the item was saved.
class LibraryItem {
  final String title;
  final String originalText;
  final String simplifiedText;
  final String profile;
  final DateTime date;

  const LibraryItem({
    required this.title,
    required this.originalText,
    required this.simplifiedText,
    required this.profile,
    required this.date,
  });

  /// Serialise to a JSON-compatible map for SharedPreferences storage.
  Map<String, dynamic> toJson() => {
    'title':          title,
    'originalText':   originalText,
    'simplifiedText': simplifiedText,
    'profile':        profile,
    'date':           date.toIso8601String(),
  };

  /// Deserialise from a JSON map read out of SharedPreferences.
  /// Defaults [profile] to "moderate" if the stored value is absent or
  /// unrecognised (guards against data written by older app versions).
  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    const validProfiles = {'mild', 'moderate', 'severe'};
    final rawProfile = json['profile'] as String? ?? 'moderate';

    return LibraryItem(
      title:          json['title']          as String,
      originalText:   json['originalText']   as String,
      simplifiedText: json['simplifiedText'] as String,
      profile:        validProfiles.contains(rawProfile) ? rawProfile : 'moderate',
      date:           DateTime.parse(json['date'] as String),
    );
  }

  // Convenience: encode a list to a JSON string for SharedPreferences.
  static String encodeList(List<LibraryItem> items) =>
      jsonEncode(items.map((i) => i.toJson()).toList());

  // Convenience: decode a JSON string from SharedPreferences to a list.
  static List<LibraryItem> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
