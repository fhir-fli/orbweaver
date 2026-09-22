import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/fit_text.dart';

/// Renders an `algorithm`-variant flowchart as a real clinical decision
/// tree: **decision diamonds down the left**, each with connectors drawn
/// from its corners — the `continue` branch runs straight DOWN to the next
/// diamond, the terminal branch runs straight RIGHT into a wide disposition
/// box. No elbows: because the diamonds share a left column, the down-arrows
/// are straight and the whole thing reads like the printed ACLS/clinical
/// algorithms it digitises.
class AlgorithmFlowchartView extends StatelessWidget {
  const AlgorithmFlowchartView({
    required this.flowchart,
    required this.theme,
    super.key,
  });

  final AlgorithmFlowchart flowchart;
  final TopicTheme theme;

  static const int _cols = 12;
  static const double _dLeftCol = 0.3; // diamond left edge
  static const double _dCols = 4.2; // diamond width
  /// The largest axis-aligned rectangle inside a rhombus is exactly half
  /// its width by half its height. Decision text is laid out in that
  /// rectangle so it never crosses the sloped edges.
  static const double _kDiamondTextWFrac = 0.5;
  static const double _kDiamondTextHFrac = 0.5;
  static const double _boxLeftCol =
      2.7; // wide box, next to the down-arrow (→ col 12)

  static double diamondCenter(double colW) => colW * (_dLeftCol + _dCols / 2);

  @override
  Widget build(BuildContext context) {
    final fc = flowchart;
    return LayoutBuilder(
      builder: (context, c) {
        final colW = c.maxWidth / _cols;
        final rows = <Widget>[];

        if (fc.entry != null) {
          rows.add(_Entry(text: fc.entry!.text, theme: theme, colW: colW));
        }
        for (final s in fc.stages) {
          rows.add(
            _DecisionStage(stage: s, flowchart: fc, theme: theme, colW: colW),
          );
        }
        if (fc.terminal != null) {
          rows.add(
            Padding(
              padding: EdgeInsets.only(left: colW * _boxLeftCol),
              child: _AlgoBox(box: fc.terminal, theme: theme, terminal: true),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        );
      },
    );
  }
}

/// Entry stadium centred over the first diamond, with a down-arrow into it.
class _Entry extends StatelessWidget {
  const _Entry({required this.text, required this.theme, required this.colW});
  final String text;
  final TopicTheme theme;
  final double colW;
  @override
  Widget build(BuildContext context) {
    final cx = AlgorithmFlowchartView.diamondCenter(colW);
    // A short label reads best as a stadium/pill; a long one wraps to many
    // lines, and a near-circular (999) radius would then curve in over the
    // text corners — so long entries use a contained rounded rectangle with
    // roomier padding.
    final longEntry = text.length > 32;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: cx * 2,
          child: Center(
            child: Container(
              padding: longEntry
                  ? const EdgeInsets.symmetric(horizontal: 20, vertical: 11)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: theme.flowEntry,
                border: Border.all(color: theme.nodeBorder, width: 1.5),
                borderRadius: BorderRadius.circular(longEntry ? 18 : 999),
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: cx - 7),
          child: const SizedBox(
            width: 14,
            height: 18,
            child: CustomPaint(
              painter: _ArrowLine([Offset(7, 0), Offset(7, 18)]),
            ),
          ),
        ),
      ],
    );
  }
}

/// One decision: a left diamond with corner-drawn connectors — straight
/// down (continue) and straight right (terminal box).
class _DecisionStage extends StatelessWidget {
  const _DecisionStage({
    required this.stage,
    required this.flowchart,
    required this.theme,
    required this.colW,
  });

  final AlgoStage stage;
  final AlgorithmFlowchart flowchart;
  final TopicTheme theme;
  final double colW;

  @override
  Widget build(BuildContext context) {
    final leftX = colW * AlgorithmFlowchartView._dLeftCol;
    final dW = colW * AlgorithmFlowchartView._dCols;
    final dcx = leftX + dW / 2;
    final rightCornerX = leftX + dW;

    // Grow the diamond with the decision length so long questions have room
    // (and the criteria card below never overlaps the wrapped text).
    //
    // The text must fit the diamond's INSCRIBED RECTANGLE, not its bounding
    // box. A rhombus is at full width only on its centre line and tapers to a
    // point at top and bottom, so the largest axis-aligned rectangle inside
    // one is exactly half its width by half its height. Sizing against the
    // bounding box is why a long question used to cross the sloped edges —
    // its first and last lines sat where the diamond is narrowest.
    const dFont = 11.5;
    final textW = dW * AlgorithmFlowchartView._kDiamondTextWFrac;
    // ~0.55 em average advance for this weight; floor keeps a narrow column
    // from claiming one character per line.
    final charsPerLine = (textW / (dFont * 0.55)).floor().clamp(6, 40);
    // Let a long question grow the diamond rather than clip: clamping the
    // line count low is what left "Age >1 month - child convulsing for more
    // than 5 minutes OR presents convulsing?" crossing the sloped edges even
    // after the inscribed-rectangle fix. Long decisions are rare; a tall
    // diamond reads, a clipped one does not.
    final dLines = (stage.decision.length / charsPerLine).ceil().clamp(2, 18);
    // 1.12 under-estimated the wrapped height: TextPainter adds ascent and
    // descent beyond the 1.05 line-height in the style, which left six
    // diamonds 6-11 px short (flowchart_fit_guard_test). 1.28 clears them.
    final textH = dLines * dFont * 1.28;
    // Double it: the text box occupies the middle half of the diamond.
    final dH = (textH / AlgorithmFlowchartView._kDiamondTextHFrac + 16).clamp(
      72.0,
      520.0,
    );
    final midY = dH / 2;

    final terminals = [
      for (final o in stage.outcomes)
        if (!o.cont) o,
    ];
    AlgoOutcome? cont;
    for (final o in stage.outcomes) {
      if (o.cont) {
        cont = o;
        break;
      }
    }

    // A single title-only disposition sits to the RIGHT at the diamond's
    // level (straight-right arrow). A box with dosing bullets, or a
    // multi-way branch, drops BELOW the diamond (wide, hugging the
    // down-arrow) reached by an out-right-then-down elbow.
    // A single terminal disposition goes straight RIGHT at the diamond's
    // level (higher on the page, room for its label). Only a VERY long box
    // (a full dosing protocol) drops BELOW — wide and short — and multi-way
    // branches drop below too.
    // Criteria that qualify the decision ("Any of the following?") render as
    // a card on the spine just below the diamond; the continue line and any
    // below-boxes resume beneath it.
    final hasCrit = stage.criteria.isNotEmpty;
    // Estimate the criteria-card height, allowing for text wrapping in the
    // ~6-column-wide card (~28 chars/line at the card font).
    final critLines = stage.criteria.fold<int>(
      0,
      (a, c) => a + (c.length / 28).ceil(),
    );
    final critH = hasCrit ? (16 + critLines * 14).toDouble() : 0.0;
    final belowStart = dH + (hasCrit ? critH + 12 : 0.0);

    final singleBox = terminals.length == 1
        ? flowchart.boxFor(terminals.first)
        : null;
    final wideBelow =
        (singleBox?.bullets.length ?? 0) >= 5 || singleBox?.table != null;
    // A criteria-bearing decision sends its terminal BELOW the criteria card
    // (stacked), so the box never collides with the wide criteria card.
    final atLevel = terminals.length == 1 && !wideBelow && !hasCrit;
    // A short at-level box (a plain disposition) stays compact; one carrying
    // several bullets goes WIDER (and closer to the diamond) so a content-heavy
    // box renders short instead of as a narrow, sprawling column.
    final atWide = atLevel && (singleBox?.bullets.length ?? 0) >= 3;
    final leftForBox = atLevel
        ? rightCornerX + colW * (atWide ? 0.8 : 1.6)
        : colW * AlgorithmFlowchartView._boxLeftCol;
    // At-level: the label sits ~at the diamond level, the box just below it
    // so the right arrow lands near the box's top.
    final boxTop = atLevel ? (midY - 18).clamp(0.0, midY) : (belowStart + 14);
    final boxW = atLevel
        ? colW * (atWide ? 6.6 : 5.2)
        : colW * (12 - AlgorithmFlowchartView._boxLeftCol);
    // Estimated vertical centres of each stacked box (multi-way fan), so
    // the painter can draw a connector from the diamond to each.
    final branchCenters = <double>[];
    if (terminals.length > 1) {
      var y = boxTop;
      for (final t in terminals) {
        final n = flowchart.boxFor(t)?.bullets.length ?? 0;
        final h = 18 + 30 + n * 22.0; // label + title + bullets
        branchCenters.add(y + (h - 18) / 2 + 18);
        y += h + 10;
      }
    }

    final sizing = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: belowStart + 16 + (cont != null ? 20 : 6),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: leftForBox, top: boxTop),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < terminals.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i < terminals.length - 1 ? 10 : 0,
                ),
                child: SizedBox(
                  width: boxW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Outcome label above each box (wraps if long, so it
                      // never overlaps the box or truncates).
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 1),
                        child: _label(terminals[i].label),
                      ),
                      _AlgoBox(
                        box: flowchart.boxFor(terminals[i]),
                        theme: theme,
                        terminal: true,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Force the stage to the full grid width. Otherwise a decision with no
    // right-side terminal box (only a continue-down) would collapse to the
    // left-padding width, clipping the diamond, its criteria card, and the
    // painter's connectors.
    final fullW = colW * AlgorithmFlowchartView._cols;
    return SizedBox(
      width: fullW,
      child: Stack(
        children: [
          sizing,
          Positioned.fill(
            child: CustomPaint(
              painter: _StagePainter(
                leftX: leftX,
                dW: dW,
                dH: dH,
                dcx: dcx,
                rightCornerX: rightCornerX,
                boxTop: boxTop,
                boxLeftX: leftForBox,
                atLevel: atLevel,
                contStartY: belowStart,
                fill: theme.flowDecision,
                hasContinue: cont != null,
                terminalCount: terminals.length,
                branchCenters: branchCenters,
              ),
            ),
          ),
          // Diamond label.
          Positioned(
            left: leftX,
            top: 0,
            width: dW,
            height: dH,
            child: Center(
              // The inscribed rectangle of a rhombus is half its width by
              // half its height — anything wider crosses the sloped edges.
              child: SizedBox(
                width: textW,
                child: FitText(
                  stage.decision,
                  maxWidth: textW,
                  maxHeight: dH * AlgorithmFlowchartView._kDiamondTextHFrac,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          // Criteria card on the spine, just below the diamond.
          if (hasCrit)
            Positioned(
              left: leftX,
              top: dH + 4,
              width: colW * 6.2,
              child: _CriteriaCard(criteria: stage.criteria, theme: theme),
            ),
          // Continue label — to the LEFT of the down-arrow, where there's room.
          // The gutter is narrow, so use a slightly smaller size and let long
          // labels wrap on word boundaries rather than mid-word.
          if (cont != null)
            Positioned(
              left: 0,
              top: belowStart + 4,
              width: dcx - 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  cont.label,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String s) => Text(
    s,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    ),
  );
}

class _StagePainter extends CustomPainter {
  const _StagePainter({
    required this.leftX,
    required this.dW,
    required this.dH,
    required this.dcx,
    required this.rightCornerX,
    required this.boxTop,
    required this.boxLeftX,
    required this.atLevel,
    required this.contStartY,
    required this.fill,
    required this.hasContinue,
    required this.terminalCount,
    required this.branchCenters,
  });

  final double leftX;
  final double dW;
  final double dH;
  final double dcx;
  final double rightCornerX;
  final double boxTop;
  final double boxLeftX;
  final double contStartY;
  final bool atLevel;
  final Color fill;
  final bool hasContinue;
  final int terminalCount;
  final List<double> branchCenters;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final solid = Paint()..color = Colors.black87;
    final midY = dH / 2;

    void head(Offset tip, Offset dir) {
      final u = dir / dir.distance;
      final perp = Offset(-u.dy, u.dx) * 4;
      final b = tip - u * 8;
      final p = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(b.dx + perp.dx, b.dy + perp.dy)
        ..lineTo(b.dx - perp.dx, b.dy - perp.dy)
        ..close();
      canvas.drawPath(p, solid);
    }

    // Diamond.
    final d = Path()
      ..moveTo(dcx, 0)
      ..lineTo(rightCornerX, midY)
      ..lineTo(dcx, dH)
      ..lineTo(leftX, midY)
      ..close();
    canvas
      ..drawPath(d, Paint()..color = fill)
      ..drawPath(
        d,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );

    // Terminal branch(es).
    if (terminalCount == 1) {
      if (atLevel) {
        // Short disposition: straight right into a box at the diamond level.
        canvas.drawLine(
          Offset(rightCornerX, midY),
          Offset(boxLeftX, midY),
          stroke,
        );
        head(Offset(boxLeftX, midY), const Offset(1, 0));
      } else {
        // Dosing box below: out to the right slightly, then turn down in.
        final turnX = rightCornerX + 14;
        final path = Path()
          ..moveTo(rightCornerX, midY)
          ..lineTo(turnX, midY)
          ..lineTo(turnX, boxTop);
        canvas.drawPath(path, stroke);
        head(Offset(turnX, boxTop), const Offset(0, 1));
      }
    } else if (terminalCount > 1 && branchCenters.isNotEmpty) {
      // Multi-way fan: a spine from the diamond bottom down, with a tick
      // into each stacked box.
      canvas.drawLine(Offset(dcx, dH), Offset(dcx, branchCenters.last), stroke);
      for (final cy in branchCenters) {
        canvas.drawLine(Offset(dcx, cy), Offset(boxLeftX, cy), stroke);
        head(Offset(boxLeftX, cy), const Offset(1, 0));
      }
    }
    // Continue: from below the criteria, straight down to the next diamond.
    if (hasContinue) {
      canvas.drawLine(
        Offset(dcx, contStartY),
        Offset(dcx, size.height),
        stroke,
      );
      head(Offset(dcx, size.height), const Offset(0, 1));
    }
  }

  @override
  bool shouldRepaint(_StagePainter old) =>
      old.dH != dH ||
      old.dcx != dcx ||
      old.hasContinue != hasContinue ||
      old.terminalCount != terminalCount ||
      old.boxTop != boxTop ||
      old.atLevel != atLevel ||
      old.boxLeftX != boxLeftX ||
      old.contStartY != contStartY ||
      old.fill != fill;
}

class _ArrowLine extends CustomPainter {
  const _ArrowLine(this.points);
  final List<Offset> points;
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, stroke);
    final tip = points.last;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - 4, tip.dy - 7)
        ..lineTo(tip.dx + 4, tip.dy - 7)
        ..close(),
      Paint()..color = Colors.black87,
    );
  }

  @override
  bool shouldRepaint(_ArrowLine old) => false;
}

class _AlgoBox extends StatelessWidget {
  const _AlgoBox({
    required this.box,
    required this.theme,
    this.terminal = false,
  });
  final AlgoBox? box;
  final TopicTheme theme;
  final bool terminal;
  @override
  Widget build(BuildContext context) {
    final b = box;
    if (b == null) return const SizedBox.shrink();
    final fill = _sevFill(theme, b.severity);
    final border = _sevBorder(theme, b.severity) ?? theme.nodeBorder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: fill ?? Colors.white,
        border: Border.all(color: border, width: terminal ? 1.5 : 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (b.title.isNotEmpty)
            Text(
              b.title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          for (final bullet in b.bullets)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '•  $bullet',
                style: const TextStyle(fontSize: 11, height: 1.2),
              ),
            ),
          if (b.table != null)
            Padding(
              padding: EdgeInsets.only(top: b.title.isNotEmpty ? 4 : 0),
              child: _MiniTable(table: b.table!, theme: theme),
            ),
        ],
      ),
    );
  }
}

/// A compact bordered table rendered inside an [_AlgoBox] — a reference table
/// that lives as a node in the flowchart (e.g. Iron Studies).
class _MiniTable extends StatelessWidget {
  const _MiniTable({required this.table, required this.theme});
  final AlgoTable table;
  final TopicTheme theme;

  TextAlign _alignOf(int c) {
    final a = (table.align != null && c < table.align!.length)
        ? table.align![c]
        : (c == 0 ? 'left' : 'center');
    return switch (a) {
      'right' => TextAlign.right,
      'center' => TextAlign.center,
      _ => TextAlign.left,
    };
  }

  Widget _cell(String s, {required bool header, required int c}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    child: Text(
      s,
      textAlign: _alignOf(c),
      style: TextStyle(
        fontSize: 10.5,
        height: 1.1,
        fontWeight: header ? FontWeight.w800 : FontWeight.w400,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final line = theme.nodeBorder.withValues(alpha: 0.55);
    return Table(
      border: TableBorder.all(color: line, width: 0.8),
      columnWidths: const {0: FlexColumnWidth()},
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: theme.nodeBorder.withValues(alpha: 0.12),
          ),
          children: [
            for (var c = 0; c < table.columns.length; c++)
              _cell(table.columns[c], header: true, c: c),
          ],
        ),
        for (final row in table.rows)
          TableRow(
            children: [
              for (var c = 0; c < row.length; c++)
                _cell(row[c], header: false, c: c),
            ],
          ),
      ],
    );
  }
}

/// The criteria that qualify a decision (the "any of the following"),
/// shown as a small card on the spine beneath the diamond.
class _CriteriaCard extends StatelessWidget {
  const _CriteriaCard({required this.criteria, required this.theme});
  final List<String> criteria;
  final TopicTheme theme;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: theme.nodeBorder.withValues(alpha: 0.6)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in criteria)
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(
              '•  $c',
              style: const TextStyle(fontSize: 10.5, height: 1.15),
            ),
          ),
      ],
    ),
  );
}

Color? _sevFill(TopicTheme t, RowSeverity s) => switch (s) {
  RowSeverity.emergency => t.severitySevereTile,
  RowSeverity.priority => t.severityModerateTile,
  RowSeverity.nonUrgent => t.severityMildTile,
  RowSeverity.none => null,
};

Color? _sevBorder(TopicTheme t, RowSeverity s) => switch (s) {
  RowSeverity.emergency => t.severitySevereHeader,
  RowSeverity.priority => t.severityModerateHeader,
  RowSeverity.nonUrgent => t.severityMildHeader,
  RowSeverity.none => null,
};
