#!/usr/bin/env python3
"""Build an exact UTF-8 source snapshot for the Gemini content task."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = (
    "docs/GEMINI_LAUNCH_CONTENT_TASK.md", "AGENTS.md",
    "docs/LAUNCH_SCOPE.md", "docs/VISUAL_DIRECTION.md",
    "docs/AUDIO.md",
    "release/launch_config.json", "release/asset_manifest.json",
    "docs/DATA_SCHEMA.md", "docs/GAME_DESIGN_SPEC.md",
    "godot-project/scripts/MainGame.gd", "godot-project/autoload/GameManager.gd",
    "godot-project/scripts/LevelController.gd", "godot-project/scripts/SwipeRackController.gd",
    "godot-project/scripts/GameAudio.gd", "godot-project/scripts/TutorialController.gd",
    "godot-project/data/levels.json", "godot-project/data/dictionary.json",
    "tools/level_generator.py", "tools/validate_levels.py",
)


def main():
    snapshots = [(name, (ROOT / name).read_bytes()) for name in FILES]
    output = bytearray(b"Word Tiles v1: plain UTF-8 source handoff, not a ZIP.\n")
    output.extend(b"Only produce the art/copy/content staging files requested in the first document.\n")
    for name, data in snapshots:
        data.decode("utf-8")
        output.extend(f"\n===== FILE BEGIN: {name} =====\n".encode())
        output.extend(data)
        output.extend(f"\n===== FILE END: {name} =====\n".encode())
    destination = ROOT / "dist/gemini-launch-content-source.txt"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(output)
    saved = destination.read_bytes()
    for name, data in snapshots:
        extracted = saved.split(f"===== FILE BEGIN: {name} =====\n".encode(), 1)[1]
        extracted = extracted.split(f"\n===== FILE END: {name} =====".encode(), 1)[0]
        if extracted != data:
            raise RuntimeError(f"Source mismatch: {name}")
    manifest = {"bundle": destination.name, "files": [
        {"path": name, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
        for name, data in snapshots
    ]}
    destination.with_suffix(".manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Verified {len(snapshots)} complete files, {len(saved)} bytes -> {destination}")


if __name__ == "__main__":
    main()
