#!/usr/bin/env python3
"""Re-run the structure/safety checker on every output (after the checker
changes) and write checks.tsv: label, page, problems. One row per file,
written and flushed as each finishes. Run from tool/l10n/bakeoff/."""
import glob, os, re, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
PAGES = {os.path.basename(l.strip()): l.strip() for l in open(os.path.join(HERE, 'pages.txt')) if l.strip()}

with open(os.path.join(HERE, 'checks.tsv'), 'w') as out:
    out.write('label\tpage\tproblems\n')
    for path in sorted(glob.glob(os.path.join(HERE, 'outputs', '*', '*.yaml'))):
        label = os.path.basename(os.path.dirname(path))
        page = PAGES[os.path.basename(path)]
        r = subprocess.run(['dart', 'run', 'tool/l10n/check_pair.dart', page, path],
                           cwd=REPO, capture_output=True, text=True)
        open(path + '.check.txt', 'w').write(r.stdout + r.stderr)
        m = re.search(r'problems: (\d+)', r.stdout)
        n = m.group(1) if m else 'unparsable'
        out.write(f'{label}\t{os.path.basename(path)}\t{n}\n'); out.flush()
        print(label, os.path.basename(path), n, flush=True)
