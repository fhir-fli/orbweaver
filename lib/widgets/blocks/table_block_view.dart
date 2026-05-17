import 'package:flutter/material.dart' hide TableCell, TableRow;
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/mini_markdown.dart';

/// Renders a `TableBlock` as a hand-laid Column of Rows.
///
/// Flutter's built-in `Table` / `DataTable` widgets don't support row-spans
/// or per-row severity backgrounds cleanly, so we build the grid manually.
/// Supports:
///   - column headers (top row, theme-coloured)
///   - optional row headers (left column)
///   - optional group column (contiguous same-`group` rows collapse to
///     a single label on their first row with a shared tinted band)
///   - row severity backgrounds (WHO IMCI pink/yellow/green)
///   - cell content = plain text or bulleted list
class TableBlockView extends StatelessWidget {
  const TableBlockView({required this.block, required this.theme, super.key});

  final TableBlock block;
  final TopicTheme theme;

  static const double _rowVPad = 1;
  static const double _cellHPad = 4;
  static const double _fontSize = 12;
  static const double _headerFontSize = 12;

  bool get _hasRowHeaders => block.rows.any((r) => r.header != null);
  bool get _hasGroups => block.rows.any((r) => r.group != null);

  /// Per-column flex applies only when an explicit weight is given for
  /// every column; otherwise fall back to [fallback] (equal columns for
  /// the header, or the cell's own `span` for data rows).
  bool get _hasColumnFlex =>
      block.columnFlex.isNotEmpty &&
      block.columnFlex.length == block.columns.length;

  int _colFlex(int i, int fallback) =>
      _hasColumnFlex ? block.columnFlex[i] : fallback;

  @override
  Widget build(BuildContext context) {
    final borderColor = theme.nodeBorder.withValues(alpha: 0.6);
    final headerBg = theme.header;
    final boxed = block.layout == TableLayout.boxed;

    final children = <Widget>[];

    if (block.title != null) {
      children.add(
        Text(
          block.title!,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: theme.header,
          ),
        ),
      );
    }

    if (block.columns.isNotEmpty) {
      children.add(_headerRow(headerBg, borderColor));
    }

    for (var i = 0; i < block.rows.length; i++) {
      final row = block.rows[i];
      final isFirstInGroup = _hasGroups &&
          row.group != null &&
          (i == 0 || block.rows[i - 1].group != row.group);
      children.add(
        boxed
            ? _boxedRow(row: row, borderColor: borderColor)
            : _dataRow(
                row: row,
                borderColor: borderColor,
                isFirstInGroup: isFirstInGroup,
                isLast: i == block.rows.length - 1,
              ),
      );
    }

    // Boxed layout has no outer border — cells carry their own frames.
    if (boxed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _boxedRow({
    required TopicTableRow row,
    required Color borderColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var ci = 0; ci < row.cells.length; ci++) ...[
            if (ci > 0) const SizedBox(width: 6),
            Expanded(
              flex: row.cells[ci].span,
              child: _isEmptyCell(row.cells[ci])
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _severityBg(row.severity),
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _cellView(row.cells[ci]),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  /// In boxed layout, a cell with empty text renders as blank space
  /// (no border, no tile) — lets a row act as a partial overlay under
  /// a previous row, where only some columns carry content.
  bool _isEmptyCell(TableCell cell) =>
      cell is TextCell && cell.text.trim().isEmpty;

  Widget _headerRow(Color headerBg, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: headerBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(3),
          topRight: Radius.circular(3),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: _rowVPad,
        horizontal: _cellHPad,
      ),
      child: Row(
        children: [
          if (_hasGroups)
            const SizedBox(width: 64, child: SizedBox.shrink()),
          if (_hasRowHeaders)
            const SizedBox(width: 78, child: SizedBox.shrink()),
          for (var ci = 0; ci < block.columns.length; ci++)
            Expanded(
              flex: _colFlex(ci, 1),
              child: Text(
                block.columns[ci],
                style: const TextStyle(
                  fontSize: _headerFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dataRow({
    required TopicTableRow row,
    required Color borderColor,
    required bool isFirstInGroup,
    required bool isLast,
  }) {
    final sevBg = _severityBg(row.severity);
    final dividerColor = borderColor.withValues(alpha: 0.5);

    final cellsRow = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        if (_hasGroups)
          SizedBox(
            width: 64,
            child: isFirstInGroup
                ? Text(
                    row.group ?? '',
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w800,
                      color: theme.header,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        if (_hasRowHeaders)
          SizedBox(
            width: 78,
            child: Text(
              row.header ?? '',
              style: const TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        for (var ci = 0; ci < row.cells.length; ci++)
          Expanded(
            flex: _colFlex(ci, row.cells[ci].span),
            child: Container(
              padding: EdgeInsets.only(
                left: ci == 0 ? 0 : 6,
                right: ci == row.cells.length - 1 ? 0 : 6,
              ),
              decoration: ci == row.cells.length - 1
                  ? null
                  : BoxDecoration(
                      border: Border(
                        right: BorderSide(color: dividerColor, width: 1),
                      ),
                    ),
              child: _cellView(row.cells[ci]),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: sevBg,
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: _rowVPad,
        horizontal: _cellHPad,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (row.title != null) ...[
            Text(
              row.title!,
              style: TextStyle(
                fontSize: _fontSize + 1,
                fontWeight: FontWeight.w800,
                color: theme.header,
              ),
            ),
            const SizedBox(height: 2),
          ],
          cellsRow,
        ],
      ),
    );
  }

  Widget _cellView(TableCell cell) {
    return switch (cell) {
      // Single-line text cells go through MiniMarkdown so inline `**bold**`
      // renders (otherwise `**H**ypoglycaemia` shows literal asterisks).
      TextCell(:final text) => MiniMarkdown(
          markdown: text,
          fontSize: _fontSize,
        ),
      BulletCell(:final items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              MiniMarkdown(markdown: '- $item', fontSize: _fontSize),
          ],
        ),
      MarkdownCell(:final markdown) => MiniMarkdown(
          markdown: markdown,
          fontSize: _fontSize,
        ),
    };
  }

  Color? _severityBg(RowSeverity s) => switch (s) {
        RowSeverity.none => null,
        RowSeverity.emergency => const Color(0xFFFFEBEE),
        RowSeverity.priority => const Color(0xFFFFF8E1),
        RowSeverity.nonUrgent => const Color(0xFFE8F5E9),
      };
}
