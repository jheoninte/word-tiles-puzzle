#!/usr/bin/env python3
import argparse
import json
import random
from collections import Counter
from copy import deepcopy
from pathlib import Path

WORD_THEMES = [
    {
        "theme": "자연과 휴식",
        "pool": ["STAR", "TREE", "EAR", "RAT", "SEA", "TEA", "EAT", "ART", "REST", "RATE", "TEAR"],
    },
    {
        "theme": "바다 여행",
        "pool": ["SAND", "SEA", "AREA", "DEEP", "SEED", "SEND", "READ", "NEAR", "RED", "APE"],
    },
    {
        "theme": "우주 탐험",
        "pool": ["MOON", "MARS", "NOVA", "RING", "SUN", "SON", "RAM", "ARM", "RAIN", "IRON"],
    },
    {
        "theme": "카페 메뉴",
        "pool": ["아이스", "아메리카노", "스무디", "카라멜", "아이", "카메라", "라디오", "마디", "무스"],
    },
]


class CrosswordBuilder:
    def __init__(self, max_size: int = 6) -> None:
        self.max_size = max_size
        self.grid = [[None for _ in range(max_size)] for _ in range(max_size)]
        self.placed_words = []

    def can_place_word(self, word: str, r: int, c: int, direction: str, require_intersection: bool = True) -> bool:
        length = len(word)
        if direction == "H":
            if r < 0 or r >= self.max_size or c < 0 or c + length > self.max_size:
                return False
            if c > 0 and self.grid[r][c - 1] is not None:
                return False
            if c + length < self.max_size and self.grid[r][c + length] is not None:
                return False
        else:
            if c < 0 or c >= self.max_size or r < 0 or r + length > self.max_size:
                return False
            if r > 0 and self.grid[r - 1][c] is not None:
                return False
            if r + length < self.max_size and self.grid[r + length][c] is not None:
                return False

        has_intersection = False
        for idx, char in enumerate(word):
            nr = r + idx if direction == "V" else r
            nc = c + idx if direction == "H" else c
            existing = self.grid[nr][nc]
            if existing is not None:
                if existing != char:
                    return False
                has_intersection = True
            else:
                if direction == "H":
                    if (nr > 0 and self.grid[nr - 1][nc] is not None) or (nr + 1 < self.max_size and self.grid[nr + 1][nc] is not None):
                        return False
                else:
                    if (nc > 0 and self.grid[nr][nc - 1] is not None) or (nc + 1 < self.max_size and self.grid[nr][nc + 1] is not None):
                        return False

        return has_intersection or not require_intersection

    def place_word(self, word: str, r: int, c: int, direction: str) -> None:
        for idx, char in enumerate(word):
            nr = r + idx if direction == "V" else r
            nc = c + idx if direction == "H" else c
            self.grid[nr][nc] = char
        self.placed_words.append({"word": word, "r": r, "c": c, "dir": direction})

    def build(self, candidates, target_word_count: int = 4) -> bool:
        words = [word for word in sorted(set(candidates), key=lambda item: (-len(item), random.random())) if 2 <= len(word) <= self.max_size]
        if len(words) < 3:
            return False
        self.place_word(words[0], 0, 0, "H")
        for word in words[1:]:
            if len(self.placed_words) >= target_word_count:
                break
            options = []
            for r in range(self.max_size):
                for c in range(self.max_size):
                    for direction in ("H", "V"):
                        if self.can_place_word(word, r, c, direction, require_intersection=True):
                            options.append((r, c, direction))
            if options:
                r, c, direction = random.choice(options)
                self.place_word(word, r, c, direction)
        return len(self.placed_words) >= 3

    def export_level(self, theme_name: str, pool) -> dict:
        max_row = 0
        max_col = 0
        cells = {}
        for placed in self.placed_words:
            word = placed["word"]
            for idx, char in enumerate(word):
                row = placed["r"] + idx if placed["dir"] == "V" else placed["r"]
                col = placed["c"] + idx if placed["dir"] == "H" else placed["c"]
                max_row = max(max_row, row)
                max_col = max(max_col, col)
                cells[(row, col)] = char

        tile_counts = Counter(cells.values())
        placed_words = {item["word"] for item in self.placed_words}
        bonus_words = []
        for candidate in pool:
            if candidate in placed_words or len(candidate) < 2:
                continue
            needed = Counter(candidate)
            if all(needed[ch] <= tile_counts.get(ch, 0) for ch in needed):
                bonus_words.append(candidate)

        return {
            "theme": theme_name,
            "rows": max(5, max_row + 1),
            "cols": max(5, max_col + 1),
            "difficulty": len(cells) * 2 + len(tile_counts) * 3 + len(self.placed_words) * 4,
            "words": deepcopy(self.placed_words),
            "bonusWords": sorted(set(bonus_words)),
        }


def generate_levels_batch(count: int):
    levels = []
    attempts = 0
    while len(levels) < count and attempts < count * 20:
        attempts += 1
        theme = WORD_THEMES[attempts % len(WORD_THEMES)]
        builder = CrosswordBuilder(max_size=6)
        pool = list(theme["pool"])
        random.shuffle(pool)
        if builder.build(pool, target_word_count=4):
            levels.append(builder.export_level(theme["theme"], pool))
    levels.sort(key=lambda item: item["difficulty"])
    return levels


def main() -> None:
    parser = argparse.ArgumentParser(description="Word Tiles crossword level generator")
    parser.add_argument("--count", type=int, default=10)
    parser.add_argument("--output", type=str, default="godot-project/data/levels.generated.json")
    args = parser.parse_args()

    levels = generate_levels_batch(args.count)
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(levels, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Generated {len(levels)} levels -> {output_path}")


if __name__ == "__main__":
    main()
