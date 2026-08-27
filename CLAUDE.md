# Orbweaver — Claude Instructions

# 🔴🔴🔴 RULE 0 — SAFETY AND CORRECTNESS ALWAYS TRUMP FAST. NEVER NARROW SCOPE TO SAVE EFFORT. 🔴🔴🔴

## **Grey is a physician. These artefacts are clinical references that people treat patients from. A page skipped is a page someone reads at 3 a.m. in Gulu.**

**NEVER offer a sample, subset, spot-check, "highest-yield few", or "start with a couple"
because it is cheaper, faster, less work, "low yield", "tractable", "manageable" or
"efficient.** Default to the **COMPLETE pass — every topic, every page, every item.**

- **Sampling is legitimate ONLY when the sample answers the question.** "Does the generator
  transcribe faithfully?" is answerable by 10 hand-checked cases. "Is anything wrong
  anywhere in 258 topics?" is not.
- **Effort may be stated as a neutral fact** ("this is 258 topics, it will take several
  passes") — **NEVER as a justification for doing less.**
- If the full scope genuinely is wrong, the reason must be **evidence**, never effort.
- **Do not present a menu with a cheaper option in it.**

**Before proposing any plan, ask: "Am I proposing this because it is right, or because it
is less work?"** If less work → propose the complete version instead.

**2026-08-27 — Grey, furious.** Having just finished a full page-by-page pass of one book,
I offered a "spot-check" of "two or three high-risk chapters" of the next and called the
rest "low yield". He asked *"why not all of them?"* — there was no reason except that it
was less work. His words: *"WHY IN THE GODDAMN FUCK DO YOU ALWAYS CHOOSE CHEAPER, SIMPLER,
EASIER, FASTER? I WANT THIS DONE GODDAMN FUCKING RIGHT. I'M NOT A TECH COMPANY, I'M NOT AN
AI COMPANY, I'M A FUCKING GODDAMN MOTHERFUCKING DOCTOR TAKING CARE OF HUMAN BEINGS, SO
SAFETY AND CORRECTNESS ALWAYS TRUMPS FAST."*

**The evidence that the full pass is right is already in hand:** the complete
page-by-page pass of the ProtocolBook produced **32 flags, every one endorsed by
OpenEvidence, 14 of them patient-safety** — including an SVT chart that sent unstable
patients to adenosine instead of cardioversion, and a hyperkalaemia algorithm that gave
the sickest patients nothing that lowers potassium. **A sample would have missed most of
them.**

🔒 Hook-enforced: `~/.claude/hooks/warn-scope-shrink.py`.

---


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
