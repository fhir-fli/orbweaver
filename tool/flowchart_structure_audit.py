#!/usr/bin/env python3
"""Audit every flowchart in every book for STRUCTURAL defects.

Not layout, not print fidelity — whether the flow can be followed. The two
worst errors this project has found were both structural: an SVT chart whose
stability branch was inverted, so unstable patients were sent to a drug instead
of electricity, and a hyperkalaemia algorithm whose sickest branch contained
nothing that lowers potassium. Both were found by reading. These are the
defects a machine can find on its own:

  DEAD END        a decision outcome says `continue: true` but nothing follows
                  it — the reader falls off the bottom of the chart.
  ONE-SIDED       a decision has a single outcome, so one answer is unhandled.
  EMPTY BRANCH    an outcome has neither a box, a continue, nor a goto.
  EMPTY BOX       a box has a title and nothing else, in a chart whose other
                  boxes carry content.
  DANGLING GOTO   a `goto:` or `loop_to:` naming an id that does not exist.
  UNREACHED ID    a node carries an id nothing targets — usually the remains of
                  a branch that was rewritten.

Every finding is a fact about the file, not a judgement, so this reports rather
than adjudicates. Output is written and flushed per chart.
"""

import io
import os
import sys

import yaml

ROOT = '/home/grey/dev/fhir/orbweaver/assets/books'
OUT = '/home/grey/dev/fhir/orbweaver/tool/crossbook/flowchart_structure.tsv'
BOOKS = ('protocolbook', 'who_imci', 'wvems')


def charts_in(doc):
    out = []

    def walk(x):
        if isinstance(x, dict):
            if x.get('type') == 'flowchart':
                out.append(x)
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(doc)
    return out


def ids_and_targets(chart):
    ids, targets = set(), []

    def walk(x):
        if isinstance(x, dict):
            if isinstance(x.get('id'), str):
                ids.add(x['id'])
            for key in ('goto', 'loop_to', 'loopback'):
                if isinstance(x.get(key), str):
                    targets.append((key, x[key]))
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(chart)
    return ids, targets


def audit(chart):
    problems = []
    ids, targets = ids_and_targets(chart)

    for key, t in targets:
        if t not in ids:
            problems.append('DANGLING %s -> "%s"' % (key, t))
    hit = {t for _, t in targets}
    for i in sorted(ids - hit):
        problems.append('UNREACHED id "%s"' % i)

    stages = chart.get('stages')
    if isinstance(stages, list):
        for n, st in enumerate(stages):
            if not isinstance(st, dict):
                continue
            outs = st.get('outcomes')
            label = str(st.get('decision', ''))[:60]
            if isinstance(outs, list):
                if len(outs) == 1:
                    problems.append('ONE-SIDED decision "%s"' % label)
                for o in outs:
                    if not isinstance(o, dict):
                        continue
                    if o.get('continue') and n == len(stages) - 1:
                        problems.append(
                            'DEAD END: "%s" / "%s" continues past the last '
                            'stage' % (label, o.get('label', '')))
                    if (not o.get('box') and not o.get('continue')
                            and not o.get('goto')):
                        problems.append(
                            'EMPTY BRANCH "%s" / "%s"'
                            % (label, o.get('label', '')))

    # An outcome box with a title and nothing else, where the chart's other
    # boxes do carry content.
    boxes = []

    def collect(x):
        if isinstance(x, dict):
            if 'title' in x and ('bullets' in x or 'severity' in x
                                 or 'table' in x or x.get('title')):
                if set(x) <= {'title', 'severity'}:
                    boxes.append((x.get('title'), False))
                elif 'bullets' in x or 'table' in x:
                    boxes.append((x.get('title'), True))
            for v in x.values():
                collect(v)
        elif isinstance(x, list):
            for v in x:
                collect(v)
    collect(chart)
    if any(full for _, full in boxes):
        for t, full in boxes:
            if not full:
                problems.append('BARE BOX "%s" (title only)' % str(t)[:50])
    return problems


def main():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    fh = io.open(OUT, 'w', encoding='utf-8')
    fh.write('book\tfile\tchart\tvariant\tproblem\n')
    fh.flush()
    n_charts = n_flag = 0
    for book in BOOKS:
        d = os.path.join(ROOT, book, 'topics')
        if not os.path.isdir(d):
            continue
        for name in sorted(os.listdir(d)):
            if not name.endswith('.yaml'):
                continue
            with io.open(os.path.join(d, name), encoding='utf-8') as f:
                doc = yaml.safe_load(f)
            for i, ch in enumerate(charts_in(doc)):
                n_charts += 1
                for p in audit(ch):
                    fh.write('%s\t%s\t%d\t%s\t%s\n'
                             % (book, name, i, ch.get('variant', ''), p))
                    fh.flush()
                    n_flag += 1
                    print('  %s %s [%d] %s' % (book, name, i, p), flush=True)
    fh.close()
    print('DONE: %d charts audited, %d structural problems -> %s'
          % (n_charts, n_flag, OUT), flush=True)


if __name__ == '__main__':
    sys.exit(main())
