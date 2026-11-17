# Word Tiles Agent Notes

- Keep the web prototype runnable as static files with no build step.
- Preserve the core invariant: tile counts must be recomputed from unfilled board cells, never decremented per submitted word length.
- Keep `web-prototype/` and `godot-project/` behavior aligned when adding mechanics.
- Prefer minimal, continuation-ready changes over speculative production systems.
- Target iOS release first, Android later; develop on Windows and finish native builds and device validation on Mac.
- Follow `docs/RELEASE_PLAN.md` for offline-first design, IAP/IAA scope, and release gates.
- For large implementations, prepare a self-contained Gemini prompt and current source handoff first; review, integrate, and verify the returned code here.
