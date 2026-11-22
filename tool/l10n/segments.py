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
KEYS = set(re.findall(r"'([a-z_]+)'", _block.group(1)))
assert 'markdown' in KEYS and 'title' in KEYS, KEYS


def _yaml():
    y = YAML()
    y.preserve_quotes = True
    y.width = 4096
    return y


def _walk(node, key, visit):
    """Visit each translatable string. Mirrors compareTranslation: a list
    inherits its key, a map's children take their own."""
    if isinstance(node, dict):
        for k in list(node.keys()):
            v = node[k]
            if isinstance(v, str) and str(k) in KEYS:
                node[k] = visit(v)
            else:
                _walk(v, str(k), visit)
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


def reinsert(path, translated):
    """English page with each string replaced, as YAML text. Raises if an id
    is missing or extra."""
    doc = _yaml().load(open(path))
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
    return buf.getvalue()
