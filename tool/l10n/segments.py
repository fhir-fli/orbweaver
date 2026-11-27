"""Pull the reader-visible text out of a page, and put a translation back.

A model never sees the YAML. It gets {"s1": "text", "s2": ...} and returns the
same ids with Spanish text; everything else (keys, ids, links, structure,
order) is copied from the English file by this code, so a model cannot
change it. Which keys are text comes from kTranslatableKeys in
tool/l10n/translation_check.dart, read at import so there is one list.
"""
import io
import os
import re

from ruamel.yaml import YAML
from ruamel.yaml.scalarstring import LiteralScalarString

HERE = os.path.dirname(os.path.abspath(__file__))
CHECK = os.path.join(HERE, 'translation_check.dart')
_block = re.search(r'kTranslatableKeys = <String>\{(.*?)\};', open(CHECK).read(), re.S)
KEYS = set(re.findall(r"'([a-z_.]+)'", _block.group(1)))
assert 'markdown' in KEYS and 'title' in KEYS, KEYS


def _yaml():
    y = YAML()
    y.preserve_quotes = True
    y.width = 4096
    return y


def _walk(node, key, visit):
    """Visit each translatable string. Mirrors compareTranslation: a list
    inherits its key, a map's children take their own, scoped to the map's
    `type:` when KEYS lists "<type>.<key>" (a drug card's class/indications)."""
    if isinstance(node, dict):
        for k in list(node.keys()):
            v = node[k]
            scoped = f"{node.get('type')}.{k}"
            kk = scoped if scoped in KEYS else str(k)
            if isinstance(v, str) and kk in KEYS:
                node[k] = visit(v)
            else:
                _walk(v, kk, visit)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            if isinstance(v, str) and key in KEYS:
                node[i] = visit(v)
            else:
                _walk(v, key, visit)


def extract(path):
    doc = _yaml().load(open(path))
    out = {}

    def visit(s):
        out[f's{len(out) + 1}'] = str(s)
        return s
    _walk(doc, None, visit)
    return out


def _strip_comments(node):
    """Drop every comment. ruamel re-emits a comment at its source column; a
    replaced literal block is re-emitted at ruamel's own indent, so a comment
    that followed it in the English can land inside the block and become
    reader-visible text (pb_054_meningitis, 2026-11-22). The translated file
    is generated, so it carries no maintainer comments."""
    ca = getattr(node, 'ca', None)
    if ca is not None:
        ca.items.clear()
        ca.comment = None
        ca.end = []
    if isinstance(node, dict):
        for v in node.values():
            _strip_comments(v)
    elif isinstance(node, list):
        for v in node:
            _strip_comments(v)


def reinsert(path, translated):
    """English page with each string replaced, as YAML text. Raises if an id
    is missing or extra, or if the emitted YAML does not read back as exactly
    the translated strings."""
    doc = _yaml().load(open(path))
    _strip_comments(doc)
    n = [0]

    def visit(s):
        n[0] += 1
        t = translated[f's{n[0]}']
        return LiteralScalarString(t) if '\n' in t else type(s)(t) if not isinstance(s, LiteralScalarString) else LiteralScalarString(t)
    _walk(doc, None, visit)
    if n[0] != len(translated):
        raise ValueError(f'{len(translated)} strings returned, page has {n[0]}')
    buf = io.StringIO()
    _yaml().dump(doc, buf)
    text = buf.getvalue()
    back = {}

    def read(s):
        back[f's{len(back) + 1}'] = str(s)
        return s
    _walk(_yaml().load(text), None, read)
    bad = [k for k in translated if back.get(k) != translated[k]]
    if bad or len(back) != len(translated):
        raise ValueError(f'{path}: emitted YAML reads back differently at {bad[:5]}')
    return text
