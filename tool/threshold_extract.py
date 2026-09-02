#!/usr/bin/env python3
"""Thresholds, extracted by SUBJECT and bound to the DECISION they gate.

This replaces the threshold half of `crossbook_rules_extract.py`, which keyed a
cutoff on its UNIT and grouped on the unit alone. Measured on its own output of
2026-08-30, that produced three defects, all of which made the pass unreadable:

  1. THE UNIT IS NOT THE QUANTITY. 17 of its 244 rows carried a quantity the
     page does not support: 8 rows of `blood lactate >= 2 mmol/L` and CSF
     glucose were labelled "glucose mmol/L"; 8 rows of CRP, bilirubin,
     creatinine and a systolic pressure were labelled "glucose mg/dL"; and
     `ascitic fluid protein < 1.5 g/dL` was labelled haemoglobin. A row that
     names the wrong quantity is not a weak signal, it is a false statement
     about the book.

  2. ONE ROW POOLED DECISIONS THAT HAVE NOTHING TO DO WITH EACH OTHER. Its
     `glucose mmol/L` row pooled hypoglycaemia at 2.2, the severe-wasting
     cutoff of 3, DKA entry at 14 and DKA resolution at 11. Every threshold row
     it produced resolved to that pooling, which is why the pass reported no
     findings: not because the books agree, but because the instrument cannot
     see a disagreement. A cutoff belongs to a decision.

  3. IT COVERED SIX QUANTITIES AND THE BOOKS USE MORE. A census of every
     comparator+number+unit in both books found 1,360 occurrences. Respiratory
     rate, heart rate, MUAC, serum sodium, serum potassium, haematocrit (EVF),
     tuberculin induration and CD4 count all carry cutoffs in these books and
     none of them was captured at all.

So: a threshold is (subject, unit, kind, decision), and any one of those
missing means the row is not a threshold yet.

SUBJECT. Every ambiguous unit requires a subject term, found nearest before the
number, else in the enclosing headings AND THE TOPIC TITLE. The title matters:
sixteen transfusion thresholds - `<4 g/dL, or <5 g/dL and unstable` - name
haemoglobin nowhere except in the topic name, and a first version that searched
only the heading stack lost every one of them. The subject vocabulary was harvested
from the books themselves rather than written from memory - the words that
actually precede a comparator in these two volumes. A number whose subject
cannot be identified is written to thresholds_unattributed.tsv and is NOT
guessed into a bucket. `mm` is the case that proves the rule: in these books it
is mostly ECG amplitude, tuberculin induration and Ballard heel-toe, and only
occasionally MUAC.

KIND. `level` is an absolute value, `delta` a change ("a rise of >= 1 g/dL",
"respiratory rate up >= 5/min"), `rate` a change per unit time ("<= 10 mEq/L in
24 h"). Comparing a delta against a level is the same error as comparing two
decisions, one step down.

DECISION. Taken from the page: the enclosing heading and topic title, plus any
condition named in the fragment itself. Two rows are compared only when their
decisions share a distinctive word, and a row joins a group only when it shares
one with EVERY row already in it. Single linkage is not enough: A-B and B-C
chained A to C, and the first version collapsed every oxygen decision in both
books into one group of 14 cutoffs, which is the pooling this tool exists to
stop, one level up. Rows for the same quantity under different
decisions are printed in a separate section as NOT COMPARABLE, so they are
visibly excluded rather than silently pooled.

🛑 It SURFACES disagreements. Resolving one is a separate act and needs a
source - see ~/.claude/rules/leave-the-blank-blank.md, written after two dose
figures were invented while resolving exactly this kind of finding.

🛑 WVEMS is excluded, for the reason at the top of crossbook_dose_extract.py:
its figures are the original protocol's and are strict.

Output is written and flushed per row.
"""

import io
import os
import re
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crossbook_dose_extract as ex  # noqa: E402

OUTDIR = ex.OUTDIR
THR_OUT = os.path.join(OUTDIR, 'thresholds.tsv')
UNATTR_OUT = os.path.join(OUTDIR, 'thresholds_unattributed.tsv')
REPORT = os.path.join(OUTDIR, 'threshold_side_by_side.md')

_N = r'\d+(?:\.\d+)?(?:\s*[-–—]\s*\d+(?:\.\d+)?)?'
CMP = (r'(?:≥|≤|>=|<=|<|>|greater than|less than|at least|'
       r'no more than|below|above|under|over)')

# Unit surface forms. The key is the canonical unit written into the output.
UNITS = {
    '%': r'%',
    '°C': r'°\s?C',
    'g/dL': r'g\s*/\s*d[lL]',
    'g/L': r'g\s*/\s*[lL](?![a-z])',
    'mg/dL': r'mg\s*/\s*d[lL]',
    'mmol/L': r'mmol\s*/\s*[lL]',
    'mEq/L': r'mEq\s*/\s*[lL]',
    '/min': r'/\s*min|bpm',
    'mmHg': r'mmHg',
    'mm': r'mm(?![a-zA-Z/])',
    'cm': r'cm(?![a-zA-Z/])',
    '/mm3': r'/\s*mm³|cells\s*/\s*mm',
}

# (quantity, allowed units, subject regex).
#
# Harvested from the books: these are the words that actually precede a
# comparator in these two volumes, not a list written from memory. Order
# matters only for readability; attribution is by nearest match, not by order.
SUBJECTS = [
    ('oxygen saturation', {'%'},
     r'sp[o0][2₂]|sa[o0][2₂]|o\s*[2₂]\s*sat|oxygen satur|pulse\s*ox|'
     r'hypox|oximetr|desatur'),
    ('haematocrit (EVF/PCV)', {'%'},
     r'\bevf\b|\bpcv\b|h[ae]{1,2}matocrit'),
    ('peak flow', {'%'}, r'peak flow|\bpefr?\b'),
    ('burn surface area', {'%'}, r'\btbsa\b|body surface|burn'),
    ('temperature', {'°C'},
     r'temp|fever|febrile|hypotherm|pyrexi|axillary|rectal|\bcore\b'),
    ('haemoglobin', {'g/dL'},
     r'\bhb\b|\bhgb\b|h[ae]{1,2}moglobin|an[ae]{1,2}mi|transfus'),
    ('protein (fluid)', {'g/dL', 'g/L'}, r'protein'),
    ('blood glucose', {'mmol/L', 'mg/dL'},
     r'glucose|glyc[ae]{1,2}mi|dextrostix|\brbs\b|dextrose'),
    ('lactate', {'mmol/L'}, r'lactate'),
    ('sodium', {'mmol/L', 'mEq/L'}, r'sodium|natr|\bna\+?\b'),
    ('potassium', {'mmol/L', 'mEq/L'}, r'potassium|kal[ae]{1,2}mi|\bk\+'),
    ('C-reactive protein', {'mg/dL', 'g/L'}, r'\bcrp\b|c-reactive'),
    ('bilirubin', {'mg/dL'}, r'bilirubin|jaundice'),
    ('creatinine', {'mg/dL'}, r'creatinine|\bcr\b'),
    ('respiratory rate', {'/min'},
     r'respirat|breath|\brr\b|tachypn|\bapn'),
    ('heart rate', {'/min'},
     r'\bhr\b|pulse|heart rate|tachycard|bradycard'),
    ('systolic blood pressure', {'mmHg'}, r'\bsbp\b|systolic'),
    # Not labelled systolic: the page says "< 70 mmHg" under a
    # hypotension heading without saying which pressure. Recording it
    # as what the page says rather than as what it probably means.
    ('blood pressure', {'mmHg'},
     r'\bbp\b|hypotens|blood pressure|\bmap\b'),
    ('pulse pressure', {'mmHg'}, r'pulse pressure|\bpp\b'),
    ('PaO2', {'mmHg'}, r'pao₂|pao2'),
    ('MUAC', {'mm', 'cm'},
     r'\bmuac\b|mid[- ]upper arm|arm circumference'),
    ('tuberculin induration', {'mm'},
     r'tuberculin|mantoux|skin test|induration|\bbcg\b|\btst\b'),
    ('ECG amplitude', {'mm'},
     r'\bst\b|elevation|depression|\bwave\b|\bavl\b|\bavf\b|\bv[1-6]\b|'
     r'lead|deflection'),
    ('height/length', {'cm'},
     r'height|length|stature|standing|recumbent'),
    ('CD4 count', {'/mm3', '%'}, r'\bcd4\b'),
    ('reticulocyte count', {'%'}, r'retic'),
    ('fractional excretion of sodium', {'%'}, r'\bfena\b'),
    ('neutrophil count', {'/mm3'}, r'neutropen|neutrophil'),
    ('platelet count', {'/mm3'}, r'platelet|thrombocytopen'),
]

# A subject term that must NOT be read as its quantity when it appears in this
# company. `transferrin saturation` is a percentage and is not an SpO2.
SUBJECT_VETO = {
    'oxygen saturation': re.compile(r'transferrin', re.I),
}

# A compartment qualifier OVERRIDES the nearest subject, because the substance
# is the same word in both. `CSF: low glucose (< 1.5 mmol/L)` binds `glucose`
# nearer to the number than `CSF`, so nearest-wins alone filed three CSF
# glucoses as blood glucose - a cutoff a tenth of the blood one, compared
# against hypoglycaemia. Only quantities where a compartment changes the
# meaning are eligible.
COMPARTMENTS = [
    ('CSF', re.compile(r'\bcsf\b|cerebrospinal', re.I)),
    ('ascitic', re.compile(r'ascit', re.I)),
    ('pleural', re.compile(r'pleural', re.I)),
]
COMPARTMENT_OF = {'blood glucose': 'glucose', 'protein (fluid)': 'protein'}

# Words that make a number a CHANGE rather than a level.
DELTA = re.compile(
    r'(rise|rises|risen|rising|drop|drops|fall|falls|fell|increase|decrease|'
    r'up|down|change|gain|loss|by)\b', re.I)
# A time expression right after the value makes it a rate.
RATE_AFTER = re.compile(
    r'^\s*(?:in|per|over|/)\s*\d*\s*(?:h\b|hr|hour|day|24|48|min)', re.I)

# Headings and words that carry no decision on their own.
STOP = set('''a an and or the of for in on to with at by is are be as if
this that these those any all not no non per from into over under after
before management treatment assessment approach dx rx step steps chart
notes note give giving when where which what how paediatric pediatric adult
child children infant infants neonate neonatal severe acute chronic
emergency care hospital section page'''.split())

_WORD = re.compile(r'[a-zæ]+')



def window(text, start, end, before=190, after=190):
    """The text AROUND the match, not the first 400 characters of the unit.

    A fragment is truncated for the output column, and a match past that cut
    left the row showing text that does not contain the number the row
    reports. Six duration rows read as a malaria coma paragraph filed under
    iron; the drug and the duration were both real and both past character
    400. A row a reader cannot adjudicate from its own evidence is worse than
    no row.
    """
    a = max(0, start - before)
    b = min(len(text), end + after)
    out = text[a:b]
    if a:
        out = '…' + out
    if b < len(text):
        out = out + '…'
    return out


def norm(v):
    v = re.sub(r'[‐-―−]', '-', v).replace(' ', '')
    out = []
    for p in [p for p in v.split('-') if p]:
        try:
            out.append('%g' % float(p))
        except ValueError:
            out.append(p)
    return '-'.join(out)


def norm_cmp(c):
    c = c.lower().strip()
    return {'>=': '≥', '<=': '≤', 'greater than': '>',
            'less than': '<', 'at least': '≥', 'below': '<',
            'above': '>', 'under': '<', 'over': '>',
            'no more than': '≤'}.get(c, c)


def decision_words(text):
    """The distinctive words of a decision label, for matching across books."""
    ws = {w for w in _WORD.findall(text.lower())
          if len(w) > 3 and w not in STOP}
    # British/American and singular/plural collapse to one form.
    out = set()
    for w in ws:
        w = w.replace('ae', 'e').replace('oe', 'e')
        w = re.sub(r'(ia|ias|ic|ics|es|s)$', '', w)
        if len(w) > 3:
            out.add(w)
    return out


# A unit that can only mean one quantity in these books. Requiring a
# subject for these lost real rows: `T >39°C` and `Core > 32 °C`.
SELF_IDENTIFYING = {'°C': 'temperature'}

# A page's SUB-decisions. The general hypoglycaemia cutoff and the
# severe-malnutrition one sit in the same sentence and share every decision
# word, so decision clustering alone put them in one group; a reader separated
# them at a glance from the qualifier, and the tool could not. Eleven of 50
# flagged groups hold rows carrying different qualifiers. Harvested from the
# books, not invented: these are the qualifying clauses these two volumes
# actually attach to a cutoff.
QUALIFIERS = [
    ('severe malnutrition',
     re.compile(r'severe (?:acute )?malnutrition|\bSAM\b|severely malnourished'
                r'|kwashiorkor|marasm', re.I)),
    ('neonate', re.compile(r'neonat|newborn|first 48 h|preterm|\bLBW\b', re.I)),
    ('symptomatic', re.compile(r'symptomatic|fitting|convulsing|unconscious',
                               re.I)),
    ('malaria', re.compile(r'malaria', re.I)),
    ('on ART', re.compile(r'\bART\b|antiretroviral', re.I)),
    ('in pregnancy', re.compile(r'pregnan', re.I)),
]


def qualifiers(text, start=None, end=None):
    """Sub-decision qualifiers governing ONE number, not the whole fragment.

    `Blood glucose < 2.5 mmol/L, or < 3.0 mmol/L in severe malnutrition` holds
    both numbers and one qualifier, and reading the whole fragment tagged both.
    The qualifier is scoped to the CLAUSE containing the number: comma,
    semicolon, dash and pipe end a clause, and the qualifier may follow the
    number as well as precede it, which is how these books write it.
    """
    if start is None:
        return frozenset(n for n, rx in QUALIFIERS if rx.search(text))
    DELIM = (',', ';', '|', ' - ', '\u2014', '\u2013', '(', ')')
    a = max((text.rfind(d, 0, start) for d in DELIM), default=-1)
    ends = [i for i in (text.find(d, end) for d in DELIM) if i != -1]
    b = min(ends) if ends else len(text)
    clause = text[a + 1:b]
    return frozenset(n for n, rx in QUALIFIERS if rx.search(clause))


UNIT_RX = {u: re.compile(p, re.I) for u, p in UNITS.items()}
SUBJ_RX = [(q, us, re.compile(p, re.I)) for q, us, p in SUBJECTS]
THRESHOLD = re.compile(r'(' + CMP + r')\s*(' + _N + r')\s*')


def attribute(frag, ctx, title, start, unit):
    """Quantity for a number of `unit` at `start`, or None if unidentifiable.

    Nearest subject BEFORE the number wins, exactly as the dose extractor binds
    a dose to the nearest drug named before it. Falling back to the enclosing
    headings is what carries a table row whose subject is only in its header.
    """
    if unit in SELF_IDENTIFYING:
        return SELF_IDENTIFYING[unit], 'unit'
    best = None
    for q, units, rx in SUBJ_RX:
        if unit not in units:
            continue
        veto = SUBJECT_VETO.get(q)
        for m in rx.finditer(frag, 0, start):
            if veto and veto.search(frag[max(0, m.start() - 30):m.end() + 30]):
                continue
            if best is None or m.start() > best[0]:
                best = (m.start(), q)
    if best is not None:
        return compartment(frag, start, best[1]), 'fragment'
    for q, units, rx in SUBJ_RX:
        if unit not in units:
            continue
        veto = SUBJECT_VETO.get(q)
        m = rx.search(frag, start)
        if m and not (veto and veto.search(frag)):
            return compartment(frag, start, q), 'fragment-after'
    hay = ' || '.join(tuple(ctx) + (title,))
    for q, units, rx in SUBJ_RX:
        if unit not in units:
            continue
        veto = SUBJECT_VETO.get(q)
        m = rx.search(hay)
        if m and not (veto and veto.search(hay)):
            return compartment(hay, len(hay), q), 'context'
    return None, None


def compartment(text, start, quantity):
    """Rename a quantity when a compartment qualifier governs it."""
    noun = COMPARTMENT_OF.get(quantity)
    if noun is None:
        return quantity
    window = text[:start]
    for name, rx in COMPARTMENTS:
        m = None
        for m in rx.finditer(window):
            pass
        if m is None:
            continue
        # A blood/serum word AFTER the compartment word takes it back: the
        # clause has moved on to a different sample.
        if re.search(r'\bblood\b|\bserum\b|\bplasma\b',
                     window[m.end():], re.I):
            continue
        return '%s %s' % (name, noun)
    return quantity


def kind_of(frag, start, end):
    before = frag[max(0, start - 40):start]
    if DELTA.search(before):
        return 'delta'
    if RATE_AFTER.match(frag[end:end + 24]):
        return 'rate'
    return 'level'


def main():
    os.makedirs(OUTDIR, exist_ok=True)
    tf = io.open(THR_OUT, 'w', encoding='utf-8')
    tf.write('book\tfile\ttopic\tquantity\tunit\tkind\tcmp\tvalue\t'
             'decision\tvia\tqualifier\tfragment\n')
    tf.flush()
    uf = io.open(UNATTR_OUT, 'w', encoding='utf-8')
    uf.write('book\tfile\ttopic\tunit\tcmp\tvalue\tdecision\tfragment\n')
    uf.flush()

    n_thr = n_un = 0
    for book, book_dir in ex.BOOKS.items():
        tdir = os.path.join(ex.ROOT, book_dir, 'topics')
        paths = [os.path.join(tdir, n) for n in sorted(os.listdir(tdir))
                 if n.endswith('.yaml')]
        if book_dir in ex.HAS_FORMULARY:
            paths.append(os.path.join(ex.ROOT, book_dir, 'formulary.yaml'))
        for path in paths:
            with io.open(path, encoding='utf-8') as f:
                doc = ex.yaml.safe_load(f)
            title = ex.topic_title(doc, path)
            base = os.path.basename(path)
            units = []
            ex.collect(doc, [], units)
            here_t = here_u = 0
            for frag, ctx in units:
                decision = (title + ' › ' + ' › '.join(ctx[-2:])
                            ).replace('\t', ' ')[:200]
                for m in THRESHOLD.finditer(frag):
                    clean = re.sub(r'[*_`]', '', window(
                        frag, m.start(), m.end())).replace('\t', ' ')
                    tail = frag[m.end():m.end() + 18]
                    unit = None
                    for u, rx in UNIT_RX.items():
                        um = rx.match(tail)
                        if um:
                            unit = u
                            uend = m.end() + um.end()
                            break
                    if unit is None:
                        continue
                    q, via = attribute(frag, ctx, title, m.start(), unit)
                    if q is None:
                        uf.write('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' % (
                            book, base, title.replace('\t', ' '), unit,
                            norm_cmp(m.group(1)), norm(m.group(2)),
                            decision, clean))
                        uf.flush()
                        n_un += 1
                        here_u += 1
                        continue
                    tf.write(
                        '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n'
                        % (book, base, title.replace('\t', ' '), q, unit,
                           kind_of(frag, m.start(), uend), norm_cmp(m.group(1)),
                           norm(m.group(2)), decision, via,
                           '+'.join(sorted(qualifiers(frag, m.start(), uend))),
                           clean))
                    tf.flush()
                    n_thr += 1
                    here_t += 1
            print('%s %s: %d thresholds, %d unattributed (total %d / %d)'
                  % (book, base, here_t, here_u, n_thr, n_un), flush=True)
    tf.close()
    uf.close()
    print('DONE: %d thresholds -> %s' % (n_thr, THR_OUT), flush=True)
    print('DONE: %d unattributed -> %s' % (n_un, UNATTR_OUT), flush=True)
    report()
    return 0


def _span(value):
    """(low, high) for a value that may be a range, or None if not numeric."""
    v = value.replace('\u2013', '-').replace('\u2014', '-')
    parts = [x for x in v.split('-') if x]
    try:
        ns = [float(x) for x in parts]
    except ValueError:
        return None
    return (min(ns), max(ns))


def why_not_a_disagreement(pairs):
    """Say why a set of (cmp, value) is not a real difference, or None.

    Twelve of 62 flagged groups were one of these two, and neither is a
    clinical difference. They are labelled rather than dropped: the group still
    prints, under a heading that says why, so nothing is hidden from a reader.
    """
    nums = {v for _, v in pairs}
    cmps = {c for c, _ in pairs}
    if len(nums) == 1:
        below = {'<', '\u2264'}
        above = {'>', '\u2265'}
        if cmps <= below or cmps <= above:
            return ('same number, the comparator differs only at the value '
                    'itself')
        return ('same number read in both directions - a trigger on one page '
                'and a target on the other, not a disagreement about the '
                'number')
    spans = [_span(v) for v in nums]
    if any(x is None for x in spans):
        return None
    lo = min(x[0] for x in spans)
    hi = max(x[1] for x in spans)
    widest = [x for x in spans if x == (lo, hi)]
    if widest and all(lo <= x[0] and x[1] <= hi for x in spans) and \
            len({x[0] for x in spans}) == 1:
        return ('one book prints a wider range that contains the other; they '
                'share a lower bound')
    return None


def report():
    rows = []
    with io.open(THR_OUT, encoding='utf-8') as f:
        next(f)
        for line in f:
            c = line.rstrip('\n').split('\t')
            if len(c) == 12:
                rows.append(c)

    groups = defaultdict(list)
    for c in rows:
        groups[(c[3], c[4], c[5])].append(c)

    rf = io.open(REPORT, 'w', encoding='utf-8')
    rf.write('# Thresholds, by quantity and by the DECISION each one gates\n\n')
    rf.write('Generated by `tool/threshold_extract.py`. WVEMS is excluded '
             '(its figures are the\noriginal protocol\'s and are strict). '
             '**Candidates, not findings** — read the context.\n\n'
             'A cutoff is comparable to another only when both gate the same '
             'decision. Rows for\none quantity under different decisions are '
             'listed under NOT COMPARABLE rather than\npooled, which is what '
             'the previous version did and why it reported nothing.\n\n')
    rf.flush()

    n_cmp = n_not = n_benign = 0
    for key in sorted(groups):
        quantity, unit, kind = key
        rs = groups[key]
        buckets = []
        for c in rs:
            ws = decision_words(c[8])
            qs = frozenset(x for x in c[10].split('+') if x)
            for b in buckets:
                if b['qual'] == qs and all(ws & w for w in b['each']):
                    b['each'].append(ws)
                    b['rows'].append(c)
                    break
            else:
                buckets.append({'each': [ws], 'rows': [c], 'qual': qs})

        rf.write('## %s — %s (%s)\n\n' % (quantity, unit, kind))
        for b in buckets:
            byval = defaultdict(list)
            for c in b['rows']:
                byval[c[6] + ' ' + c[7]].append(c)
            books = {c[0] for c in b['rows']}
            label = sorted({c[8].split(' › ')[0] for c in b['rows']})
            differ = len(byval) > 1
            head = ' / '.join(label)[:120]
            if b['qual']:
                head += ' [' + ', '.join(sorted(b['qual'])) + ']'
            benign = why_not_a_disagreement(
                [(c[6], c[7]) for c in b['rows']]) if differ else None
            if benign:
                n_benign += 1
                rf.write('### ○ %s — not a disagreement: %s\n\n'
                         % (head, benign))
            elif differ and len(books) > 1:
                n_cmp += 1
                rf.write('### ⚠ %s — %d different cutoffs, '
                         'both books\n\n' % (head, len(byval)))
            elif differ:
                n_cmp += 1
                rf.write('### ⚠ %s — %d different cutoffs, '
                         '%s only\n\n' % (head, len(byval), list(books)[0]))
            else:
                n_not += 1
                rf.write('### %s — agreed at %s\n\n'
                         % (head, list(byval)[0]))
            for v in sorted(byval):
                for c in byval[v][:3]:
                    rf.write('- `%s` **%s** — %s\n  > %s\n'
                             % (v, c[0], c[8][:110], c[11][:190]))
            rf.write('\n')
            rf.flush()
        if len(buckets) > 1:
            rf.write('> NOT COMPARABLE: the %d groups above gate different '
                     'decisions and are not compared with each other.\n\n'
                     % len(buckets))
    rf.close()
    print('DONE: %d groups with differing cutoffs, %d benign (comparator or '
          'contained range), %d agreed -> %s'
          % (n_cmp, n_benign, n_not, REPORT), flush=True)


if __name__ == '__main__':
    sys.exit(main())
