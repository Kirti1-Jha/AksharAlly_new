import 'package:flutter/material.dart';

import '../theme/accessibility_settings.dart';
import '../theme/app_theme.dart';

/// Renders the optional OCR layout model without flattening it into prose.
/// This widget is intentionally tolerant of missing fields so older or
/// partially-recognised documents can still be displayed safely.
class StructuredContentView extends StatelessWidget {
  final Map<String, dynamic> content;

  const StructuredContentView({
    super.key,
    required this.content,
  });

  TextStyle get _bodyStyle => TextStyle(
        color: AccessibilitySettings.textColor(),
        fontSize: 18,
        height: 1.55,
      );

  @override
  Widget build(BuildContext context) {
    final blocks = (content['blocks'] as List?)
            ?.whereType<Map>()
            .map((block) => Map<String, dynamic>.from(block))
            .toList() ??
        const <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          if (index > 0) const SizedBox(height: AppTheme.spaceMD),
          _buildBlock(blocks[index]),
        ],
      ],
    );
  }

  Widget _buildBlock(Map<String, dynamic> block) {
    switch (block['type']) {
      case 'table':
        return _buildTable(block);
      case 'menu_section':
        return _buildMenuSection(block);
      case 'columns':
        return _buildColumns(block);
      default:
        return Text(block['text'] as String? ?? '', style: _bodyStyle);
    }
  }

  Widget _buildTable(Map<String, dynamic> block) {
    final headers = (block['headers'] as List?)
            ?.map((value) => value?.toString() ?? '')
            .toList() ??
        const <String>[];
    final rows = (block['rows'] as List?)
            ?.whereType<List>()
            .map((row) => row.map((value) => value?.toString() ?? '').toList())
            .toList() ??
        const <List<String>>[];
    final columnCount = headers.length;
    if (columnCount == 0) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(
          color: AppTheme.primaryBlue.withOpacity(0.35),
          width: 1,
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.10),
            ),
            children: headers
                .map((header) => _tableCell(header, isHeader: true))
                .toList(),
          ),
          for (final row in rows)
            TableRow(
              children: List.generate(
                columnCount,
                (index) => _tableCell(
                  index < row.length ? row[index] : '',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableCell(String value, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        value.isEmpty ? ' ' : value,
        style: _bodyStyle.copyWith(
          fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMenuSection(Map<String, dynamic> block) {
    final items = (block['items'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        const <Map<String, dynamic>>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          block['title']?.toString() ?? 'Menu',
          style: _bodyStyle.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
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
                    Text(
                      items[index]['name']?.toString() ?? '',
                      style: _bodyStyle.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if ((items[index]['description']?.toString() ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          items[index]['description'].toString(),
                          style: _bodyStyle.copyWith(fontSize: 16),
                        ),
                      ),
                  ],
                ),
              ),
              if ((items[index]['price']?.toString() ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    items[index]['price'].toString(),
                    style: _bodyStyle.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildColumns(Map<String, dynamic> block) {
    final columns = (block['columns'] as List?)
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
              child: Text(line, style: _bodyStyle),
            ),
        ],
      ],
    );
  }
}