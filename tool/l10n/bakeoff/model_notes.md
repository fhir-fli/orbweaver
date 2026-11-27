# Models in the translation test, and how each is run

Same prompt (prompt.md) and pages (pages.txt) for every model.

- **Claude Haiku 5.5** (`claude-haiku-5-5`), API, defaults (adaptive thinking,
  effort medium), streaming, max_tokens 32000. $0.10 / $0.50 per million tokens.
- **Gemma 4 E2B / E4B / 12B**, local, CPU only (the laptop's integrated
  graphics is not usable as a GPU), through LiteRT-LM 0.19.0
  (`uv tool run --from litert-lm==0.19.0 litert-lm run`), on the same
  .litertlm files graiai uses (graiai/models/). Ollama 0.15.4 cannot load
  Gemma 4 ("unknown model architecture: 'gemma4'"). Sampling at the model
  card's recommendation, temperature 1.0, top_p 0.95, top_k 64
  (graiai/thalamus/harness/model_research/gemma-4-E4B-it.md, -E2B-it.md),
  thinking off, the model file's own chat template, 8192-token context.
- **Gemini 3.1 Flash-Lite** and **Gemma 4 31B**, Gemini API, defaults, with
  Grey's AI Studio key (~/.config/orbweaver-l10n/keys.env, not in a repo).
  Gemini 2.5 Flash / Flash-Lite answer 404 "no longer available to new users"
  (2026-11-21). Gemma 31B often answers 503 "high demand"; rerun skips done pages.
- **RunPod**: not run; no RunPod key found.
- **Claude Opus 5.5** (this conversation): translated by hand in this conversation:
  opus/<page>.json, inserted by insert_hand.py into outputs/opus-5-5-conversation/.
