import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';

/// Renders an interactive [ConversionBlock]. See docs/conversion_block.md.
///
/// `equivalence` mode: a three-section converter — source drug/route/dose →
/// an always-visible reference (e.g. MME) line → target drug/route = result.
/// Direct conversion only (no 24-hour aggregation).
///
/// `tiers` mode: an agents × tiers matrix of tappable real strengths; tap a
/// strength to highlight its tier (the equivalent doses across agents).
class ConversionBlockView extends StatefulWidget {
  const ConversionBlockView({
    required this.block,
    required this.theme,
    super.key,
  });

  final ConversionBlock block;
  final TopicTheme theme;

  @override
  State<ConversionBlockView> createState() => _ConversionBlockViewState();
}

class _ConversionBlockViewState extends State<ConversionBlockView> {
  // equivalence state
  final _doseCtrl = TextEditingController();
  String? _srcName;
  String? _srcRoute;
  String? _tgtName;
  String? _tgtRoute;

  // tiers state
  String? _selectedTier;

  ConversionBlock get _b => widget.block;

  @override
  void initState() {
    super.initState();
    final names = _b.agentNames;
    if (names.isNotEmpty) {
      _srcName = names.first;
      _srcRoute = _firstRoute(names.first);
      _tgtName = names.length > 1 ? names[1] : names.first;
      _tgtRoute = _firstRoute(_tgtName!);
    }
    _doseCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _doseCtrl.dispose();
    super.dispose();
  }

  /// Non-null routes available for [name], or empty if the class has no
  /// route concept.
  List<String> _routes(String name) => [
    for (final r in _b.routesFor(name))
      if (r != null) r,
  ];

  String? _firstRoute(String name) {
    final r = _routes(name);
    return r.isEmpty ? null : r.first;
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.theme.header;
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
          if (_b.mode == ConversionMode.equivalence)
            _buildEquivalence(accent)
          else
            _buildTiers(accent),
          if (_b.excluded.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildExcluded(),
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

  // ── equivalence ──────────────────────────────────────────────

  Widget _buildEquivalence(Color accent) {
    final src = _srcName == null ? null : _b.agentFor(_srcName!, _srcRoute);
    final tgt = _tgtName == null ? null : _b.agentFor(_tgtName!, _tgtRoute);
    final dose = double.tryParse(_doseCtrl.text.trim());
    final refEq = (src != null && dose != null)
        ? _b.toReference(src, dose)
        : null;
    final tgtDose = (tgt != null && refEq != null)
        ? _b.fromReference(tgt, refEq)
        : null;
    final refLabel = _b.referenceLabel ?? _b.reference ?? 'reference';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FROM
        _label('FROM'),
        Row(
          children: [
            Expanded(flex: 3, child: _drugDropdown(isSource: true)),
            if (_routes(_srcName ?? '').isNotEmpty) ...[
              const SizedBox(width: 6),
              Expanded(flex: 2, child: _routeDropdown(isSource: true)),
            ],
            const SizedBox(width: 6),
            Expanded(flex: 2, child: _doseField(src)),
          ],
        ),
        const SizedBox(height: 10),
        // reference anchor line (always shown)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            refEq == null ? '= — $refLabel' : '= ${_fmt(refEq)} $refLabel',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // TO
        _label('TO'),
        Row(
          children: [
            Expanded(flex: 3, child: _drugDropdown(isSource: false)),
            if (_routes(_tgtName ?? '').isNotEmpty) ...[
              const SizedBox(width: 6),
              Expanded(flex: 2, child: _routeDropdown(isSource: false)),
            ],
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: Text(
                tgtDose == null
                    ? '= —'
                    : '= ${_fmt(tgtDose)} ${tgt?.unit ?? _b.unit ?? ''}'.trim(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _drugDropdown({required bool isSource}) {
    final value = isSource ? _srcName : _tgtName;
    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      isDense: true,
      items: [
        for (final n in _b.agentNames)
          DropdownMenuItem(
            value: n,
            child: Text(n, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (n) {
        if (n == null) return;
        setState(() {
          if (isSource) {
            _srcName = n;
            _srcRoute = _firstRoute(n);
          } else {
            _tgtName = n;
            _tgtRoute = _firstRoute(n);
          }
        });
      },
    );
  }

  Widget _routeDropdown({required bool isSource}) {
    final name = (isSource ? _srcName : _tgtName) ?? '';
    final routes = _routes(name);
    final value = isSource ? _srcRoute : _tgtRoute;
    return DropdownButton<String>(
      value: routes.contains(value)
          ? value
          : (routes.isEmpty ? null : routes.first),
      isExpanded: true,
      isDense: true,
      items: [
        for (final r in routes) DropdownMenuItem(value: r, child: Text(r)),
      ],
      onChanged: (r) => setState(() {
        if (isSource) {
          _srcRoute = r;
        } else {
          _tgtRoute = r;
        }
      }),
    );
  }

  Widget _doseField(ConversionAgent? src) {
    final unit = src?.unit ?? _b.unit ?? '';
    return TextField(
      controller: _doseCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        isDense: true,
        hintText: 'dose',
        suffixText: unit.isEmpty ? null : unit,
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        border: const OutlineInputBorder(),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  // ── tiers ────────────────────────────────────────────────────

  Widget _buildTiers(Color accent) {
    final tiers = _b.tiers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_b.tierNote != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _b.tierNote!,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(color: Colors.black12),
          columnWidths: {
            0: const FlexColumnWidth(2.2),
            for (var i = 0; i < tiers.length; i++)
              i + 1: const FlexColumnWidth(2),
          },
          children: [
            // header
            TableRow(
              children: [
                _tierHeaderCell('', accent, highlight: false),
                for (final t in tiers)
                  _tierHeaderCell(t, accent, highlight: t == _selectedTier),
              ],
            ),
            for (final name in _b.agentNames)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final t in tiers) _tierCell(name, t, accent),
                ],
              ),
          ],
        ),
        if (_selectedTier != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Highlighted: $_selectedTier-intensity equivalents.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _tierHeaderCell(String text, Color accent, {required bool highlight}) {
    return Container(
      color: highlight
          ? accent.withValues(alpha: 0.18)
          : accent.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }

  Widget _tierCell(String name, String tier, Color accent) {
    final doses = [
      for (final a in _b.agents)
        if (a.name == name)
          for (final d in a.doses)
            if (d.tier == tier) d.dose,
    ];
    final highlight = tier == _selectedTier;
    return Container(
      color: highlight ? accent.withValues(alpha: 0.12) : null,
      padding: const EdgeInsets.all(4),
      child: doses.isEmpty
          ? const SizedBox(height: 24)
          : Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                for (final d in doses)
                  InkWell(
                    onTap: () => setState(() => _selectedTier = tier),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: highlight ? accent : Colors.white,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.6),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: highlight ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  // ── shared ───────────────────────────────────────────────────

  Widget _buildExcluded() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Not convertible here:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        for (final e in _b.excluded)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '• ${e.name} — ${e.reason}',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
      ],
    );
  }

  Widget _buildCaveats() {
    return Container(
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
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.black54,
        letterSpacing: 0.6,
      ),
    ),
  );

  /// Formats a computed dose: integer when whole, else up to 2 decimals
  /// (trailing zeros trimmed) — no false precision.
  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
