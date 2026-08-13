import 'package:flutter/material.dart';
import 'package:orbweaver/data/search_normalizer.dart';
import 'package:orbweaver/models/formulary.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/mini_markdown.dart';

/// A faceted **formulary** index: the same drugs viewed A–Z, by class, or by
/// indication via a segmented toggle, with a search box. Tapping a drug opens
/// its detail page (A–Z / class) or expands its indication slice in place
/// (indication lens) — the interaction follows the facet's atomic unit.
class DrugIndexScreen extends StatefulWidget {
  const DrugIndexScreen({
    required this.formulary,
    required this.palette,
    super.key,
  });

  final Formulary formulary;
  final Map<String, Color> palette;

  @override
  State<DrugIndexScreen> createState() => _DrugIndexScreenState();
}

class _DrugIndexScreenState extends State<DrugIndexScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _searchOpen = false;
  late String _facetKey = widget.formulary.facets.first.key;

  /// The drug id currently expanded inline in the indication lens (keyed by
  /// "indication|id" so the same drug can be expanded per indication group).
  String? _expanded;

  Color get _accent => widget.palette['accent'] ?? const Color(0xFF5981BF);
  Color get _fill => widget.palette['accent_fill'] ?? const Color(0xFFEEF2F9);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  FormularyFacet get _facet =>
      widget.formulary.facets.firstWhere((f) => f.key == _facetKey);

  List<Drug> get _sortedDrugs {
    final ds = [...widget.formulary.drugs]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return ds;
  }

  bool _matches(Drug d, String q) {
    if (q.isEmpty) return true;
    final blob = SearchNormalizer.normalize(d.searchBlob);
    for (final term in SearchNormalizer.normalize(q).split(' ')) {
      if (term.isNotEmpty && !blob.contains(term)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: _searchOpen
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search drugs…',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : Text(widget.formulary.title),
        actions: [
          IconButton(
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              if (_searchOpen) {
                _searchCtrl.clear();
                _query = '';
              }
              _searchOpen = !_searchOpen;
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_searchOpen || _query.isEmpty) _segmentedControl(),
          Expanded(
            child: _query.isNotEmpty ? _searchResults() : _facetBody(),
          ),
        ],
      ),
    );
  }

  Widget _segmentedControl() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE3E7EE),
          borderRadius: BorderRadius.circular(9),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (final f in widget.formulary.facets)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _facetKey = f.key;
                    _expanded = null;
                  }),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: _facetKey == f.key ? _accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      f.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _facetKey == f.key
                            ? Colors.white
                            : const Color(0xFF55606F),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _searchResults() {
    final hits = _sortedDrugs.where((d) => _matches(d, _query)).toList();
    if (hits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No drugs match "$_query".',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: hits.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, thickness: 0.5, indent: 12, endIndent: 12),
      itemBuilder: (_, i) => _drugRow(hits[i], subtitle: hits[i].subtitle),
    );
  }

  Widget _facetBody() {
    final f = _facet;
    if (f.mode == 'alpha') {
      final ds = _sortedDrugs;
      final intro = widget.formulary.intro;
      final hasIntro = intro != null;
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: ds.length + (hasIntro ? 1 : 0),
        separatorBuilder: (_, _) =>
            const Divider(height: 1, thickness: 0.5, indent: 12, endIndent: 12),
        itemBuilder: (_, i) {
          if (hasIntro && i == 0) return _introCard(intro);
          final d = ds[hasIntro ? i - 1 : i];
          return _drugRow(d, subtitle: d.subtitle);
        },
      );
    }
    // group mode: class or indication.
    final byIndication = f.field == 'indications';
    final order = byIndication
        ? widget.formulary.indicationOrder
        : widget.formulary.classOrder;
    final label = byIndication
        ? widget.formulary.indicationLabel
        : widget.formulary.classLabel;

    final tiles = <Widget>[];
    for (final key in order) {
      final members = _sortedDrugs.where((d) {
        return byIndication ? d.indications.contains(key) : d.className == key;
      }).toList();
      if (members.isEmpty) continue;
      tiles.add(_groupHeader(label(key)));
      for (final d in members) {
        if (byIndication) {
          tiles.add(_indicationRow(d, key));
        } else {
          tiles.add(_drugRow(d, subtitle: d.subtitle));
        }
      }
    }
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      children: tiles,
    );
  }

  Widget _groupHeader(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: _accent,
      ),
    ),
  );

  /// Front-matter card shown once at the top of the A–Z list.
  Widget _introCard(String markdown) => Container(
    margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: _accent.withValues(alpha: 0.35)),
    ),
    child: MiniMarkdown(
      markdown: markdown,
      fontSize: 12.5,
      bulletColor: _accent,
    ),
  );

  /// A–Z / class row: taps through to the drug detail page.
  Widget _drugRow(Drug d, {required String subtitle}) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DrugDetailScreen(drug: d, palette: widget.palette),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        child: Row(
          children: [
            _accentBar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  /// Indication-lens row: shows the dose for THIS indication and expands the
  /// slice in place; a link inside jumps to the full drug page.
  Widget _indicationRow(Drug d, String indicationKey) {
    final rowKey = '$indicationKey|${d.id}';
    final open = _expanded == rowKey;
    final dose = d.doseForIndication(indicationKey);
    final hint = dose?.regimen ?? d.regimen ?? d.daily ?? '';
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = open ? null : rowKey),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
            child: Row(
              children: [
                _accentBar(open: open),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hint.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          hint,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _darken(_accent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  open ? Icons.expand_less : Icons.chevron_right,
                  size: 20,
                  color: Colors.black38,
                ),
              ],
            ),
          ),
        ),
        if (open) _indicationExpansion(d, dose),
      ],
    );
  }

  Widget _indicationExpansion(Drug d, DoseRow? dose) {
    return Container(
      width: double.infinity,
      color: _fill,
      padding: const EdgeInsets.fromLTRB(25, 4, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dose != null && dose.bands.isNotEmpty) ...[
            Text(
              d.bandLabel.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 5),
            _bandStrip(d.bandColumns, dose.bands),
            const SizedBox(height: 6),
          ],
          if (dose?.form != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                dose!.form!,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    DrugDetailScreen(drug: d, palette: widget.palette),
              ),
            ),
            child: Text(
              'See full ${d.name} →',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _darken(_accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A compact one-row band table (columns + a single value row).
  Widget _bandStrip(List<String> cols, List<String> vals) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: const Color(0xFFDDE1E8), width: 0.5),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0x11000000)),
            children: [
              for (final c in cols) _cell(c, header: true),
            ],
          ),
          TableRow(
            children: [
              for (var i = 0; i < cols.length; i++)
                _cell(i < vals.length ? vals[i] : '—'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool header = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: header ? FontWeight.w700 : FontWeight.w400,
        color: header ? Colors.black54 : Colors.black87,
      ),
    ),
  );

  Widget _accentBar({bool open = false}) => Container(
    width: 3,
    height: 32,
    decoration: BoxDecoration(
      color: open ? _darken(_accent) : _accent,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  static Color _darken(Color c) => HSLColor.fromColor(c)
      .withLightness((HSLColor.fromColor(c).lightness - 0.12).clamp(0.0, 1.0))
      .toColor();
}

/// A single drug's detail page: the weight-band dose table(s) + preparation
/// and cautions, styled like a topic page (steel-blue app bar with the source
/// page badge). Built from the structured [Drug] record — no topic file.
class DrugDetailScreen extends StatelessWidget {
  const DrugDetailScreen({
    required this.drug,
    required this.palette,
    super.key,
  });

  final Drug drug;
  final Map<String, Color> palette;

  Color get _accent => palette['accent'] ?? const Color(0xFF5981BF);
  Color get _fill => palette['accent_fill'] ?? const Color(0xFFEEF2F9);

  @override
  Widget build(BuildContext context) {
    final theme = TopicTheme(palette);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        titleSpacing: 8,
        title: Row(
          children: [
            if (drug.page != null) ...[
              _PageBadge(pageNumber: drug.page!, headerColor: _accent),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                drug.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            if (drug.subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 8),
                child: Text(
                  drug.subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ),
            if (drug.dose != null)
              _card(
                theme,
                title: 'Dose & route',
                child: MiniMarkdown(
                  markdown: drug.dose!,
                  fontSize: 13,
                  bulletColor: _accent,
                ),
              ),
            if (drug.regimen != null)
              _card(
                theme,
                title: 'Regimen',
                child: Text(
                  drug.regimen!,
                  style: const TextStyle(fontSize: 13),
                ),
                highlight: true,
              ),
            if (drug.daily != null)
              _card(
                theme,
                title: 'Daily dose',
                child: Text(
                  drug.daily!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                highlight: true,
              ),
            if (drug.doses.isNotEmpty) _doseTable(),
            if (drug.notes != null)
              _card(
                theme,
                title: 'Notes',
                child: MiniMarkdown(
                  markdown: drug.notes!,
                  fontSize: 13,
                  bulletColor: _accent,
                ),
              ),
            if (drug.review)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 2),
                child: Text(
                  'Indication from EMLc fallback — pending OpenEvidence review.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _doseTable() {
    const firstW = 190.0;
    const bandW = 78.0;
    Widget hcell(String t, double w, {bool first = false}) => Container(
      width: w,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      alignment: first ? Alignment.centerLeft : Alignment.centerLeft,
      child: Text(
        t,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: _darken(_accent),
        ),
      ),
    );
    Widget vcell(String t, double w) => Container(
      width: w,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        t,
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
    Widget firstCell(DoseRow d) => Container(
      width: firstW,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d.label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          if (d.regimen != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                d.regimen!,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          if (d.form != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                d.form!,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
        ],
      ),
    );

    final cols = drug.bandColumns;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              drug.bandLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _darken(_accent),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    hcell('Dose', firstW, first: true),
                    for (final c in cols) hcell(c, bandW),
                  ],
                ),
                const Divider(height: 1, thickness: 0.5),
                for (final d in drug.doses) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      firstCell(d),
                      for (var i = 0; i < cols.length; i++)
                        vcell(i < d.bands.length ? d.bands[i] : '—', bandW),
                    ],
                  ),
                  const Divider(height: 1, thickness: 0.5),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    TopicTheme theme, {
    required String title,
    required Widget child,
    bool highlight = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: highlight ? _fill : const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border(left: BorderSide(color: _accent, width: 4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _darken(_accent),
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  static Color _darken(Color c) => HSLColor.fromColor(c)
      .withLightness((HSLColor.fromColor(c).lightness - 0.12).clamp(0.0, 1.0))
      .toColor();
}

class _PageBadge extends StatelessWidget {
  const _PageBadge({required this.pageNumber, required this.headerColor});

  final int pageNumber;
  final Color headerColor;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      '$pageNumber',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: headerColor,
      ),
    ),
  );
}
