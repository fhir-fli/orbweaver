# tool/ — the instruments, and what is not kept here

**Nothing in this directory ships.** The app bundle is `assets/` only, per
`pubspec.yaml`. This is the workshop.

## What is kept

**Every `.py` is an instrument and stays**, whether or not a test runs it. Two of
them are run by `test/data/`; the rest are re-run whenever a book changes.
Rebuilding one costs a session — a loop-detection probe was rebuilt from scratch
on 2026-09-01 for work that had finished three days earlier, and three separate
probe designs were measured before the record turned up saying the question was
closed.

**The adjudications stay**, in `crossbook/`:
`threshold_adjudication.md` · `duration_adjudication.md` ·
`intrabook_adjudication.md` · `intrabook_rules_adjudication.md` ·
`flowchart_shape_adjudication.md` · `loop_chart_disposition.md`.
Each records what was read, what was ruled, and **why something was dismissed**,
so a later pass does not re-derive a settled question. That is the one thing git
history does not give you cheaply: you cannot grep for a decision you do not know
was made.

**`protocolbook_source_errata.md` stays** — it is live work, the list of print
corrections for v1.8.

**`formulary_page_parity_baseline.tsv` stays** — a test asserts against it.

**The clinical question queues were removed on 2026-10-06** (Grey: committed,
done and unlikely to be needed again means delete; git history is the archive).
Every one was stamped NOTHING IS OPEN and its rulings were applied to the books.

| removed 2026-10-06 | what it was |
|---|---|
| `crossbook_findings.md` | cross-book dose comparison findings, all dismissed or applied |
| `protocolbook_needs_oe_rereview.md` | OE re-review tracker, rounds 1–2 |
| `protocolbook_advance_pass_114_142.md`, `who_imci_advance_pass.md` | advance passes, 32 + 13 flags, all applied |
| `protocolbook_content_flags.md`, `protocolbook_formulary_flags.md`, `protocolbook_open_dosing_questions.md` | flag and question files, all closed |
| `protocolbook_flattened_figures.md`, `protocolbook_number_parity_adjudication.md`, `who_imci_fidelity_findings.md` | first-pass fidelity reports, superseded by the applied books |
| `wvems_fit_measure_test.dart` | one-off fit measurement for the finished WVEMS pass |

## What is not kept

**Generated output is gitignored, not committed.** Every `.tsv` and every
side-by-side report is rebuilt by the script named in its own header. A committed
snapshot goes stale silently, and twice on 2026-08-30 that cost something real: a
stale `doses.tsv` made the formulary parity guard report a valid entry as
orphaned, and a stale hand-off list nearly sent superseded doses to a reviewer.
Run the script; do not read a checked-in copy.

**Finished design-audit records were removed** on 2026-09-01, once the WVEMS
design pass was applied and verified. They are in git if ever needed:

| removed | commit |
|---|---|
| `wvems_audit_typography.md`, `wvems_audit_colour.md`, `wvems_audit_badges.md` | `6c6891a` |
| `wvems_sidebyside_audit.md` | `281c712` |
| `wvems_dose_audit.md` | `0a159d4` |
| `wvems_design_application_plan.md`, `wvems_links_not_restorable.md` | `2bea4c8` |

## The one file that is not here

`OPENEVIDENCE.md` lives at the **repo root**. It is the only file anyone has to
find and paste, and it was buried under `tool/` until 2026-09-01.
