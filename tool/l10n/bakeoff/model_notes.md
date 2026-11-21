# Models in the translation test, and how each is run

Same prompt (prompt.md) and pages (pages.txt) for every model.

- **Claude Haiku 5.5** (`claude-haiku-5-5`), API, defaults (adaptive thinking,
  effort medium), streaming, max_tokens 32000. $0.10 / $0.50 per million tokens.
- **Gemma 4 E4B / E2B**, local via ollama, CPU only (the laptop's integrated
  graphics is not usable as a GPU). Google's QAT q4_0 GGUF. Sampling at the
  model card's recommendation, temperature 1.0, top_p 0.95, top_k 64
  (graiai/thalamus/harness/model_research/gemma-4-E4B-it.md, -E2B-it.md),
  thinking off (`think: false`), the GGUF's own chat template, num_ctx 16384.
- **Gemini**: not run yet; the Google keys in graiai .env files are refused by
  the Gemini API ("API key not valid", 2026-11-21).
- **RunPod**: not run yet; no RunPod key found.
- **Claude Opus 5.5** (this conversation): translated by hand into
  outputs/opus-5-5-conversation/.
