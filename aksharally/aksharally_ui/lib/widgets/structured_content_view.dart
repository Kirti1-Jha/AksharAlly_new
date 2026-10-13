import 'package:flutter/material.dart';

import '../theme/accessibility_settings.dart';
import '../theme/app_theme.dart';

/// Renders the optional OCR layout model without flattening it into prose.
/// This widget is intentionally tolerant of missing fields so older or
/// partially-recognised documents can still be displayed safely.
class StructuredContentView extends StatelessWidget {
  final Map<String, dynamic> content;
  final List<String> words;
  final int currentIndex;

  const StructuredContentView({
    super.key,
    required this.content,
    this.words = const [],
    this.currentIndex = -1,
  });

  TextStyle get _bodyStyle => AccessibilitySettings.readingTextStyle(
    color: AccessibilitySettings.textColor(),
  );

  @override
  Widget build(BuildContext context) {
    final highlighter = _StructuredWordHighlighter(
      words: words,
      currentIndex: currentIndex,
      enabled: AccessibilitySettings.wordHighlighting,
    );
    final blocks =
        (content['blocks'] as List?)
            ?.whereType<Map>()
            .map((block) => Map<String, dynamic>.from(block))
            .toList() ??
        const <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          if (index > 0)
            SizedBox(height: AccessibilitySettings.paragraphSpacing),
          _buildBlock(blocks[index], highlighter),
        ],
      ],
    );
  }

  Widget _buildBlock(
    Map<String, dynamic> block,
    _StructuredWordHighlighter highlighter,
  ) {
    switch (block['type']) {
      case 'table':
        return _buildTable(block, highlighter);
      case 'menu_section':
        return _buildMenuSection(block, highlighter);
      case 'columns':
        return _buildColumns(block, highlighter);
      case 'section':
        return _buildSection(block, highlighter);
      default:
        return highlighter.render(block['text'] as String? ?? '', _bodyStyle);
    }
  }

  Widget _buildTable(
    Map<String, dynamic> block,
    _StructuredWordHighlighter highlighter,
  ) {
    final headers =
        (block['headers'] as List?)
            ?.map((value) => value?.toString() ?? '')
            .toList() ??
        const <String>[];
    final rows =
        (block['rows'] as List?)
            ?.whereType<List>()
            .map((row) => row.map((value) => value?.toString() ?? '').toList())
            .toList() ??
        const <List<String>>[];
    final columnCount = headers.length;
    if (columnCount == 0) return const SizedBox.shrink();

    final headerCells = headers
        .map((header) => _tableCell(header, highlighter, isHeader: true))
        .toList();
    final rowCells = rows
        .map(
          (row) => List<Widget>.generate(
            columnCount,
            (index) => _tableCell(
              index < row.length ? row[index] : '',
              highlighter,
            ),
          ),
        )
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnValues = List.generate(
          columnCount,
          (column) => [
            headers[column],
            for (final row in rows) column < row.length ? row[column] : '',
          ],
        );
        // Estimate the width of the longest unbreakable word, not the full
        // sentence. Long descriptions can wrap inside a cell and should not
        // force an otherwise readable 2–3 column table to scroll.
        final preferredWidths = columnValues.map<double>((values) {
          final longestWord = values.fold<int>(0, (longest, value) {
            final wordLength = value
                .split(RegExp(r'\s+'))
                .fold<int>(
                  0,
                  (current, word) =>
                      word.length > current ? word.length : current,
                );
            return wordLength > longest ? wordLength : longest;
          });
          return (longestWord * 8.0 + 28.0).clamp(72.0, 220.0).toDouble();
        }).toList();
        final preferredTotal = preferredWidths.fold<double>(
          0,
          (sum, width) => sum + width,
        );
        final availableWidth = constraints.maxWidth;
        final needsHorizontalScroll =
            !availableWidth.isFinite || preferredTotal > availableWidth;

        final fittingColumnWidths = <int, TableColumnWidth>{};
        if (!needsHorizontalScroll && preferredTotal > 0) {
          final extraWidth = availableWidth - preferredTotal;
          for (var index = 0; index < columnCount; index++) {
            // Give wider-content columns a proportionate share of spare
            // space while keeping all cells at the same column width.
            final share = preferredWidths[index] / preferredTotal;
            fittingColumnWidths[index] = FixedColumnWidth(
              preferredWidths[index] + extraWidth * share,
            );
          }
        }

        final table = Table(
          columnWidths: needsHorizontalScroll ? null : fittingColumnWidths,
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(
            color: AccessibilitySettings.textColor().withOpacity(0.35),
            width: 1,
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: AccessibilitySettings.textColor().withOpacity(0.08),
              ),
              children: headerCells,
            ),
            for (final cells in rowCells) TableRow(children: cells),
          ],
        );

        return needsHorizontalScroll
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: table,
              )
            : table;
      },
    );
  }

  Widget _tableCell(
    String value,
    _StructuredWordHighlighter highlighter, {
    bool isHeader = false,
  }) {
    final style = _bodyStyle.copyWith(
      fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: highlighter.render(value.isEmpty ? ' ' : value, style),
    );
  }

  Widget _buildMenuSection(
    Map<String, dynamic> block,
    _StructuredWordHighlighter highlighter,
  ) {
    final items =
        (block['items'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        const <Map<String, dynamic>>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        highlighter.render(
          block['title']?.toString() ?? 'Menu',
          _bodyStyle.copyWith(
            color: AccessibilitySettings.textColor(),
            fontWeight: FontWeight.w900,
            letterSpacing: AccessibilitySettings.letterSpacing + 0.5,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    highlighter.render(
                      items[index]['name']?.toString() ?? '',
                      _bodyStyle.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if ((items[index]['description']?.toString() ?? '')
                        .isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: highlighter.render(
                          items[index]['description'].toString(),
                          _bodyStyle.copyWith(
                            fontSize: (AccessibilitySettings.fontSize - 2)
                                .clamp(14, double.infinity)
                                .toDouble(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if ((items[index]['price']?.toString() ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: highlighter.render(
                    items[index]['price'].toString(),
                    _bodyStyle.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AccessibilitySettings.textColor(),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildColumns(
    Map<String, dynamic> block,
    _StructuredWordHighlighter highlighter,
  ) {
    final columns =
        (block['columns'] as List?)
            ?.whereType<List>()
            .map((column) => column.map((line) => line.toString()).toList())
            .toList() ??
        const <List<String>>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < columns.length; index++) ...[
          if (index > 0) const Divider(height: 28),
          for (final line in columns[index])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: highlighter.render(line, _bodyStyle),
            ),
        ],
      ],
    );
  }

  Widget _buildSection(
    Map<String, dynamic> block,
    _StructuredWordHighlighter highlighter,
  ) {
    final lines =
        (block['lines'] as List?)
            ?.map((line) => line?.toString() ?? '')
            .where((line) => line.isNotEmpty)
            .toList() ??
        const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        highlighter.render(
          block['title']?.toString() ?? '',
          _bodyStyle.copyWith(
            color: AccessibilitySettings.textColor(),
            fontWeight: FontWeight.w900,
            letterSpacing: AccessibilitySettings.letterSpacing + 0.4,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < lines.length; index++) ...[
          if (index > 0) const SizedBox(height: 6),
          highlighter.render(lines[index], _bodyStyle),
        ],
      ],
    );
  }
}

/// Matches structured reading text back to the flat spoken word list so the
/// same Output Screen progress index highlights text in both renderers.
class _StructuredWordHighlighter {
  _StructuredWordHighlighter({
    required this.words,
    required this.currentIndex,
    required this.enabled,
  });

  final List<String> words;
  final int currentIndex;
  final bool enabled;
  int _wordCursor = 0;

  Widget render(String text, TextStyle style) {
    final matches = RegExp(r'\S+').allMatches(text);
    if (!enabled || currentIndex < 0 || matches.isEmpty) {
      return Text(text, style: style);
    }

    final spans = <InlineSpan>[];
    var textCursor = 0;
    for (final match in matches) {
      if (match.start > textCursor) {
        spans.add(TextSpan(text: text.substring(textCursor, match.start)));
      }
      final token = match.group(0)!;
      final displayIndex = _findDisplayIndex(token);
      spans.add(
        TextSpan(
          text: token,
          style: displayIndex == currentIndex
              ? style.copyWith(color: Colors.red, fontWeight: FontWeight.bold)
              : null,
        ),
      );
      textCursor = match.end;
    }
    if (textCursor < text.length) {
      spans.add(TextSpan(text: text.substring(textCursor)));
    }
    return Text.rich(TextSpan(style: style, children: spans));
  }

  int? _findDisplayIndex(String token) {
    final normalized = _normalize(token);
    if (normalized.isEmpty) return null;
    for (var index = _wordCursor; index < words.length; index++) {
      final candidate = words[index];
      if (candidate == '¶' || candidate == '↵') continue;
      if (_normalize(candidate) != normalized) continue;
      _wordCursor = index + 1;
      return index;
    }
    return null;
  }

  String _normalize(String token) {
    const punctuation = '.,!?;:()[]{}"“”‘’…।॥،؛';
    var start = 0;
    var end = token.length;
    while (start < end && punctuation.contains(token[start])) {
      start++;
    }
    while (end > start && punctuation.contains(token[end - 1])) {
      end--;
    }
    return token.substring(start, end).toLowerCase();
  }
}
