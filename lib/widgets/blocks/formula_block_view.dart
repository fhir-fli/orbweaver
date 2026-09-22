import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbweaver/data/formula_registry.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/blocks/calculator_frame.dart';

/// Renders an interactive [FormulaBlock]: a small form of numeric/select
/// inputs whose computed outputs update live. The math lives in
/// `lib/data/formula_registry.dart` (keyed by [FormulaBlock.kind]); this widget
/// only collects inputs and displays the [FormulaResult].
class FormulaBlockView extends StatefulWidget {
  const FormulaBlockView({
    required this.block,
    required this.theme,
    super.key,
  });

  final FormulaBlock block;
  final TopicTheme theme;

  @override
  State<FormulaBlockView> createState() => _FormulaBlockViewState();
}

class _FormulaBlockViewState extends State<FormulaBlockView> {
  final _controllers = <String, TextEditingController>{};
  final _selects = <String, String>{};
  final _bools = <String, bool>{};

  FormulaBlock get _b => widget.block;

  @override
  void initState() {
    super.initState();
    for (final input in _b.inputs) {
      switch (input.type) {
        case FormulaInputType.number:
          _controllers[input.key] = TextEditingController(
            text: input.defaultValue ?? '',
          )..addListener(() => setState(() {}));
        case FormulaInputType.boolean:
          _bools[input.key] = input.defaultValue == 'true';
        case FormulaInputType.select:
          _selects[input.key] =
              input.defaultValue ??
              (input.options.isNotEmpty ? input.options.first.value : '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Collects current input values (numbers parsed to double, selects as
  /// strings) for the registry.
  Map<String, dynamic> _values() {
    final v = <String, dynamic>{};
    for (final input in _b.inputs) {
      switch (input.type) {
        case FormulaInputType.number:
          final parsed = double.tryParse(_controllers[input.key]!.text.trim());
          if (parsed != null) v[input.key] = parsed;
        case FormulaInputType.boolean:
          v[input.key] = _bools[input.key] ?? false;
        case FormulaInputType.select:
          final s = _selects[input.key];
          if (s != null && s.isNotEmpty) v[input.key] = s;
      }
    }
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.theme.header;
    final result = computeFormula(_b.kind, _values());
    return CalculatorFrame(
      accent: accent,
      theme: widget.theme,
      title: _b.title,
      notes: _b.notes,
      caveats: _b.caveats,
      source: _b.source,
      body: [
        ..._buildInputs(),
        const SizedBox(height: 12),
        _buildResult(accent, result),
      ],
    );
  }

  // ── inputs ───────────────────────────────────────────────────

  List<Widget> _buildInputs() {
    return [
      for (final input in _b.inputs)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: input.type == FormulaInputType.boolean
              ? _booleanRow(input)
              : Row(
                  children: [
                    Expanded(flex: 5, child: _inputLabel(input)),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: input.type == FormulaInputType.number
                          ? _numberField(input)
                          : _selectField(input),
                    ),
                  ],
                ),
        ),
    ];
  }

  Widget _inputLabel(FormulaInput input) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        input.label + (input.optional ? ' (optional)' : ''),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      if (input.help != null)
        Text(
          input.help!,
          style: const TextStyle(fontSize: 10.5, color: Colors.black54),
        ),
    ],
  );

  Widget _booleanRow(FormulaInput input) {
    final on = _bools[input.key] ?? false;
    return InkWell(
      onTap: () => setState(() => _bools[input.key] = !on),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Checkbox(
              value: on,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: widget.theme.header,
              onChanged: (b) => setState(() => _bools[input.key] = b ?? false),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(child: _inputLabel(input)),
        ],
      ),
    );
  }

  Widget _numberField(FormulaInput input) => TextField(
    controller: _controllers[input.key],
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.]'))],
    decoration: InputDecoration(
      isDense: true,
      hintText: input.label.toLowerCase(),
      suffixText: input.unit,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      border: const OutlineInputBorder(),
    ),
    style: const TextStyle(fontSize: 14),
  );

  Widget _selectField(FormulaInput input) {
    final current = _selects[input.key];
    final values = [for (final o in input.options) o.value];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black38),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: values.contains(current) ? current : null,
        isDense: true,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: [
          for (final o in input.options)
            DropdownMenuItem(
              value: o.value,
              child: Text(o.display, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (val) {
          if (val == null) return;
          setState(() => _selects[input.key] = val);
        },
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  // ── result ───────────────────────────────────────────────────

  Widget _buildResult(Color accent, FormulaResult result) {
    if (result.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Enter values to calculate',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
      );
    }
    return Column(
      children: [
        for (final o in result.outputs) _outputRow(accent, o),
      ],
    );
  }

  Widget _outputRow(Color accent, FormulaOutput o) {
    final sevColor = switch (o.severity) {
      FormulaSeverity.alert => widget.theme.alert,
      FormulaSeverity.warn => widget.theme.formulaWarn,
      FormulaSeverity.info => accent,
      FormulaSeverity.none => accent,
    };
    final tinted =
        o.severity == FormulaSeverity.alert ||
        o.severity == FormulaSeverity.warn;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: tinted
            ? sevColor.withValues(alpha: 0.10)
            : accent.withValues(alpha: o.primary ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(6),
        border: tinted
            ? Border.all(color: sevColor.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  o.label,
                  style: TextStyle(
                    fontSize: o.primary ? 13.5 : 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                o.value,
                style: TextStyle(
                  fontSize: o.primary ? 20 : 15,
                  fontWeight: FontWeight.w800,
                  color: sevColor,
                ),
              ),
              if (o.unit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    o.unit!,
                    style: TextStyle(
                      fontSize: o.primary ? 12 : 11,
                      fontWeight: FontWeight.w600,
                      color: sevColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (o.interpretation != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                o.interpretation!,
                style: TextStyle(
                  fontSize: 11.5,
                  color: tinted ? sevColor : Colors.black54,
                  fontWeight: tinted ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
