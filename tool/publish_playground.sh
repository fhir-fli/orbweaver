#!/usr/bin/env bash
# Builds the topic playground (lib/main_playground.dart) as a Flutter web app
# and copies it, plus the JSON Schemas, into the documentation site:
#
#   fhir_fli_documentation/jaspr/web/orbweaver_demo/      the playground (iframe)
#   fhir_fli_documentation/jaspr/web/orbweaver/schema/    topic/book/formulary/index schemas
#
# The docs site serves jaspr/web/ statically, so the schemas land at the
# `$id` URLs written inside them. Commit and push the docs repo to deploy.
#
# Usage: tool/publish_playground.sh [path-to-fhir_fli_documentation]
set -euo pipefail
cd "$(dirname "$0")/.."

DOCS="${1:-../fhir_fli_documentation}"
BASE="/fhir_fli_documentation/orbweaver_demo/"
[ -d "$DOCS/jaspr/web" ] || { echo "no docs site at $DOCS" >&2; exit 1; }

rm -rf build/web
flutter build web -t lib/main_playground.dart --release --no-tree-shake-icons --base-href "$BASE"
sed -i 's#<title>[^<]*</title>#<title>Orbweaver Playground</title>#' build/web/index.html
sed -i 's#"name": *"[^"]*"#"name": "Orbweaver Playground"#; s#"short_name": *"[^"]*"#"short_name": "Orbweaver"#' build/web/manifest.json

rm -rf "$DOCS/jaspr/web/orbweaver_demo"
cp -r build/web "$DOCS/jaspr/web/orbweaver_demo"
mkdir -p "$DOCS/jaspr/web/orbweaver/schema"
cp schema/*.schema.json "$DOCS/jaspr/web/orbweaver/schema/"

echo "playground -> $DOCS/jaspr/web/orbweaver_demo ($(du -sh "$DOCS/jaspr/web/orbweaver_demo" | cut -f1))"
echo "schemas    -> $DOCS/jaspr/web/orbweaver/schema"
ls "$DOCS/jaspr/web/orbweaver/schema"
