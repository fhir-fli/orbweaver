# Orbweaver — Claude Instructions

> **Universal rules are in `~/.claude/CLAUDE.md`** — it loads in every session, in
> every directory, so they are not repeated here. Full records: `~/.claude/rule-records/`.
> This file holds project facts only.

Orbweaver is a Flutter app that renders clinical quick-reference "topics"
authored in YAML.  Topics are stacks of typed blocks
(prose / table / flowchart / drug_card / image / row / column / arrows /
merge_arrows) rendered by a custom Flutter renderer.  It is **not** a
general markdown viewer — the renderer implements a deliberately minimal
subset of markdown via `lib/widgets/mini_markdown.dart`.

## Markdown emphasis — asterisks

The `MiniMarkdown` widget handles a **small** subset of markdown.  Don't
assume standard markdown semantics.

- `**bold**` → renders as bold.  This works everywhere MiniMarkdown is
  used (prose blocks, table cells, etc.).
- `*italic*` with single asterisks → **does not render** as italic by
  default.  The single-asterisk pair is consumed as literal text (the
  stars appear on screen).
- `_italic_` is not supported either.

If you need italic emphasis, either:
1. Skip the italic and use bold, OR use a different phrasing that
   doesn't need italic; OR
2. Extend `MiniMarkdown._parseBold` to also parse single-asterisk
   italics (using `RichText` with `FontStyle.italic`) — add it as a
   second pass after bold parsing, and make sure the regex doesn't
   greedily consume parts of `**bold**` runs.

The same caveat applies to any other markdown you might be tempted to
write — links, headings (other than block-level `title:`), inline
code, blockquotes, nested lists beyond one level.  None of these
render.  Before authoring content that uses any markdown feature, open
`mini_markdown.dart` and confirm the syntax is supported.

## Authoring cadence

Walkthrough of the ProtocolBook (Grey's own pocket reference,
`ProtocolBook eBook 1.7.pdf`, 176 pages) proceeds page by page.  Commit
after each page is approved on the emulator.  Naming: `pb_*.yaml` for
ProtocolBook topics, `wvems_*` for WVEMS, `who_*` for WHO IMCI.  Always
register new topics in `lib/data/library.dart` under the correct book.

## Emulator

Pixel 6 API 36 AVD, launched with `emulator -avd Fresh_API_36`.  After
boot, run `adb shell wm size 1080x2220 && adb shell wm density 440`
to simulate Pixel 3a dimensions (~393×852 logical) — a closer proxy
to a typical phone and the user's device than the default Pixel 6
viewport.  Run with `flutter run -d emulator-5554`.
