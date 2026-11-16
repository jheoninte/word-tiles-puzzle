# Word Tiles Agent Notes

- Keep the web prototype runnable as static files with no build step.
- Preserve the core invariant: tile counts must be recomputed from unfilled board cells, never decremented per submitted word length.
- Keep `web-prototype/` and `godot-project/` behavior aligned when adding mechanics.
- Prefer minimal, continuation-ready changes over speculative production systems.
