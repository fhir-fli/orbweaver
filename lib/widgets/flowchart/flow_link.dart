import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:orbweaver/data/library_scope.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/widgets/scope_chip.dart';
import 'package:orbweaver/widgets/unit_text.dart';

/// Inline cross-references inside flowchart text.
///
/// Flowchart strings are not markdown — they render as plain `Text`, so the
/// `[label](topic:id)` written in a prose block would show its brackets on
/// screen. This is the one piece of inline syntax they do understand, and it
/// exists because the print puts *several* cross-references inside a single
/// line: on p.34 the convergence bullet "Fever, Pain, Nausea" carries three
/// links, one per word, to pp.16, 20 and 22.
///
/// A per-node `link_id` cannot express that — it links the whole node, and on
/// that bullet the app pointed all three words at Pain. `link_id` stays for
/// what it is good at (a whole node that is one cross-reference); this covers
/// the rest.
///
///     "Fever, Pain, Nausea"
///  -> "[Fever](topic:wvems-2026-016), [Pain](topic:wvems-2026-020), ..."
final RegExp flowLinkPattern = RegExp(r'\[([^\]]+)\]\(topic:([^)]+)\)');

/// Provider-scope badge, the same token `MiniMarkdown` takes: `{E}`, `{A}`,
/// `{I}`, `{P}`, `{P(CC)}`, and `{}` for the print's blank EMR badge.
///
/// Flowchart text needs it because the print puts badges inside convergence
/// stadium bullets (pp.24, 52) and inside entry-chain nodes (pp.84, 94), where
/// there is no action tile to carry a `provider_level:`. Those were authored
/// as "(A) NS Bolus".
final RegExp flowBadgePattern = RegExp(r'\{(E|A|I|P\(CC\)|P|CC)?\}');

final RegExp _flowInline = RegExp(
  '${flowLinkPattern.pattern}|${flowBadgePattern.pattern}',
);

/// True when [raw] carries at least one cross-reference or badge.
bool hasFlowLink(String raw) => _flowInline.hasMatch(raw);

/// [raw] as the reader sees it, with the markup removed.
///
/// Every measurement — `FitText`'s widest-word shrink, line-count estimates,
/// layout budgets — must use this, never the raw string, or the invisible
/// `](topic:wvems-2026-016)` counts as a very long word and shrinks the node
/// to nothing. A badge stands in as its letter plus a space, which is about
/// the width the chip actually takes.
String flowLinkPlain(String raw) => raw
    .replaceAllMapped(flowLinkPattern, (m) => m.group(1)!)
    .replaceAllMapped(flowBadgePattern, (m) => '${m.group(1) ?? ''} ');

/// Renders flowchart text with its inline cross-references tappable and
/// underlined, and plain `Text` when there are none.
///
/// Stateful so the per-link [TapGestureRecognizer]s can be disposed — the
/// same reason `MiniMarkdown` is.
class FlowLinkText extends StatefulWidget {
  const FlowLinkText(
    this.text, {
    this.style,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<FlowLinkText> createState() => _FlowLinkTextState();
}

class _FlowLinkTextState extends State<FlowLinkText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    // Always rich: even a node with no link or badge can carry a unit that
    // needs stepping down ("NS Bolus 500 mL").
    return Text.rich(
      TextSpan(
        children: buildFlowLinkSpans(
          context,
          widget.text,
          _recognizers,
          fontSize: widget.style?.fontSize ?? 14,
        ),
      ),
      textAlign: widget.textAlign,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}

/// The spans for [raw], appending each link's recognizer to [sink] so the
/// caller can dispose them. Exposed for the places that already build their
/// own `TextSpan` tree (the convergence bullet's leading glyph, for one).
List<InlineSpan> buildFlowLinkSpans(
  BuildContext context,
  String raw,
  List<TapGestureRecognizer> sink, {
  double fontSize = 14,
}) {
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in _flowInline.allMatches(raw)) {
    if (m.start > last) {
      spans.addAll(
        unitAwareSpans(raw.substring(last, m.start), null, fontSize),
      );
    }
    if (m.group(2) == null) {
      // A badge: groups 1-2 belong to the link alternative, group 3 to this.
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 3),
            child: ScopeChip(level: ProviderLevel.fromString(m.group(3))),
          ),
        ),
      );
      last = m.end;
      continue;
    }
    final target = m.group(2)!.split('#');
    final recognizer = TapGestureRecognizer()
      ..onTap = () => openLinkedTopic(
        context,
        target.first,
        anchor: target.length > 1 && target[1].isNotEmpty ? target[1] : null,
      );
    sink.add(recognizer);
    spans.add(
      TextSpan(
        text: m.group(1),
        style: const TextStyle(decoration: TextDecoration.underline),
        recognizer: recognizer,
      ),
    );
    last = m.end;
  }
  if (last < raw.length) {
    spans.addAll(unitAwareSpans(raw.substring(last), null, fontSize));
  }
  return spans;
}
