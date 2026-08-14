import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:orbweaver/data/library_scope.dart';

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

/// True when [raw] carries at least one inline cross-reference.
bool hasFlowLink(String raw) => flowLinkPattern.hasMatch(raw);

/// [raw] as the reader sees it, with the markup removed.
///
/// Every measurement — `FitText`'s widest-word shrink, line-count estimates,
/// layout budgets — must use this, never the raw string, or the invisible
/// `](topic:wvems-2026-016)` counts as a very long word and shrinks the node
/// to nothing.
String flowLinkPlain(String raw) =>
    raw.replaceAllMapped(flowLinkPattern, (m) => m.group(1)!);

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
    if (!hasFlowLink(widget.text)) {
      return Text(
        widget.text,
        textAlign: widget.textAlign,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }
    return Text.rich(
      TextSpan(children: buildFlowLinkSpans(context, widget.text, _recognizers)),
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
  List<TapGestureRecognizer> sink,
) {
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in flowLinkPattern.allMatches(raw)) {
    if (m.start > last) {
      spans.add(TextSpan(text: raw.substring(last, m.start)));
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
    spans.add(TextSpan(text: raw.substring(last)));
  }
  return spans;
}
