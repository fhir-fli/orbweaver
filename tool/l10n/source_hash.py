#!/usr/bin/env python3
"""Print the line a translation carries on line 1, for an English file:

    python3 tool/l10n/source_hash.py assets/books/wvems/topics/wvems_2026_001.yaml
    # translated-from-sha256: 3f1c...

Stamp a translation only after checking it against that exact English text;
test/l10n/translations_test.dart fails when the English changes later.
"""
import hashlib, sys

for path in sys.argv[1:]:
    with open(path, 'rb') as f:
        print(f"# translated-from-sha256: {hashlib.sha256(f.read()).hexdigest()}", flush=True)
