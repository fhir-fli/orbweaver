import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:json_schema/json_schema.dart';
import 'package:orbweaver/data/schema_explain.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/widgets/topic_view.dart';
import 'package:url_launcher/url_launcher.dart';

/// Topic playground: YAML on the left, the rendered page on the right, for
/// the documentation site (`fhir_fli_documentation/jaspr/web/orbweaver_demo`).
///
/// It runs the real renderer ([TopicView]) and the real schema
/// (`schema/topic.schema.json`) in the browser, so what an author sees here is
/// what the app draws. A pasted topic is standalone: its own `palette:` applies
/// over the defaults, same-topic `#anchor` links scroll, and cross-topic
/// `topic:` links render inert because there is no library to resolve them.
///
/// Build: `tool/publish_playground.sh` (or
/// `flutter build web -t lib/main_playground.dart`).
void main() => runApp(const PlaygroundApp());

const String kSchemaUrl =
    'https://fhir-fli.github.io/fhir_fli_documentation/orbweaver/schema/topic.schema.json';
const String kAuthoringUrl =
    'https://fhir-fli.github.io/fhir_fli_documentation/docs/orbweaver/orbweaver_authoring';

/// Bundled topics that between them use every block type and every flowchart
/// variant, so an author can start from a real page.
const List<({String label, String asset})> kExamples = [
  (
    label: 'Prose (Syncope)',
    asset: 'assets/books/protocolbook/topics/pb_126_im_syncope.yaml',
  ),
  (
    label: 'Table (Paediatric triage)',
    asset: 'assets/books/protocolbook/topics/pb_012_triage.yaml',
  ),
  (
    label: 'Row / column grid + arrows (Malaria)',
    asset: 'assets/books/protocolbook/topics/pb_022_malaria.yaml',
  ),
  (
    label: 'Flowchart: severity (PALS)',
    asset: 'assets/books/protocolbook/topics/pb_013_pals.yaml',
  ),
  (
    label: 'Flowchart: linear (Alcohol intoxication)',
    asset: 'assets/books/protocolbook/topics/pb_034_alcohol_intoxication.yaml',
  ),
  (
    label: 'Flowchart: algorithm (Hydrocarbon)',
    asset: 'assets/books/protocolbook/topics/pb_030_hydrocarbon.yaml',
  ),
  (
    label: 'Flowchart: cycle (Cardiac arrest)',
    asset: 'assets/books/protocolbook/topics/pb_014_cardiac_arrest.yaml',
  ),
  (
    label: 'Flowchart: cascade (Meningitis)',
    asset: 'assets/books/protocolbook/topics/pb_054_meningitis.yaml',
  ),
  (
    label: 'Flowchart: differential + band callout (Abdominal pain)',
    asset: 'assets/books/wvems/topics/wvems_2026_034.yaml',
  ),
  (
    label: 'Drug cards',
    asset: 'assets/books/wvems/topics/wvems_drug_ref_a.yaml',
  ),
  (
    label: 'Procedure cards',
    asset: 'assets/books/wvems/topics/wvems_2026_096.yaml',
  ),
  (
    label: 'Image (IO line)',
    asset: 'assets/books/protocolbook/topics/pb_021_io_line.yaml',
  ),
  (
    label: 'Formula (MAP)',
    asset: 'assets/books/calculators/topics/calc_map.yaml',
  ),
  (
    label: 'Score (4Ts)',
    asset: 'assets/books/calculators/topics/calc_4ts.yaml',
  ),
  (
    label: 'Conversion (Opioids)',
    asset: 'assets/books/calculators/topics/conv_opioids.yaml',
  ),
];

class PlaygroundApp extends StatelessWidget {
  const PlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Orbweaver Playground',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF455A64)),
      useMaterial3: true,
    ),
    home: const PlaygroundPage(),
  );
}

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  final _controller = TextEditingController();
  JsonSchema? _schema;
  Topic? _topic;
  String? _parseError;
  List<String> _problems = const [];
  String _exampleAsset = kExamples.first.asset;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });
    _boot();
  }

  Future<void> _boot() async {
    final text = await rootBundle.loadString('schema/topic.schema.json');
    _schema = schemaFromJson(text);
    await _loadExample(_exampleAsset);
  }

  Future<void> _loadExample(String asset) async {
    final yaml = await rootBundle.loadString(asset);
    _controller.text = yaml;
    _exampleAsset = asset;
    _render();
  }

  /// Validates against the schema and parses with the app's own model. The
  /// page renders whenever the parser accepts it, even with schema problems,
  /// because that is exactly what the app would do: draw the page and ignore
  /// the keys it does not know.
  void _render() {
    final text = _controller.text;
    var problems = const <String>[];
    Topic? topic;
    String? parseError;
    try {
      final doc = parseYamlPlain(text);
      final schema = _schema;
      if (schema != null) problems = explain(schema, doc);
    } on Object catch (e) {
      parseError = 'YAML does not parse: $e';
    }
    if (parseError == null) {
      try {
        topic = Topic.fromYamlString(text);
      } on Object catch (e) {
        parseError = 'The app cannot read this topic: $e';
      }
    }
    setState(() {
      _topic = topic;
      _parseError = parseError;
      _problems = problems;
      _dirty = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orbweaver topic playground'),
        actions: [
          TextButton(
            onPressed: () => launchUrl(Uri.parse(kSchemaUrl)),
            child: const Text('Schema (JSON)'),
          ),
          TextButton(
            onPressed: () => launchUrl(Uri.parse(kAuthoringUrl)),
            child: const Text('Authoring reference'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 900;
          final editor = _EditorPane(
            controller: _controller,
            exampleAsset: _exampleAsset,
            dirty: _dirty,
            onExample: _loadExample,
            onRender: _render,
          );
          final output = _OutputPane(
            topic: _topic,
            parseError: _parseError,
            problems: _problems,
          );
          if (wide) {
            return Row(
              children: [
                Expanded(child: editor),
                const VerticalDivider(width: 1),
                Expanded(child: output),
              ],
            );
          }
          return Column(
            children: [
              SizedBox(height: 320, child: editor),
              const Divider(height: 1),
              Expanded(child: output),
            ],
          );
        },
      ),
    );
  }
}

class _EditorPane extends StatelessWidget {
  const _EditorPane({
    required this.controller,
    required this.exampleAsset,
    required this.dirty,
    required this.onExample,
    required this.onRender,
  });

  final TextEditingController controller;
  final String exampleAsset;
  final bool dirty;
  final ValueChanged<String> onExample;
  final VoidCallback onRender;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: exampleAsset,
                  items: [
                    for (final e in kExamples)
                      DropdownMenuItem(value: e.asset, child: Text(e.label)),
                  ],
                  onChanged: (v) {
                    if (v != null) onExample(v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                key: const Key('render'),
                onPressed: onRender,
                icon: const Icon(Icons.play_arrow),
                label: Text(dirty ? 'Render (changed)' : 'Render'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              key: const Key('yaml'),
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    'topic:\n  id: "my-topic"\n  title: "…"\n  blocks:\n    - type: "prose"\n      markdown: "…"',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OutputPane extends StatelessWidget {
  const _OutputPane({
    required this.topic,
    required this.parseError,
    required this.problems,
  });

  final Topic? topic;
  final String? parseError;
  final List<String> problems;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (parseError != null)
          _Banner(
            key: const Key('parse-error'),
            color: scheme.errorContainer,
            text: parseError!,
          )
        else if (problems.isNotEmpty)
          _Banner(
            key: const Key('schema-problems'),
            color: const Color(0xFFFFF3E0),
            text:
                '${problems.length} schema problem${problems.length == 1 ? '' : 's'} '
                '— the page renders, but the app ignores what it does not know:\n'
                '${problems.map((p) => '• $p').join('\n')}',
          )
        else if (topic != null)
          const _Banner(
            key: Key('valid'),
            color: Color(0xFFE8F5E9),
            text: 'Valid: matches schema/topic.schema.json',
          ),
        Expanded(
          child: topic == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: TopicView(key: ValueKey(topic), topic: topic!),
                ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.text, super.key});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(maxHeight: 220),
    color: color,
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    child: SingleChildScrollView(
      child: SelectableText(
        text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    ),
  );
}
