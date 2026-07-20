import 'package:flutter/material.dart';
import 'package:orbweaver/data/formula_registry.dart' show FormulaSeverity;
import 'package:orbweaver/data/score_engine.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';

/// Renders an interactive [ScoreBlock]: tap criteria → live summed score → risk
/// band. Toggles are checkbox rows; choice items are chip groups. Scoring is in
/// `lib/data/score_engine.dart`.
class ScoreBlockView extends StatefulWidget {
  const ScoreBlockView({
    required this.block,
    required this.theme,
    super.key,
  });

  final ScoreBlock block;
  final TopicTheme theme;

  @override
  State<ScoreBlockView> createState() => _ScoreBlockViewState();
}

class _ScoreBlockViewState extends State<ScoreBlockView> {
  final _toggles = <String, bool>{};
  final _choices = <String, String>{};

  ScoreBlock get _b => widget.block;

  @override
  void initState() {
    super.initState();
    for (final item in _b.items) {
      if (item.type == ScoreItemType.toggle) {
        _toggles[item.key] = false;
      } else {
        _choices[item.key] = item.defaultValue ??
            (item.options.isNotEmpty ? item.options.first.value : '');
      }
    }
  }

  Map<String, dynamic> _selections() => {..._toggles, ..._choices};

  @override
  Widget build(BuildContext context) {
    final accent = widget.theme.header;
    final result = computeScore(_b, _selections());
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.04),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_b.title != null)
            Text(
              _b.title!,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          const SizedBox(height: 8),
          for (final item in _b.items) _buildItem(accent, item),
          const SizedBox(height: 12),
          _buildResult(accent, result),
          if (_b.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final n in _b.notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  n,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
          ],
          if (_b.caveats.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildCaveats(),
          ],
          if (_b.source != null) ...[
            const SizedBox(height: 8),
            Text(
              'Source: ${_b.source}',
              style: const TextStyle(fontSize: 10.5, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  // ── items ────────────────────────────────────────────────────

  Widget _buildItem(Color accent, ScoreItem item) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: switch (item.type) {
          ScoreItemType.toggle => _toggleRow(accent, item),
          ScoreItemType.choice => _choiceRow(accent, item),
          ScoreItemType.scale => _scaleRow(accent, item),
        },
      );

  Widget _toggleRow(Color accent, ScoreItem item) {
    final on = _toggles[item.key] ?? false;
    return InkWell(
      onTap: () => setState(() => _toggles[item.key] = !on),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 26,
              child: Checkbox(
                value: on,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: accent,
                onChanged: (v) =>
                    setState(() => _toggles[item.key] = v ?? false),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(child: _labelBlock(item)),
            const SizedBox(width: 6),
            _pointsBadge(accent, item.points, active: on),
          ],
        ),
      ),
    );
  }

  Widget _choiceRow(Color accent, ScoreItem item) {
    final selected = _choices[item.key];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelBlock(item),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final o in item.options)
              _choiceChip(accent, item.key, o, o.value == selected),
          ],
        ),
      ],
    );
  }

  Widget _scaleRow(Color accent, ScoreItem item) {
    final sel = _choices[item.key];
    final selOpt = _optionFor(item, sel);
    final anchor = (selOpt != null && selOpt.label != '${selOpt.points}')
        ? selOpt.label
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelBlock(item),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final o in item.options)
              _scaleButton(accent, item.key, o, o.value == sel),
          ],
        ),
        if (anchor != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              anchor,
              style: TextStyle(
                fontSize: 11.5,
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _scaleButton(Color accent, String key, ScoreOption o, bool sel) =>
      InkWell(
        onTap: () => setState(() => _choices[key] = o.value),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? accent : Colors.white,
            border: Border.all(color: accent.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${o.points}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: sel ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );

  ScoreOption? _optionFor(ScoreItem item, String? value) {
    for (final o in item.options) {
      if (o.value == value) return o;
    }
    return null;
  }

  Widget _choiceChip(Color accent, String key, ScoreOption o, bool sel) =>
      InkWell(
        onTap: () => setState(() => _choices[key] = o.value),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: sel ? accent : Colors.white,
            border: Border.all(color: accent.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${o.label}  ${_signed(o.points)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: sel ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );

  Widget _labelBlock(ScoreItem item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (item.help != null)
            Text(
              item.help!,
              style: const TextStyle(fontSize: 10.5, color: Colors.black54),
            ),
        ],
      );

  Widget _pointsBadge(Color accent, num points, {required bool active}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          _signed(points),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: active ? accent : Colors.black38,
          ),
        ),
      );

  // ── result ───────────────────────────────────────────────────

  Widget _buildResult(Color accent, ScoreResult result) {
    final band = result.band;
    final sevColor = _sevColor(accent, band?.severity ?? FormulaSeverity.none);
    final tinted = band != null &&
        (band.severity == FormulaSeverity.alert ||
            band.severity == FormulaSeverity.warn);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: tinted
            ? sevColor.withValues(alpha: 0.10)
            : accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border:
            tinted ? Border.all(color: sevColor.withValues(alpha: 0.5)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Score',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${result.total}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: sevColor,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  _b.unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sevColor.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          if (band != null) ...[
            const SizedBox(height: 2),
            Text(
              band.label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: tinted ? sevColor : accent,
              ),
            ),
            if (band.detail != null)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  band.detail!,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: tinted ? sevColor : Colors.black54,
                    fontWeight: tinted ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCaveats() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: widget.theme.alertFill,
          border: Border.all(color: widget.theme.alert, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in _b.caveats)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '⚠ $c',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.theme.alertText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );

  Color _sevColor(Color accent, FormulaSeverity sev) => switch (sev) {
        FormulaSeverity.alert => widget.theme.alert,
        FormulaSeverity.warn => const Color(0xFFB26A00),
        FormulaSeverity.info => accent,
        FormulaSeverity.none => accent,
      };

  /// "+2" / "−2" / "0" — with a real minus glyph for negatives.
  String _signed(num p) {
    if (p < 0) return '−${-p}';
    return '+$p';
  }
}
