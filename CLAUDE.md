# CLAUDE.md - Word Tiles Project Guide for AI Coding Agents

## 1. Project Overview
- **Title**: Word Tiles - Relaxing Puzzle
- **Core Genre**: Crossword Tile-Allocation Word Puzzle (Mobile/Web)
- **Primary Targets**: HTML5 prototype first, Godot mobile port second

## 2. Core Rules
1. Players connect letter tiles to form words.
2. Tile counts must represent remaining unfilled board cells.
3. Intersections count once because the board state is cell-based.
4. Bonus words reward coins but do not consume board progress.

## 3. Important Invariants
1. **No double deduction at intersections**.
2. **Hints must fill cells, then trigger a tile-count recompute**.
3. **Saved progress is cell-based**, not merely word-complete based.
4. **Prototype and Godot logic should stay conceptually in sync**.

## 4. Useful Commands
- Run prototype: `python -m http.server 8080 --directory web-prototype`
- Generate levels: `python tools/level_generator.py --count 50 --output godot-project/data/levels.generated.json`
- Open Godot project: `godot --path godot-project`

## 5. Recommended Workflow
1. Validate mechanics in `web-prototype/index.html`.
2. Move stable data flow into `tools/level_generator.py` and JSON files.
3. Mirror stable mechanics in `godot-project/scripts/`.
