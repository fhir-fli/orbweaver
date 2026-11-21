#!/usr/bin/env python3
"""One-time move of the calculator wording out of lib/data/formula_registry.dart
into assets/l10n/formulas.yaml, replacing each literal with a keyed lookup
`_t('<kind>.<slug>', {...})`. The math is untouched.

Kept for the record of how the keys were made; re-running on the converted
file finds nothing to move (it only touches quoted English in output fields).
"""
import re, sys, json

SRC = 'lib/data/formula_registry.dart'
OUT = 'assets/l10n/formulas.yaml'

src = open(SRC).read()
lines = src.split('\n')

# kind for each private function, from the dispatch switch.
fn2kind = {fn: kind for kind, fn in re.findall(r"'([a-z0-9_]+)' => (_[A-Za-z0-9]+)\(v\)", src)}

LIT = re.compile(r"""(?<![A-Za-z0-9_$])(['"])((?:\\.|(?!\1).)*)\1""")
# Lines whose literals are English wording shown to the reader.
CONTEXT = re.compile(r"^\s*(label:|interpretation:|interp = |cat = |\? |: |unit: '(criteria met|cells/µL|mL/day)'|'[A-Z<>≥≤=0-9]|\"[A-Z])")
SKIP = re.compile(r"_sel\(|_num\(|==|=> \(|case |value:")

def slug(text):
    t = re.sub(r"\$\{[^}]*\}|\$[A-Za-z_]+", "", text)
    words = re.findall(r"[A-Za-z]+", t.lower())
    return '_'.join(words[:5]) or 'text'

def argname(expr):
    m = re.match(r"fmtNum\(([A-Za-z_]+)", expr)
    if m: return m.group(1)
    m = re.match(r"([A-Za-z_]+)$", expr)
    if m: return m.group(1)
    raise SystemExit(f"cannot name arg {expr!r}")

strings = {}
cur = None
out_lines = []
for i, line in enumerate(lines):
    m = re.match(r"FormulaResult (_[A-Za-z0-9]+)\(Map", line)
    if m: cur = fn2kind.get(m.group(1))
    if cur is None or not CONTEXT.search(line) or SKIP.search(line) or line.strip().startswith('//'):
        out_lines.append(line); continue
    def repl(mm):
        text = mm.group(2)
        if not re.search(r"[A-Za-z]{2,}", text) and not re.search(r"[<>≤≥✓]", text):
            return mm.group(0)
        if mm.group(1) == "'":
            text = text.replace("\\'", "'")
        args = {}
        def sub_arg(a):
            expr = a.group(1) or a.group(2)
            n = argname(expr); args[n] = expr if a.group(1) else expr
            return '{' + n + '}'
        template = re.sub(r"\$\{([^}]*)\}|\$([A-Za-z_]+)", sub_arg, text)
        key = f"{cur}.{slug(template)}"
        base, n = key, 2
        while key in strings and strings[key] != template:
            key = f"{base}_{n}"; n += 1
        strings[key] = template
        if args:
            amap = ', '.join(f"'{k}': {('fmtNum(' + v[7:]) if v.startswith('fmtNum(') else v}" for k, v in args.items())
            return f"_t('{key}', {{{amap}}})"
        return f"_t('{key}')"
    out_lines.append(LIT.sub(repl, line))

open(SRC, 'w').write('\n'.join(out_lines))
with open(OUT, 'w') as f:
    f.write('# Calculator wording, English (the source). Keys are <kind>.<slug>;\n'
            '# {name} is filled in by lib/data/formula_registry.dart. Translations\n'
            '# live beside this file as <lang>/formulas.yaml with the same keys.\n')
    for k in sorted(strings):
        f.write(f"{k}: {json.dumps(strings[k], ensure_ascii=False)}\n")
print(len(strings), 'strings', file=sys.stderr)
