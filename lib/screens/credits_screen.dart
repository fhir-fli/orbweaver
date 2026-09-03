import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:yaml/yaml.dart';

/// Sources and image attribution, shown to the user.
///
/// This screen exists for a licence reason, not a decorative one. The bundled
/// Wikimedia images are CC BY and CC BY-SA, and both require that attribution
/// reach the people who see the work. Until 2026-09-02 the attributions lived
/// in a markdown file inside the asset bundle that nothing ever displayed,
/// which is not attribution.
///
/// `assets/credits.yaml` is the single source. Do not keep a second copy.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  static const String asset = 'assets/credits.yaml';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        title: const Text('Sources & credits'),
        backgroundColor: const Color(0xFF1E4E8C),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Credits>(
        future: loadCredits(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load credits: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _CreditsBody(credits: snap.data!);
        },
      ),
    );
  }
}

/// Everything the credits screen shows.
class Credits {
  const Credits({
    required this.intro,
    required this.sources,
    required this.imageIntro,
    required this.images,
  });

  final String intro;
  final List<SourceWork> sources;
  final String imageIntro;
  final List<ImageCredit> images;
}

class SourceWork {
  const SourceWork({required this.title, required this.by, required this.note});

  final String title;
  final String by;
  final String note;
}

class ImageCredit {
  const ImageCredit({
    required this.file,
    required this.use,
    required this.source,
    required this.sourceUrl,
    required this.author,
    required this.licence,
    required this.licenceUrl,
  });

  final String file;
  final String use;
  final String source;
  final String sourceUrl;
  final String author;
  final String licence;
  final String licenceUrl;
}

String _s(dynamic v) => v == null ? '' : v.toString();

Future<Credits> loadCredits() async {
  final raw = await rootBundle.loadString(CreditsScreen.asset);
  final doc = loadYaml(raw) as YamlMap;
  final c = doc['credits'] as YamlMap;
  final imgs = c['images'] as YamlMap;
  return Credits(
    intro: _s(c['intro']),
    sources: [
      for (final s in (c['sources'] as YamlList? ?? YamlList()))
        SourceWork(
          title: _s((s as YamlMap)['title']),
          by: _s(s['by']),
          note: _s(s['note']),
        ),
    ],
    imageIntro: _s(imgs['intro']),
    images: [
      for (final i in (imgs['items'] as YamlList? ?? YamlList()))
        ImageCredit(
          file: _s((i as YamlMap)['file']),
          use: _s(i['use']),
          source: _s(i['source']),
          sourceUrl: _s(i['source_url']),
          author: _s(i['author']),
          licence: _s(i['licence']),
          licenceUrl: _s(i['licence_url']),
        ),
    ],
  );
}

class _CreditsBody extends StatelessWidget {
  const _CreditsBody({required this.credits});

  final Credits credits;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(credits.intro, style: const TextStyle(fontSize: 14, height: 1.4)),
        const SizedBox(height: 20),
        const _Heading('The books'),
        for (final s in credits.sources) _SourceCard(source: s),
        const SizedBox(height: 20),
        const _Heading('Images'),
        Text(credits.imageIntro,
            style: const TextStyle(fontSize: 13, height: 1.4)),
        const SizedBox(height: 12),
        for (final i in credits.images) _ImageRow(credit: i),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E4E8C),
          ),
        ),
      );
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});

  final SourceWork source;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(source.title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, height: 1.3)),
            if (source.by.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(source.by,
                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
            if (source.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(source.note,
                  style: const TextStyle(
                      fontSize: 12, height: 1.35, color: Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImageRow extends StatelessWidget {
  const _ImageRow({required this.credit});

  final ImageCredit credit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${credit.use} — ${credit.author}',
              style: const TextStyle(fontSize: 13, height: 1.3)),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Link(text: credit.source, url: credit.sourceUrl),
              const Text(' · ', style: TextStyle(fontSize: 12)),
              _Link(text: credit.licence, url: credit.licenceUrl),
            ],
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.text, required this.url});

  final String text;
  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Text(text,
          style: const TextStyle(fontSize: 12, color: Colors.black54));
    }
    return InkWell(
      onTap: () {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF1E4E8C),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
