#!/usr/bin/env python3
"""Find charts where the SICKER branch gets the WEAKER treatment.

This is the hyperkalaemia shape. That algorithm sent the K > 6.5 / ECG-changes
patient to calcium, furosemide and dialysis, while insulin-glucose and
salbutamol — the two things that actually lower serum potassium in the first
hour — sat on the milder 6.0–6.5 branch. The sickest patient got nothing that
lowers potassium. It was found by reading, and it is the worst class of defect
this project has produced, so it is worth asking mechanically.

The check. For every decision whose outcomes split into a MORE severe and a
LESS severe arm, compare what each arm actually contains:

  MISSING DRUG   a drug named on the milder arm and absent from the sicker one.
  THINNER ARM    the sicker arm carries strictly fewer interventions.

Severity is read from the outcome's own `severity:` field where it has one, and
otherwise from its label — "unstable", "severe", "major", "yes" against
"stable", "mild", "minor", "no". Both are the chart's own words, not a
judgement imposed on it.

Every hit is a question to read, never a verdict: a sicker arm legitimately
carries fewer items when it says "intubate and transfer" and the milder arm
lists six outpatient steps. Output is written and flushed per finding.
"""

import io
import os
import re
import sys

import yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crossbook_dose_extract as ex  # noqa: E402
from _repo import REPO

ROOT = str(REPO / 'assets/books')
OUT = str(REPO / 'tool/crossbook/severity_asymmetry.tsv')
BOOKS = ('protocolbook', 'who_imci', 'wvems')

RANK = {'emergency': 3, 'priority': 2, 'non_urgent': 0, 'none': 1}
# "yes" and "no" carry NO severity on their own and were removed on 2026-08-30.
# The decision text decides what they mean: on "Convulsion stops after 5 more
# minutes?" and "Has bleeding stopped?" the YES arm is the GOOD outcome, so
# scoring yes=severe inverted the comparison and reported the recovering child
# as the sicker one. Six of eighteen findings were that inversion.
SEVERE = re.compile(
    r'\b(unstable|severe|major|emergen|critical|shock|life[- ]threat|'
    r'decompensat|impending|arrest)\b', re.I)
MILD = re.compile(
    r'\b(stable|mild|minor|moderate|non[- ]?urgent|routine|well)\b', re.I)


def text_of(node):
    out = []

    def walk(x):
        if isinstance(x, str):
            out.append(x)
        elif isinstance(x, dict):
            for k, v in x.items():
                if k not in ('severity', 'kind', 'shape', 'side'):
                    walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(node)
    return ' \n '.join(out)


def interventions(node):
    """Count the things that are actually done, not the words."""
    t = text_of(node)
    n = 0
    for x in (node.get('bullets') if isinstance(node, dict) else None) or []:
        n += 1
    for x in (node.get('actions') if isinstance(node, dict) else None) or []:
        n += 1
    return max(n, len([l for l in t.split('\n') if l.strip()]))


def sev_rank(outcome):
    box = outcome.get('box') if isinstance(outcome, dict) else None
    s = (box or {}).get('severity') or outcome.get('severity')
    if s in RANK:
        return RANK[s], 'severity: %s' % s
    label = str(outcome.get('label', ''))
    if SEVERE.search(label) and not MILD.search(label):
        return 3, 'label "%s"' % label[:30]
    if MILD.search(label) and not SEVERE.search(label):
        return 1, 'label "%s"' % label[:30]
    return None, label[:30]


def drugs_in(node, patterns):
    t = text_of(node)
    found = set()
    for pat, canon in patterns:
        if pat.search(t):
            found.add(canon)
    return found


def main():
    vocab = ex.build_vocab()
    patterns = [(re.compile(r'(?<![\w-])' + re.escape(f) + r'(?![\w-])', re.I),
                 c)
                for f, c in sorted(((f, c) for c, fs in vocab.items()
                                    for f in fs), key=lambda x: -len(x[0]))]

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    fh = io.open(OUT, 'w', encoding='utf-8')
    fh.write('book\tfile\tdecision\tsicker\tmilder\tkind\tdetail\n')
    fh.flush()
    n_dec = n_hit = 0

    for book in BOOKS:
        d = os.path.join(ROOT, book, 'topics')
        if not os.path.isdir(d):
            continue
        for name in sorted(os.listdir(d)):
            if not name.endswith('.yaml'):
                continue
            with io.open(os.path.join(d, name), encoding='utf-8') as f:
                doc = yaml.safe_load(f)
            charts = []

            def walk(x):
                if isinstance(x, dict):
                    if x.get('type') == 'flowchart':
                        charts.append(x)
                    for v in x.values():
                        walk(v)
                elif isinstance(x, list):
                    for v in x:
                        walk(v)
            walk(doc)

            for ch in charts:
                groups = []
                for st in ch.get('stages') or []:
                    if isinstance(st, dict) and st.get('outcomes'):
                        groups.append((str(st.get('decision', ''))[:70],
                                       st['outcomes']))
                if ch.get('branches'):
                    groups.append(('(severity split)', ch['branches']))
                for label, outs in groups:
                    scored = []
                    for o in outs:
                        if not isinstance(o, dict):
                            continue
                        r, why = sev_rank(o)
                        if r is not None:
                            scored.append((r, why, o))
                    if len(scored) < 2:
                        continue
                    scored.sort(key=lambda t: -t[0])
                    hi, mid = scored[0], scored[-1]
                    if hi[0] <= mid[0]:
                        continue
                    n_dec += 1
                    hi_d = drugs_in(hi[2], patterns)
                    lo_d = drugs_in(mid[2], patterns)
                    only_mild = sorted(lo_d - hi_d)
                    if only_mild:
                        fh.write('%s\t%s\t%s\t%s\t%s\tMISSING DRUG\t%s\n'
                                 % (book, name, label, hi[1], mid[1],
                                    ', '.join(only_mild)))
                        fh.flush()
                        n_hit += 1
                        print('  %s %s | %s | sicker(%s) lacks: %s'
                              % (book, name, label, hi[1],
                                 ', '.join(only_mild)), flush=True)
                    a, b = interventions(hi[2]), interventions(mid[2])
                    if b > a + 1:
                        fh.write('%s\t%s\t%s\t%s\t%s\tTHINNER ARM\t'
                                 'sicker %d vs milder %d\n'
                                 % (book, name, label, hi[1], mid[1], a, b))
                        fh.flush()
                        n_hit += 1
                        print('  %s %s | %s | sicker arm %d items vs milder %d'
                              % (book, name, label, a, b), flush=True)
    fh.close()
    print('DONE: %d severity-ordered decisions compared, %d to read -> %s'
          % (n_dec, n_hit, OUT), flush=True)


if __name__ == '__main__':
    sys.exit(main())
