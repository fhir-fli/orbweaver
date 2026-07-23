#!/usr/bin/env bash
# Builds the WHO-only web app (Hospital Care for Children) — a single-book,
# no-shelf interactive rendering to show the WHO. Temporarily swaps the
# pubspec asset list to who_imci only, so nothing else is bundled, then
# restores it. Output: build/web.
#
# Usage: tool/build_who_web.sh [base-href]
#   base-href defaults to "/". For a subpath deploy use e.g. "/who/".
set -euo pipefail
cd "$(dirname "$0")/.."

BASE="${1:-/}"

cleanup() { [ -f pubspec.yaml.bak ] && mv pubspec.yaml.bak pubspec.yaml; }
trap cleanup EXIT

cp pubspec.yaml pubspec.yaml.bak

python3 - <<'PY'
import re
lines = open('pubspec.yaml').read().split('\n')
out, in_assets = [], False
for l in lines:
    if re.match(r'^\s+assets:\s*$', l):
        out.append(l)
        out.append('    - assets/books/who_imci/')
        out.append('    - assets/books/who_imci/topics/')
        in_assets = True
        continue
    if in_assets:
        # Drop the original asset entries; end the block at the first line
        # that isn't a "- ..." list item or a comment/blank.
        if re.match(r'^\s+- ', l) or l.strip().startswith('#') or not l.strip():
            continue
        in_assets = False
    out.append(l)
open('pubspec.yaml', 'w').write('\n'.join(out))
PY

# Clean the output so removed books don't linger from a previous full build.
rm -rf build/web

flutter build web -t lib/main_who.dart --no-tree-shake-icons --base-href "$BASE"

# Title the page (the generated index.html uses the project name).
sed -i 's#<title>[^<]*</title>#<title>Hospital Care for Children</title>#' \
  build/web/index.html || true
# Name the app in the manifest (shown in the tab / any bookmark). Runs as a
# plain website (display:browser) — no "install app" prompt.
sed -i 's#"name": *"[^"]*"#"name": "Hospital Care for Children"#; s#"short_name": *"[^"]*"#"short_name": "Hospital Care"#' \
  build/web/manifest.json || true

echo "WHO web build ready at build/web (base-href $BASE)."
echo "Books bundled:"
ls build/web/assets/assets/books
