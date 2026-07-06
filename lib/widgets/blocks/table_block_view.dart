import 'dart:math' as math;

import 'package:flutter/material.dart' hide TableCell, TableRow;
import 'package:flutter/material.dart' as mat;
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
///   - display aids (all opt-in, off by default): zebra striping, per-column
///     alignment / colour tint / in-cell magnitude bars, and — in scroll
///     layout — a sticky header and frozen first column inside a bounded,
///     internally-scrolling panel (for the big growth-reference tables).
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
    // A wide matrix (more columns than fit the screen) renders as a
    // horizontally-scrolling fixed-width grid instead of a flex table.
    if (block.layout == TableLayout.scroll) {
      return _ScrollTableView(block: block, theme: theme);
    }

    final style = _TableStyle(block, theme);
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
      children.add(_headerRow(headerBg, borderColor, style));
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
                index: i,
                borderColor: borderColor,
                isFirstInGroup: isFirstInGroup,
                isLast: i == block.rows.length - 1,
                style: style,
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

  Widget _headerRow(Color headerBg, Color borderColor, _TableStyle style) {
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
              child: Container(
                color: style.tintFor(ci),
                child: Align(
                  alignment: style.alignment(ci),
                  child: Text(
                    block.columns[ci],
                    textAlign: style.textAlign(ci),
                    style: const TextStyle(
                      fontSize: _headerFontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dataRow({
    required TopicTableRow row,
    required int index,
    required Color borderColor,
    required bool isFirstInGroup,
    required bool isLast,
    required _TableStyle style,
  }) {
    final sevBg = _severityBg(row.severity);
    final rowBg = sevBg ?? style.zebraBg(index);
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
              color: style.tintFor(ci),
              padding: EdgeInsets.only(
                left: ci == 0 ? 0 : 6,
                right: ci == row.cells.length - 1 ? 0 : 6,
              ),
              foregroundDecoration: ci == row.cells.length - 1
                  ? null
                  : BoxDecoration(
                      border: Border(
                        right: BorderSide(color: dividerColor, width: 1),
                      ),
                    ),
              child: style.styledCell(ci, row.cells[ci], _cellView),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
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
        RowSeverity.emergency => theme.severitySevereTile,
        RowSeverity.priority => theme.severityModerateTile,
        RowSeverity.nonUrgent => theme.severityMildTile,
      };
}

/// Shared cell-styling helpers used by both the standard and scroll table
/// renderers: per-column alignment, colour tint, in-cell magnitude bars, and
/// zebra row shading. All are opt-in — when the corresponding `TableBlock`
/// lists are empty / flags are false, these return neutral values and the
/// table renders exactly as before.
class _TableStyle {
  _TableStyle(this.block, this.theme) {
    for (var c = 0; c < block.columns.length; c++) {
      if (c < block.columnBar.length && block.columnBar[c]) {
        double? mn;
        double? mx;
        for (final row in block.rows) {
          if (c >= row.cells.length) continue;
          final v = _num(row.cells[c]);
          if (v == null) continue;
          mn = mn == null ? v : math.min(mn, v);
          mx = mx == null ? v : math.max(mx, v);
        }
        if (mn != null && mx != null && mx > mn) _barRange[c] = (mn, mx);
      }
    }
  }

  final TableBlock block;
  final TopicTheme theme;
  final Map<int, (double, double)> _barRange = {};

  CellAlign _alignFor(int c) =>
      c < block.columnAlign.length ? block.columnAlign[c] : CellAlign.left;

  Alignment alignment(int c) => switch (_alignFor(c)) {
        CellAlign.right => Alignment.centerRight,
        CellAlign.center => Alignment.center,
        CellAlign.left => Alignment.centerLeft,
      };

  TextAlign textAlign(int c) => switch (_alignFor(c)) {
        CellAlign.right => TextAlign.right,
        CellAlign.center => TextAlign.center,
        CellAlign.left => TextAlign.left,
      };

  Color? tintFor(int c) {
    if (c >= block.columnTintArgb.length) return null;
    final argb = block.columnTintArgb[c];
    return argb == null ? null : Color(argb);
  }

  /// Soft alternating shading for odd rows when `zebra` is on. Blends toward
  /// the theme header colour at very low alpha so it reads as a faint tint.
  Color? zebraBg(int rowIndex) {
    if (!block.zebra || rowIndex.isEven) return null;
    return theme.header.withValues(alpha: 0.06);
  }

  double? _barFraction(int c, TableCell cell) {
    final range = _barRange[c];
    if (range == null) return null;
    final v = _num(cell);
    if (v == null) return null;
    return ((v - range.$1) / (range.$2 - range.$1)).clamp(0.0, 1.0);
  }

  /// Wraps the built cell content with alignment and, when enabled for the
  /// column, an in-cell magnitude bar behind the value.
  Widget styledCell(int c, TableCell cell, Widget Function(TableCell) build) {
    final content = Align(alignment: alignment(c), child: build(cell));
    final frac = _barFraction(c, cell);
    if (frac == null) return content;
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: frac,
              heightFactor: 0.7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.header.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }

  static double? _num(TableCell cell) {
    if (cell is! TextCell) return null;
    final m = RegExp(r'-?\d+(\.\d+)?').firstMatch(cell.text);
    return m == null ? null : double.tryParse(m.group(0)!);
  }
}

/// Horizontally-scrolling fixed-width table for [TableLayout.scroll].
///
/// Two modes:
///   - **Simple** (default): a single `Table` inside a horizontal scroll,
///     with the new per-column styling (align / tint / bar / zebra). Used by
///     the existing wide matrices (e.g. the §3.14 neonatal drug-dose grid).
///   - **Frozen pane** (when `sticky_header` or `sticky_first_column` is set):
///     a bounded panel whose header row stays pinned while the body scrolls
///     vertically, and whose first (label) column stays pinned while the body
///     scrolls horizontally — for the ~130-row growth-reference tables.
class _ScrollTableView extends StatefulWidget {
  const _ScrollTableView({required this.block, required this.theme});

  final TableBlock block;
  final TopicTheme theme;

  @override
  State<_ScrollTableView> createState() => _ScrollTableViewState();
}

class _ScrollTableViewState extends State<_ScrollTableView> {
  // Simple-mode horizontal scroll.
  final _simpleH = ScrollController();
  // Frozen-pane controllers: body scrolls; the pinned header mirrors its
  // horizontal offset; a dedicated vertical controller drives the scrollbar.
  final _bodyH = ScrollController();
  final _headerH = ScrollController();
  final _bodyV = ScrollController();
  bool _syncing = false;

  static const double _defaultColWidth = 78;
  static const double _fontSize = 12;
  static const double _rowH = 21;
  // Tall enough for a header label that wraps to two lines (e.g.
  // "Length (cm)") without overflowing into the first data row.
  static const double _headerH2 = 40;

  bool get _frozen =>
      widget.block.stickyHeader || widget.block.stickyFirstColumn;

  @override
  void initState() {
    super.initState();
    _bodyH.addListener(_syncHeaderToBody);
  }

  void _syncHeaderToBody() {
    if (_syncing || !_headerH.hasClients) return;
    _syncing = true;
    _headerH.jumpTo(_bodyH.offset);
    _syncing = false;
  }

  @override
  void dispose() {
    _simpleH.dispose();
    _bodyH.dispose();
    _headerH.dispose();
    _bodyV.dispose();
    super.dispose();
  }

  double _width(int i) {
    final w = widget.block.columnWidths;
    return i < w.length ? w[i] : _defaultColWidth;
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final theme = widget.theme;
    final style = _TableStyle(block, theme);

    final grid = _frozen ? _frozenPane(context, style) : _simpleGrid(style);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.title != null) ...[
          Text(
            block.title!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: theme.header,
            ),
          ),
          const SizedBox(height: 4),
        ],
        grid,
      ],
    );
  }

  // ── Simple mode ────────────────────────────────────────────────
  Widget _simpleGrid(_TableStyle style) {
    final block = widget.block;
    final theme = widget.theme;
    final borderColor = theme.nodeBorder.withValues(alpha: 0.6);
    final dividerColor = borderColor.withValues(alpha: 0.5);
    final ncol = block.columns.length;

    final table = mat.Table(
      border: mat.TableBorder(
        top: BorderSide(color: borderColor),
        bottom: BorderSide(color: borderColor),
        left: BorderSide(color: borderColor),
        right: BorderSide(color: borderColor),
        horizontalInside: BorderSide(color: borderColor),
        verticalInside: BorderSide(color: dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      columnWidths: {
        for (var i = 0; i < ncol; i++) i: FixedColumnWidth(_width(i)),
      },
      children: [
        mat.TableRow(
          decoration: BoxDecoration(color: theme.header),
          children: [
            for (var i = 0; i < ncol; i++)
              _padCell(
                Align(
                  alignment: style.alignment(i),
                  child: Text(
                    block.columns[i],
                    textAlign: style.textAlign(i),
                    style: const TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                tint: style.tintFor(i),
              ),
          ],
        ),
        for (var r = 0; r < block.rows.length; r++)
          mat.TableRow(
            decoration: BoxDecoration(color: style.zebraBg(r)),
            children: [
              for (var i = 0; i < ncol; i++)
                _padCell(
                  i < block.rows[r].cells.length
                      ? style.styledCell(i, block.rows[r].cells[i], _cell)
                      : const SizedBox.shrink(),
                  tint: style.tintFor(i),
                ),
            ],
          ),
      ],
    );

    return Scrollbar(
      controller: _simpleH,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _simpleH,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 10),
        child: table,
      ),
    );
  }

  Widget _padCell(Widget child, {Color? tint}) => Container(
        color: tint,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: child,
      );

  // ── Frozen-pane mode ───────────────────────────────────────────
  Widget _frozenPane(BuildContext context, _TableStyle style) {
    final block = widget.block;
    final theme = widget.theme;
    final borderColor = theme.nodeBorder.withValues(alpha: 0.6);
    final ncol = block.columns.length;
    final freezeFirst = block.stickyFirstColumn;
    final bodyStart = freezeFirst ? 1 : 0;
    final bodyWidth = [
      for (var i = bodyStart; i < ncol; i++) _width(i),
    ].fold<double>(0, (a, b) => a + b);

    final maxH = block.maxHeight ??
        (MediaQuery.sizeOf(context).height * 0.58);

    final freezeBorder = BorderSide(color: borderColor);
    // Right edge of the frozen first column, to set it off from the body.
    Border? freezeEdge(int i) =>
        (freezeFirst && i == 0) ? Border(right: freezeBorder) : null;

    Widget headerCell(int i) => Container(
          width: _width(i),
          height: _headerH2,
          alignment: _alignmentFor(style, i),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(color: style.tintFor(i), border: freezeEdge(i)),
          child: Text(
            block.columns[i],
            textAlign: style.textAlign(i),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        );

    Widget bodyCell(int r, int i) {
      final row = block.rows[r];
      final sev = _severityBg(theme, row.severity);
      final bg = sev ?? style.zebraBg(r);
      // No Container.alignment here: styledCell's own Align (driven by the
      // column's alignment) positions the content inside the fixed box.
      return Container(
        width: _width(i),
        height: _rowH,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: style.tintFor(i) ?? bg,
          border: freezeEdge(i),
        ),
        child: i < row.cells.length
            ? style.styledCell(i, row.cells[i], _cell)
            : const SizedBox.shrink(),
      );
    }

    // Header band: frozen corner (first column header) + scrollable rest,
    // mirrored to the body's horizontal offset.
    final headerBand = ColoredBox(
      color: theme.header,
      child: Row(
        children: [
          if (freezeFirst) headerCell(0),
          Expanded(
            child: SingleChildScrollView(
              controller: _headerH,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  for (var i = bodyStart; i < ncol; i++) headerCell(i),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Body: one shared vertical scroll wrapping [frozen column | scroll body].
    final body = Scrollbar(
      controller: _bodyV,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _bodyV,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (freezeFirst)
              Column(
                children: [
                  for (var r = 0; r < block.rows.length; r++) bodyCell(r, 0),
                ],
              ),
            Expanded(
              child: Scrollbar(
                controller: _bodyH,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _bodyH,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: bodyWidth,
                    child: Column(
                      children: [
                        for (var r = 0; r < block.rows.length; r++)
                          Row(
                            children: [
                              for (var i = bodyStart; i < ncol; i++)
                                bodyCell(r, i),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      constraints: BoxConstraints(maxHeight: maxH),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          headerBand,
          Flexible(child: body),
        ],
      ),
    );
  }

  Alignment _alignmentFor(_TableStyle style, int i) => style.alignment(i);

  Widget _cell(TableCell cell) => switch (cell) {
        TextCell(:final text) =>
          MiniMarkdown(markdown: text, fontSize: _fontSize),
        BulletCell(:final items) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items)
                MiniMarkdown(markdown: '- $item', fontSize: _fontSize),
            ],
          ),
        MarkdownCell(:final markdown) =>
          MiniMarkdown(markdown: markdown, fontSize: _fontSize),
      };
}

Color? _severityBg(TopicTheme theme, RowSeverity s) => switch (s) {
      RowSeverity.none => null,
      RowSeverity.emergency => theme.severitySevereTile,
      RowSeverity.priority => theme.severityModerateTile,
      RowSeverity.nonUrgent => theme.severityMildTile,
    };
