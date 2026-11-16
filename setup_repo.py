from pathlib import Path

ROOT = Path(__file__).resolve().parent


def main() -> None:
    required = [
        ROOT / "docs",
        ROOT / "web-prototype",
        ROOT / "tools",
        ROOT / "godot-project" / "autoload",
        ROOT / "godot-project" / "data",
        ROOT / "godot-project" / "scripts",
        ROOT / "godot-project" / "shaders",
    ]
    for path in required:
        path.mkdir(parents=True, exist_ok=True)
    print("Repository structure verified:")
    for path in required:
        print(f"- {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
