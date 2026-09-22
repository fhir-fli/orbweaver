#!/usr/bin/env python3
"""Stage 1 of the cross-book dose comparison.

Pulls EVERY dose-bearing text fragment out of both books — all 95 ProtocolBook
topics, all 259 WHO topics, and both formularies — and writes one TSV row per
(drug, dose fragment) pair.

Why this exists: four of the thirteen WHO advance-pass flags turned out to be
the same shape — the two books give different numbers for one drug in one
indication — and two of those four were patient-safety. Every one was found by
noticing it. This runs the comparison exhaustively instead.

Stage 2 (crossbook_dose_diff.py) groups these rows by drug and reports where
the books disagree.

STRUCTURE MATTERS, and the first version of this script got it wrong three
ways, all of which silently produced zero rows:

  1. A table row puts the drug in cell 0 and the dose in cell 3. Walking string
     leaves separately meant kanamycin's "20 mg/kg IM/IV" was never attached to
     the word "Kanamycin". Table rows are now joined before matching.
  2. The formulary — the densest dose source in either book — nests `doses` and
     `notes` under a drug entry whose `name` is a sibling, not a parent, of the
     dose text. Formulary entries are now walked with the drug pre-bound.
  3. Zinc, iron and folate were on a stop-list as "too generic". They are real
     drugs with real doses in a paediatric book, and every one of their doses
     was being dropped.

Output is written and flushed per row. Never buffer: a crash mid-run must still
leave usable output.
"""

import io
import os
import re
import sys

import yaml
from _repo import REPO

ROOT = str(REPO / 'assets/books')
OUTDIR = str(REPO / 'tool/crossbook')
OUT = os.path.join(OUTDIR, 'doses.tsv')

# 🛑 WVEMS IS DELIBERATELY EXCLUDED, and must stay excluded.
#
# Its doses are the WVEMS protocol's own, transcribed from the original. They
# are strict: the protocol is the authority for a crew operating under it, and
# a difference between WVEMS and a paediatric reference is not an error to
# reconcile. Grey, 2026-08-28: "We're using the wvems doses that were in the
# original, we shouldn't be comparing to the other books, wvems has strict
# doses."
#
# This is the dose counterpart of the print-fidelity rule already recorded for
# WVEMS diagrams: reproduce it, do not improve it.
#
# The ProtocolBook and the WHO Pocket Book ARE compared, because both are
# maintained here and both are being corrected against current evidence.
BOOKS = {
    'PB': 'protocolbook',
    'WHO': 'who_imci',
}
HAS_FORMULARY = {'protocolbook', 'who_imci'}

# Names that appear in the text but not as a formulary entry, and spellings
# that differ between the two books. Key = canonical name, value = the alternate
# surface forms to match on. Matching is case-insensitive and whole-word.
SYNONYMS = {
    'paracetamol': ['acetaminophen', 'tylenol', 'panadol'],
    'adrenaline': ['epinephrine'],
    'noradrenaline': ['norepinephrine'],
    'co-trimoxazole': ['cotrimoxazole', 'trimethoprim-sulfamethoxazole',
                       'trimethoprim–sulfamethoxazole', 'tmp-smx', 'tmp/smx',
                       'septrin', 'bactrim', 'trimethoprim'],
    'acetylcysteine': ['n-acetylcysteine'],
    'salbutamol': ['albuterol'],
    'furosemide': ['frusemide'],
    'lidocaine': ['lignocaine'],
    'dextrose': ['glucose'],
    'benzylpenicillin': ['penicillin g', 'crystalline penicillin',
                         'benzyl penicillin'],
    # Phenoxymethylpenicillin is a DIFFERENT drug, oral, and the two books
    # use it for different things. Conflating them made the ProtocolBook's
    # oral pharyngitis dose look like a disagreement with WHO's IV neonatal
    # one.
    'penicillin v': ['phenoxymethylpenicillin', 'pen v'],
    'aciclovir': ['acyclovir'],
    'phenobarbital': ['phenobarbitone'],
    'magnesium sulfate': ['magnesium sulphate'],
    'ferrous sulfate': ['ferrous sulphate'],
    'vitamin k': ['phytomenadione', 'phytonadione'],
    'zinc': ['zinc sulfate', 'zinc sulphate'],
    'iron': ['elemental iron'],
    'folic acid': ['folate'],
    'dolutegravir': ['dtg'],
    'zidovudine': ['zdv', 'azt'],
    'lamivudine': ['3tc'],
    'abacavir': ['abc backbone'],
    'tenofovir': ['tdf', 'taf', 'tenofovir alafenamide'],
    'efavirenz': ['efv'],
    'nevirapine': ['nvp'],
    'flucytosine': ['5-fc'],
    'amphotericin b': ['amphotericin'],
    'potassium chloride': ['kcl'],
    'sodium valproate': ['valproic acid'],
    'hydrochlorothiazide': ['hctz'],
    'pethidine': ['meperidine'],
    'sulfadoxine-pyrimethamine': ['sulphadoxine-pyrimethamine', 'sp'],
}

# WVEMS names its drug cards by BRAND or by ward shorthand — Ativan, Narcan,
# Versed, Zofran, Toradol, Rocephin, Decadron, Keppra, Levophed, and Epi /
# Nitro / Bicarb / D10 / TXA. 35 of its 50 drug cards matched nothing until
# these were mapped, so most of the third book's doses were invisible.
BRANDS = {
    'lorazepam': ['ativan'],
    'diphenhydramine': ['benadryl'],
    'naloxone': ['narcan'],
    'midazolam': ['versed'],
    'ondansetron': ['zofran'],
    'ketorolac': ['toradol'],
    'ceftriaxone': ['rocephin'],
    'dexamethasone': ['decadron'],
    'levetiracetam': ['keppra'],
    'noradrenaline': ['levophed'],
    'haloperidol': ['haldol'],
    'sodium bicarbonate': ['bicarb'],
    'activated charcoal': ['charcoal'],
    'dextrose': ['d10', 'd50', 'd25'],
    'magnesium sulfate': ['magnesium'],
    'tranexamic acid': ['txa'],
    'adrenaline': ['epi', 'epi neb', 'epi drip', 'epi push'],
    'phenylephrine': ['neo push', 'neo-synephrine'],
    'metoprolol': ['lopressor'],
    'cefazolin': ['ancef'],
    'ipratropium': ['atrovent'],
    'oxymetazoline': ['afrin'],
    'hydroxocobalamin': ['cyanokit'],
    'nitroglycerin': ['nitro', 'nitro drip', 'nitroglycerine', 'gtn'],
    'hypertonic saline': ['3% saline'],
    'amiodarone': ['amio', 'pacerone'],
    'etomidate': [],
    'glucagon': [],
    'propofol': [],
    'rocuronium': [],
    'succinylcholine': ['sux'],
    'tetracaine': [],
    'duodote': [],
}

# Drugs that are PRESCRIBED in the text of one or both books but are not a
# formulary entry in either, so the formulary-derived vocabulary misses them.
# A missing drug does not merely lose its own doses — it hands them to whichever
# drug IS in the vocabulary nearest by. Both antihistamine and steroid doses in
# the anaphylaxis bullet were being attributed to adrenaline until these were
# added. Found with crossbook_vocab_gaps.py, which lists every drug-like word
# that sits immediately before a dose and is not already matched.
EXTRA_DRUGS = [
    'amitriptyline', 'amodiaquine', 'atropine', 'betamethasone',
    'sodium bicarbonate', 'budesonide', 'bupivacaine', 'activated charcoal',
    'clindamycin', 'dapagliflozin', 'digoxin', 'dihydroartemisinin',
    'diphenhydramine', 'empagliflozin', 'ethionamide', 'famotidine',
    'flucloxacillin', 'haloperidol', 'hydrocortisone', 'ketorolac',
    'labetalol', 'levetiracetam', 'mannitol', 'mefloquine', 'meropenem',
    'metformin', 'midazolam', 'naloxone', 'naproxen', 'nicardipine',
    'nitroprusside', 'norfloxacin', 'octreotide', 'olanzapine', 'ondansetron',
    'phenylephrine', 'phosphorus', 'piperaquine', 'pralidoxime', 'primaquine',
    'rifaximin', 'terlipressin', 'vancomycin', 'sulfamethoxazole',
    'sulfadoxine', 'clavulanate', 'lorazepam', 'enoxaparin', 'ivig',
    # Found 2026-08-29 by listing every table row-label whose row carries a
    # dose and matches nothing in the vocabulary. Caffeine citrate is the
    # one that mattered: its neonatal loading and maintenance doses were
    # being filed under ampicillin, the drug named two rows above it.
    'caffeine citrate', 'penicillin vk', 'rabies immunoglobulin',
    'whole blood', 'packed red blood cells',
    'methionine', 'deferoxamine', 'nifedipine', 'amlodipine', 'lisinopril',
    'losartan', 'hydralazine', 'spironolactone', 'ketamine', 'morphine',
    'tranexamic acid', 'oxytocin', 'misoprostol', 'insulin', 'heparin',
]

# Units we treat as a dose. Ordered longest-first so "mg/kg/day" wins over "mg".
UNITS = [
    'mg/kg/dose', 'mg/kg/day', 'mg/kg/hr', 'mg/kg/h', 'mg/kg/min',
    'mcg/kg/min', 'mcg/kg/hr', 'mcg/kg/h', 'mcg/kg/dose', 'mcg/kg',
    'µg/kg/min', 'µg/kg', 'ug/kg',
    'ml/kg/day', 'ml/kg/hr', 'ml/kg/h', 'ml/kg',
    'mmol/kg/day', 'mmol/kg', 'mmol/l',
    'units/kg/hr', 'units/kg', 'iu/kg',
    'g/kg/day', 'g/kg',
    'kcal/kg/day', 'kcal/kg',
    'mg/kg', 'mg/day', 'mg/dose', 'mg/ml', 'mg/m2',
    'mcg/ml', 'mcg', 'µg/l', 'µg',
    'mg', 'g/day', 'gm', 'g',
    'ml/hr', 'ml/h', 'ml',
    'units', 'iu',
    'mmhg',
]
UNIT_RE = '|'.join(re.escape(u) for u in UNITS)

# A number, optionally a range or a decimal, then a unit. Allows the en-dash and
# the hyphen: the print uses one and the app the other, and that difference has
# already cost a whole instrument in this project.
# One number: a thousands-grouped form FIRST (the two books write vitamin A as
# "50 000 IU" and "50,000 IU" respectively — without this, the space form parsed
# as 0 and the comma form as 50, so the same dose could never match itself),
# then a plain decimal. Optionally a range.
_ONE = r'(?:\d{1,3}(?:[ \u00a0,]\d{3})+|\d+(?:[.,]\d+)?)'
NUM = _ONE + r'(?:\s*[-–—]\s*' + _ONE + r')?'
DOSE_RE = re.compile(r'(?<![\w./])(' + NUM + r')\s*(' + UNIT_RE + r')(?![\w/])',
                     re.IGNORECASE)

# Frequency, captured separately — 8 mg/kg q8h and 8 mg/kg once daily are not
# the same dose, and flag 4-1 turned entirely on that distinction.
FREQ_RE = re.compile(
    r'\b(?:'
    r'q\s?\d+\s?(?:h|hr|hrs|hours)\b|'
    r'(?:once|twice|three times|four times|thrice)\s+(?:a\s+|per\s+)?(?:day|daily)|'
    r'(?:od|bd|bid|tds|tid|qid|qds|qd|prn|stat)\b|'
    r'\d+\s*(?:x|×)\s*(?:a\s+)?(?:day|daily)|'
    r'every\s+\d+(?:\s*[-–]\s*\d+)?\s*(?:h|hr|hrs|hours|min|minutes|days|weeks)|'
    r'daily|nocte'
    r')', re.IGNORECASE)

# A drug named as an ALLERGY or a CONTRAINDICATION is not a prescription.
# "Clindamycin PO — for penicillin allergy | 7mg/kg (max 300mg) 8 hourly" put
# the word penicillin nearer the dose than clindamycin, and the ProtocolBook's
# clindamycin dose was filed under benzylpenicillin and read as a disagreement
# with WHO's neonatal IV dose.
NOT_A_PRESCRIPTION = re.compile(
    r"^\W{0,3}(?:"
    r"allergy|allergic|hypersensitivity|intoleran|anaphylaxis|reaction|"
    r"resistan|sensitiv"
    r")", re.I)
ALLERGIC_TO = re.compile(r"(?:allergic to|allergy to|intolerant of)\W*$", re.I)

# Keys whose value is a heading for everything nested under it.
# `drug` is WVEMS's medication-block key, a SIBLING of `dose`/`route`/
# `frequency` — the same shape as the formulary's name/regimen, and the
# same trap: without it, "300 -> 150 mg" has no drug anywhere in its own
# subtree and lands on whatever the block title happens to name.
TITLE_KEYS = ('title', 'label', 'decision', 'name', 'drug',
              'list_subtitle')



# A drug name written with one dash does not match the same name written with
# another. The formulary spells it `Amoxicillin–clavulanate` with an EN DASH
# and the page that prescribes it writes `amoxicillin-clavulanate` with a
# HYPHEN, so the page's dose was invisible to the extractor and the parity
# guard reported the formulary entry as an orphan. Six drugs here carry an
# en-dash form and only four also carry the hyphen form. This is the same
# failure as requiring one letter case over prose: one of several equivalent
# writings, and the miss is silent.
_DASHES = '-\u2010\u2011\u2012\u2013\u2014\u2015\u2212'


def drug_pattern(form):
    """Regex for a drug surface form, matching any dash for any dash."""
    parts = [re.escape(p) for p in re.split('[' + _DASHES + ']', form)]
    return r'(?<![\w-])' + ('[' + _DASHES + r']\s?').join(parts) + r'(?![\w-])'

def build_vocab():
    """Canonical drug name -> set of surface forms, from BOTH formularies."""
    vocab = {}
    for book_dir in BOOKS.values():
        if book_dir not in HAS_FORMULARY:
            continue
        path = os.path.join(ROOT, book_dir, 'formulary.yaml')
        with io.open(path, encoding='utf-8') as fh:
            doc = yaml.safe_load(fh)
        for d in formulary_drugs(doc):
            name = (d.get('name') or '').strip()
            if not name:
                continue
            base = re.sub(r'\s*\(.*?\)\s*', ' ', name).strip()
            canon = base.lower()
            forms = vocab.setdefault(canon, set())
            forms.add(canon)
            for paren in re.findall(r'\(([^)]+)\)', name):
                p = paren.strip().lower()
                if len(p) <= 12 and ' ' not in p:
                    forms.add(p)
            for half in re.split(r'\s*/\s*', base):
                h = half.strip().lower()
                if h and len(h) > 3:
                    forms.add(h)
    for canon, alts in SYNONYMS.items():
        forms = vocab.setdefault(canon, set())
        forms.add(canon)
        forms.update(a.lower() for a in alts)
    for name in EXTRA_DRUGS:
        vocab.setdefault(name, set()).add(name)
    for canon, brands in BRANDS.items():
        forms = vocab.setdefault(canon, set())
        forms.add(canon)
        forms.update(b.lower() for b in brands)

    # Surface forms too generic to match on their own. Kept deliberately short:
    # the first version stopped zinc, iron and folate and lost every one of
    # their doses.
    STOP = {'water', 'oxygen', 'air', 'salt', 'sugar', 'milk', 'blood', 'gel',
            'oil', 'food', 'fluid', 'fluids',
            # Formulary abbreviations that collide with ordinary clinical
            # text. "ABC" is Airway-Breathing-Circulation far more often than
            # it is abacavir, and it was matching every resuscitation bullet
            # in both books. "SP" and "pre-referral" are the same problem.
            'abc', 'sp', 'pre-referral'}
    for canon in list(vocab):
        vocab[canon] = {f for f in vocab[canon] if len(f) >= 3 and f not in STOP}
        if not vocab[canon]:
            del vocab[canon]

    # MERGE canonicals that share any surface form. Without this the two
    # formularies produce "dextrose / glucose" (ProtocolBook) and "dextrose"
    # (WHO) as separate drugs, both matching the same sentences, and every
    # dextrose row is double-counted and never compared.
    parent = {c: c for c in vocab}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            if len(rb) < len(ra):
                ra, rb = rb, ra
            parent[rb] = ra

    owner = {}
    for canon, forms in vocab.items():
        for f in forms:
            if f in owner:
                union(owner[f], canon)
            else:
                owner[f] = canon

    merged = {}
    for canon, forms in vocab.items():
        merged.setdefault(find(canon), set()).update(forms)
    return merged


def formulary_drugs(doc):
    """The drug entries of a formulary document, whatever it is wrapped in."""
    if not isinstance(doc, dict):
        return []
    node = doc.get('formulary', doc)
    if isinstance(node, dict):
        for key in ('drugs', 'entries', 'items'):
            if isinstance(node.get(key), list):
                return [d for d in node[key] if isinstance(d, dict)]
    return []


def cell_text(cells):
    """Flatten a table row's cells to plain strings, or None if it is not a row.

    A cell is usually a string, but a spanning cell is written as
    `{text: "...", span: 2}`. The first version only joined rows whose cells
    were ALL strings, so a row with one spanning cell fell through to the
    generic walk, its drug in cell 0 was separated from its dose, and the dose
    was attributed to whatever came before. That is how the ProtocolBook's
    clindamycin dose ended up filed under benzylpenicillin.
    """
    if not isinstance(cells, list) or not cells:
        return None
    out = []
    for c in cells:
        if isinstance(c, str):
            out.append(c)
        elif isinstance(c, dict) and isinstance(c.get('text'), str):
            out.append(c['text'])
        else:
            return None
    return out


def fragments(text):
    """Split a markdown block into (fragment, parent) pairs.

    A bullet is the unit: in this corpus a dose almost never spans two bullets,
    but two different doses very often sit in two adjacent bullets.

    A SUB-bullet inherits its parent bullet's text for drug matching only. The
    books routinely name the drug in the parent and put the numbers underneath:

        - Give prophylactic SC adrenaline before the infusion
          - 0.005 mg/kg (= 0.005 ml/kg of 1:1000), capped at 0.25 mg

    Without inheritance the sub-bullet names no drug at all and its dose is
    dropped — which is exactly what happened to the WHO snake-bite dose, making
    the ProtocolBook look like the only book that carried it.
    """
    lines = text.split('\n')
    items = []          # (indent, text)
    cur_indent = 0
    cur = []
    bullet = re.compile(r'^(\s*)(?:[-*]\s+|\d+\.\s+)(.*)$')
    for line in lines:
        m = bullet.match(line)
        if m:
            if cur:
                items.append((cur_indent, ' '.join(cur)))
            cur_indent = len(m.group(1))
            cur = [m.group(2)]
        else:
            cur.append(line.strip())
    if cur:
        items.append((cur_indent, ' '.join(cur)))

    out = []
    stack = []          # (indent, text) of enclosing bullets
    for indent, body in items:
        body = re.sub(r'\s+', ' ', body).strip(' -*\t')
        while stack and stack[-1][0] >= indent:
            stack.pop()
        parent = stack[-1][1] if stack else ''
        if body:
            out.append((body, parent))
        stack.append((indent, body))
    return out


def collect(node, ctx, out):
    """Yield (fragment, context) for every dose-bearing unit.

    `ctx` is the stack of enclosing headings — block titles, flowchart box
    labels, decision text. A drug named only in the heading still binds to a
    dose in the body, which is how most flowchart boxes are written.
    """
    if isinstance(node, str):
        for frag, parent in fragments(node):
            # The parent bullet joins the context stack, so a drug named there
            # binds to a dose written in the sub-bullet beneath it.
            out.append((frag, tuple(ctx) + ((parent,) if parent else ())))
        return

    if isinstance(node, list):
        # A table row: join it, so the drug in cell 0 stays with the dose in
        # cell 3.
        flat = cell_text(node)
        if flat is not None and all(isinstance(v, str) for v in node):
            out.append((re.sub(r'\s+', ' ', ' | '.join(flat)).strip(),
                        tuple(ctx)))
            return
        for v in node:
            collect(v, ctx, out)
        return

    if isinstance(node, dict):
        # `cells: [...]` is a table row.
        flat = cell_text(node.get('cells'))
        if flat is not None:
            out.append((re.sub(r'\s+', ' ', ' | '.join(flat)).strip(),
                        tuple(ctx)))
            rest = {k: v for k, v in node.items() if k != 'cells'}
        else:
            rest = node
        heads = [str(rest[k]) for k in TITLE_KEYS
                 if isinstance(rest.get(k), str) and rest[k].strip()]
        child_ctx = ctx + heads
        for k, v in rest.items():
            if k in ('palette', 'tags', 'aliases', 'id', 'page_number',
                     'column_flex', 'column_align', 'severity', 'kind',
                     'shape', 'variant', 'last_reviewed', 'category'):
                continue
            collect(v, child_ctx, out)
        return


def topic_title(doc, path):
    if isinstance(doc, dict):
        t = doc.get('topic')
        if isinstance(t, dict) and t.get('title'):
            return str(t['title'])
        if isinstance(doc.get('title'), str):
            return doc['title']
        f = doc.get('formulary')
        if isinstance(f, dict) and isinstance(f.get('title'), str):
            return f['title']
    return os.path.basename(path)


def main():
    vocab = build_vocab()
    surfaces = sorted(
        ((form, canon) for canon, forms in vocab.items() for form in forms),
        key=lambda fc: -len(fc[0]))
    patterns = [(re.compile(drug_pattern(f),
                            re.IGNORECASE), canon)
                for f, canon in surfaces]
    print('vocabulary: %d canonical drugs, %d surface forms'
          % (len(vocab), len(surfaces)), flush=True)

    os.makedirs(OUTDIR, exist_ok=True)
    fh = io.open(OUT, 'w', encoding='utf-8')
    fh.write('book\tfile\ttopic\tdrug\tvalue\tunit\tfreq\tcontext\tfragment\n')
    fh.flush()

    def emit(book, base, title, units_seen, carry=None):
        """Write one row per dose, attached to the drug it actually belongs to.

        The first version of this attached EVERY dose in a fragment to EVERY
        drug named in it. In a bullet reading "Diphenhydramine 1mg/kg ...
        Hydrocortisone 5mg/kg ..." that produced four rows, two of them wrong,
        and in a joined table row it was worse. A dose now binds to the
        NEAREST DRUG MENTION BEFORE IT — which is also how a table row reads,
        drug in cell 0 and its doses after — falling back to the nearest
        mention after it, and only then to a drug named in the heading.
        """
        frag, ctx, bound = units_seen
        doses = list(DOSE_RE.finditer(frag))
        if not doses:
            return 0

        # Inside a FORMULARY entry the drug is not in question - it is the
        # entry we are standing in - so `bound` is authoritative there and the
        # nearest-mention rule below is skipped. Only the formulary walk passes
        # a non-empty `bound`; every topic file passes ().
        #
        # This was wrong until 2026-08-30. Phenobarbital's regimen reads "after
        # two doses of diazepam have failed", so its loading dose was filed
        # under DIAZEPAM, and the guard that caught a reintroduced phenobarbital
        # defect named the wrong drug. The same bug filed prednisolone's
        # milligrams under hydrocortisone and flucytosine's under amphotericin,
        # which cost a real read each during the intra-book pass.
        if bound:
            clean_b = re.sub(r'[*_`]', '', frag)[:400].replace('\t', ' ')
            ctx_b = ' › '.join(ctx[-3:]).replace('\t', ' ')[:200]
            freq_b = ';'.join(sorted(set(
                x.lower() for x in FREQ_RE.findall(frag))))
            # ...unless another drug is named IMMEDIATELY before the dose.
            # A formulary entry routinely quotes a companion or fallback agent
            # with its own dose - cefixime's entry ends "if neither is
            # available: gentamicin 240 mg IM", and diazepam's note says
            # "repeat PHENOBARBITAL 10 mg/kg after 30 min". Those belong to the
            # drug named, not to the entry. A drug mentioned further away does
            # NOT capture the dose: phenobarbital's own regimen reads "20 mg/kg
            # ... after two doses of diazepam have failed", where diazepam
            # follows the dose and is not its owner.
            NEAR = 20
            near = []
            claimed_n = []
            for pat, canon in patterns:
                for m in pat.finditer(frag):
                    if any(m.start() < e and st < m.end()
                           for st, e in claimed_n):
                        continue
                    claimed_n.append((m.start(), m.end()))
                    if canon not in bound:
                        near.append((m.start(), m.end(), canon))
            near.sort()

            n_b = 0
            for dm in doses:
                owner = bound
                prior = [c for st, e, c in near
                         if e <= dm.start() and dm.start() - e <= NEAR]
                if prior:
                    owner = (prior[-1],)
                for canon in owner:
                    fh.write('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' % (
                        book, base, title.replace('\t', ' '), canon,
                        dm.group(1).strip(), dm.group(2).lower(),
                        freq_b, ctx_b, clean_b))
                    fh.flush()
                    n_b += 1
            return n_b

        # Every drug mention in the fragment, with its position. Longest
        # surface forms are tried first and their spans claimed, so
        # "magnesium sulfate" is not also counted as "magnesium".
        mentions = []
        claimed = []
        for pat, canon in patterns:
            for m in pat.finditer(frag):
                if any(m.start() < e and s < m.end() for s, e in claimed):
                    continue
                claimed.append((m.start(), m.end()))
                # Skip a drug named only as an allergy or a contraindication.
                if (NOT_A_PRESCRIPTION.search(frag[m.end():m.end() + 24])
                        or ALLERGIC_TO.search(frag[max(0, m.start() - 24):
                                                   m.start()])):
                    continue
                mentions.append((m.start(), m.end(), canon))
        mentions.sort()

        # Drugs named only in the enclosing heading — used when the fragment
        # itself names none, which is how most flowchart boxes are written.
        # Headings are searched INNERMOST FIRST: the nearest heading is the
        # most specific, and a book's chapter title routinely names a drug that
        # has nothing to do with the bullet in hand.
        ctx_drugs = list(bound)
        for head in reversed(ctx):
            found = []
            claimed_h = []
            for pat, canon in patterns:
                m = pat.search(head)
                if not m:
                    continue
                if any(m.start() < e and st < m.end() for st, e in claimed_h):
                    continue
                claimed_h.append((m.start(), m.end()))
                found.append(canon)
            for canon in found:
                if canon not in ctx_drugs:
                    ctx_drugs.append(canon)
            if found:
                break

        freq = FREQ_RE.findall(frag)
        freq_s = ';'.join(sorted(set(x.lower() for x in freq)))
        clean = re.sub(r'[*_`]', '', frag)[:400].replace('\t', ' ')
        ctx_s = ' › '.join(ctx[-3:]).replace('\t', ' ')[:200]

        if mentions and carry is not None:
            carry[0], carry[1] = mentions[-1][2], ctx

        n = 0
        for dm in doses:
            before = [c for s, e, c in mentions if e <= dm.start()]
            after = [c for s, e, c in mentions if s >= dm.end()]
            if before:
                drugs = [before[-1]]
            elif after:
                drugs = [after[0]]
            elif ctx_drugs:
                drugs = ctx_drugs[:1]
            elif carry and carry[0] and carry[1] == ctx:
                # Last resort: the drug named by the PREVIOUS fragment, and ONLY
                # when that fragment sits under the identical heading chain —
                # i.e. a true sibling. Unscoped, this carried metronidazole from
                # a treatment bullet into the diet tables further down the file
                # and dosed rice, sugar and whole egg as if they were the drug.
                drugs = [carry[0]]
            else:
                continue
            value, unit = dm.group(1), dm.group(2)
            for drug in drugs:
                fh.write('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' % (
                    book, base, title.replace('\t', ' '), drug,
                    value.strip(), unit.lower(), freq_s, ctx_s, clean))
                fh.flush()
                n += 1
        return n

    rows = 0
    files = 0
    for book, book_dir in BOOKS.items():
        tdir = os.path.join(ROOT, book_dir, 'topics')
        paths = [os.path.join(tdir, n) for n in sorted(os.listdir(tdir))
                 if n.endswith('.yaml')]
        formulary_path = os.path.join(ROOT, book_dir, 'formulary.yaml')

        for path in paths:
            files += 1
            with io.open(path, encoding='utf-8') as f:
                try:
                    doc = yaml.safe_load(f)
                except yaml.YAMLError as e:
                    print('!! YAML error %s: %s' % (path, e), flush=True)
                    continue
            title = topic_title(doc, path)
            base = os.path.basename(path)
            units = []
            collect(doc, [], units)
            here = 0
            carry = [None, None]
            for frag, ctx in units:
                here += emit(book, base, title, (frag, ctx, ()), carry)
            rows += here
            print('%s %s: %d dose rows (total %d)' % (book, base, here, rows),
                  flush=True)

        # The formulary is walked per drug entry, with the drug pre-bound, so a
        # `regimen:` string that never repeats the drug's name still lands on
        # the right drug. WVEMS has none.
        if book_dir not in HAS_FORMULARY:
            continue
        files += 1
        with io.open(formulary_path, encoding='utf-8') as f:
            doc = yaml.safe_load(f)
        canon_of = {}
        for canon, forms in vocab.items():
            for form in forms:
                canon_of[form] = canon
        here = 0
        for d in formulary_drugs(doc):
            name = (d.get('name') or '').strip()
            base_name = re.sub(r'\s*\(.*?\)\s*', ' ', name).strip().lower()
            bound = ()
            if base_name in canon_of:
                bound = (canon_of[base_name],)
            units = []
            collect(d, [name], units)
            carry = [None, None]
            for frag, ctx in units:
                here += emit(book, 'formulary.yaml', 'Formulary',
                             (frag, ctx, bound), carry)
        rows += here
        print('%s formulary.yaml: %d dose rows (total %d)' % (book, here, rows),
              flush=True)

    fh.close()
    print('DONE: %d files, %d rows -> %s' % (files, rows, OUT), flush=True)

    # Coverage: which drugs in the vocabulary produced NO dose row at all.
    # A silent zero is how an extractor lies about a complete pass, so the
    # misses get written out and read, not assumed to be empty on purpose.
    seen = set()
    with io.open(OUT, encoding='utf-8') as f:
        next(f)
        for line in f:
            seen.add(line.split('\t')[3])
    miss_path = os.path.join(OUTDIR, 'vocab_misses.txt')
    mf = io.open(miss_path, 'w', encoding='utf-8')
    misses = 0
    for canon in sorted(vocab):
        if canon not in seen:
            mf.write(canon + '\t' + '; '.join(sorted(vocab[canon])) + '\n')
            mf.flush()
            misses += 1
    mf.close()
    print('vocabulary drugs with ZERO dose rows: %d (listed in %s)'
          % (misses, miss_path), flush=True)


if __name__ == '__main__':
    sys.exit(main())
