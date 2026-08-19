# WVEMS cross-references: what the app carries, and what it does not

Regenerated 2026-08-19 from `2026-WVEMS-Protocols.pdf` by re-running the link
tools end to end. **The previous version of this file was stale** — it had been
written from a `wvems_link_apply.py` report taken *before* the content pass
restored nine rewritten pages, so its 26 remaining rows described sentences the
app had since gained. Nothing in it was trustworthy.

Regenerate with (a venv holding pymupdf + pyyaml):

```bash
python tool/wvems_link_extract.py            <scratch>/links.tsv
python tool/wvems_link_resolve.py            <scratch>/links.tsv   <scratch>/targets.tsv
python tool/wvems_link_apply.py              <scratch>/targets.tsv <scratch>/odd.tsv       --odd
python tool/wvems_link_apply.py              <scratch>/targets.tsv <scratch>/appendix.tsv  --appendix
python tool/wvems_flowchart_link_sites.py    <scratch>/targets.tsv <scratch>/sites.tsv
python tool/wvems_flowchart_link_apply.py    <scratch>/sites.tsv   <scratch>/flow.tsv
```

Add `--apply` to the two appliers to write. Odd pages are the prose pages, even
pages are the flowcharts, and pp.96+ are the three appendix topics; each printed
page belongs to exactly one of the three runs.

## The accounting

| | |
|---|---:|
| link annotations in the PDF | 1,492 |
| — placed outside the page box, invisible to a reader | 99 |
| **printed cross-references** (wrapped lines merged) | **1,363** |
| — external URLs (Medscape, handtevy.com, …) | 182 |
| **cross-references inside the book** | **1,181** |
| — carried by the app, confirmed by the appliers | 865 |
| — leaving a page the app ships no topic for | 221 |
| — index links with no card anchor (a "Page 119" pointer) | 39 |
| — **rows the appliers cannot place or confirm** | **56** |

The 221 all leave pages that exist only as navigation in print: p.1's contents
grid (96), and the section index pages the app replaced with its own lists —
p.96 (2), p.109 (8), p.118 (50) and p.144 (65). The 39 are those same index
pages' internal pointers ("Page 119", "Page 102"), which resolve to the
appendix topic but to no card inside it.

## The 56 — every one read against the print this session

**49 are present in the app.** The applier reports them because it pairs a
printed *line* with an app line and these do not pair: the app merges two
printed lines into one, spells out what the print abbreviates, or holds the
link in a form the tool does not read back.

| how many | why the tool can't confirm it | evidence |
|---:|---|---|
| 28 | one print link, two app occurrences (or the reverse) on a convergence bullet | every occurrence checked: linked inline or by `link_id` |
| 8 | the app merged two printed lines into one, so the line similarity stays under 0.55 | pp.97, 101, 104 (×4), 112 (×2) — **placed by hand this session** |
| 7 | `critical_care_link.text` is not in the applier's `LINKABLE` set | 5 already inline, 2 by `link_id`; the pill renders through `FlowLinkText`, so inline works |
| 4 | the phrase is linked under different words | p.91 `O₂ & NIPPV`, p.105 `Pain`, p.113 same-topic `(#destination-triage)`, p.128 `Brady` → `Bradycardia` |
| 1 | the print abbreviates: `Head Inj.` vs the app's `Head Injury` | p.44 — **placed by hand this session** |
| 1 | `wvems_2026_003.yaml` has no page block the applier recognises | p.3 `Peds Reference` is linked at line 88 |

**1 cannot be restored without a renderer change.** p.81's `Vent` →
`wvems-2026-096#ventilator` is underlined inside the section heading *Typical
Adult Vent Settings*. `ProseBlockView` draws a block title as a plain `Text`,
so a link written there would print its brackets. Restoring it means either
teaching prose titles the link syntax or moving the heading into the body.

**6 are target disagreements — the print points one way, the app another.**
These are judgement calls, not defects, and they are Grey's:

| page | phrase | print points at | app points at |
|---|---|---|---|
| 9 | STEMI | `wvems-2026-028` Chest Pain | `wvems-2026-088` STEMI |
| 43, 65 | Dyspnea | `wvems-2026-006` Breathing | `wvems-2026-030` Dyspnea |
| 135, 136 | Malignant HTN | `wvems-2026-092` Preeclampsia | `wvems-2026-010` Hypertension |
| 136 | OD/Tox | `wvems-2026-096#administer-antidote` | `wvems-2026-040` Overdose / Tox |

In all six the app's target is the protocol *of that name* and the print's is
the protocol that *discusses it*. The print is internally consistent; so is the
app. Nothing is broken either way.

## What this pass changed

Twenty links were placed — nine by the tools once they were fixed, eleven by
hand across seven lines (p.104 alone carries four) — and four tool defects were
fixed:

- **`wvems_link_resolve.py` still called p.104's card "Adult Antidotes"**, the
  name it lost in `2d94587`. Twenty-two links resolved to the dead anchor
  `#adult-antidotes`. The procedure branch now validates its anchor against the
  app's own card slugs, exactly as the drug branch already did.
- **`wvems_flowchart_link_apply.py` was not idempotent.** It picks the field a
  link belongs to by comparing the printed line against the YAML record — but
  compared against the *raw* record, so once a dose-table row was linked, the
  target inside it dragged the similarity down and the bare flow node won
  instead. Re-running it would have added **54 duplicate links**, a second
  pointer to the same page on lines that already had one. It now compares
  against the display text.
- **`wvems_link_apply.py` paired occurrences purely left to right**, so on a
  line like `For **chemical burns** … refer to [Burns](topic:…)` it took the
  prose word out of its bold run and left the line linking p.70 twice. An
  occurrence already linked to the target is now claimed first.
- **A phrase splitting on whitespace alone** never matched across the print's
  closed-up `OD/Tox` where the app writes `OD / Tox`. All three scripts now
  split on slashes too, which found p.36's Overdose / Tox card title.

And one content defect the print exposed: **p.82's convergence bullet said
`Allergy` but navigated to Overdose / Tox** — the print's `• Allergy, OD/Tox`
had been collapsed to the one word with the other's target hung on it as a
whole-bullet `link_id`. It is now two links, as the print sets it.

## The state

Every printed cross-reference that the app has a place for is in the app.
607 tests pass; the four `formula_block` / `table_features` failures are the
ones measured as pre-existing at `334d5f1`.
