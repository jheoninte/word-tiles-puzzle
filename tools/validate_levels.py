#!/usr/bin/env python3
import argparse
import json
import sys
from collections import Counter, deque
from pathlib import Path


def print_err(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def positive_integer(value):
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("must be a positive integer")
    return parsed


def parse_args():
    parser = argparse.ArgumentParser(description="Validate Word Tiles level JSON.")
    parser.add_argument("file", help="Path to a JSON array of levels")
    parser.add_argument("--max-states", type=positive_integer, default=1000)
    parser.add_argument("--input-rule", choices=("crossing-reuse", "remaining-only"), default="crossing-reuse")
    return parser.parse_args()


def get_coords(word_item):
    return frozenset(
        (
            word_item["r"] + (index if word_item["dir"] == "V" else 0),
            word_item["c"] + (index if word_item["dir"] == "H" else 0),
        )
        for index in range(len(word_item["word"]))
    )


def validate_structure(level):
    errors, warnings = [], []
    cells, owners, valid_words = {}, {}, []
    if not isinstance(level, dict):
        return cells, valid_words, ["Level must be an object."], warnings

    rows, cols = level.get("rows"), level.get("cols")
    size_valid = all(type(value) is int and value > 0 for value in (rows, cols))
    if not size_valid:
        errors.append("rows and cols must be positive integers, excluding booleans.")

    words = level.get("words")
    if not isinstance(words, list) or not words:
        errors.append("words must be a non-empty array.")
        words = []
    seen_words = set()
    for index, item in enumerate(words):
        label = f"words[{index}]"
        if not isinstance(item, dict):
            errors.append(f"{label} must be an object.")
            continue
        text = item.get("word")
        if not isinstance(text, str) or not text.strip():
            errors.append(f"{label}.word must be a non-empty string.")
            continue
        if text in seen_words:
            errors.append(f"Duplicate target word: {text!r}.")
        seen_words.add(text)
        row, col, direction = item.get("r"), item.get("c"), item.get("dir")
        if not all(type(value) is int and value >= 0 for value in (row, col)):
            errors.append(f"{label} ({text!r}) requires non-negative integer coordinates.")
            continue
        if direction not in ("H", "V"):
            errors.append(f"{label} ({text!r}) requires direction H or V.")
            continue
        if not size_valid:
            continue
        valid_words.append(item)
        for offset, char in enumerate(text):
            coord = (row + (offset if direction == "V" else 0),
                     col + (offset if direction == "H" else 0))
            if coord[0] >= rows or coord[1] >= cols:
                errors.append(f"{text!r} exceeds board boundaries at {coord}.")
                continue
            if coord in cells and cells[coord] != char:
                errors.append(
                    f"Intersection collision at {coord}: {owners[coord]!r} "
                    f"({cells[coord]!r}) versus {text!r} ({char!r})."
                )
            else:
                cells[coord] = char
                owners[coord] = text

    bonuses = level.get("bonusWords")
    if not isinstance(bonuses, list):
        errors.append("bonusWords must be an array of non-empty strings.")
        bonuses = []
    seen_bonuses = set()
    available = Counter(cells.values())
    for index, bonus in enumerate(bonuses):
        if not isinstance(bonus, str) or not bonus.strip():
            errors.append(f"bonusWords[{index}] must be a non-empty string.")
            continue
        if bonus in seen_bonuses:
            warnings.append(f"Duplicate bonus word: {bonus!r}.")
            continue
        seen_bonuses.add(bonus)
        if bonus in seen_words:
            warnings.append(f"Bonus word {bonus!r} is also a target word.")
        if size_valid and not errors and Counter(bonus) - available:
            warnings.append(f"Bonus word {bonus!r} exceeds initial unique-cell letter counts.")
    return cells, valid_words, errors, warnings


def search_states(cells, words, max_states, input_rule="crossing-reuse"):
    targets = [(item["word"], get_coords(item), Counter(item["word"])) for item in words]
    start = frozenset()
    queue = deque([(start, ())])
    visited = {start}
    solution = None
    dead_ends = 0
    dead_end_example = None
    limited = False
    while queue:
        filled, path = queue.popleft()
        if len(filled) == len(cells):
            if solution is None:
                solution = path
            continue
        rack = Counter(char for coord, char in cells.items() if coord not in filled)
        has_transition = False
        for text, coords, required in targets:
            if coords.issubset(filled) or len(text) < 2:
                continue
            if input_rule == "remaining-only" and required - rack:
                continue
            has_transition = True
            next_filled = filled | coords
            if next_filled in visited:
                continue
            if len(visited) >= max_states:
                limited = True
                continue
            visited.add(next_filled)
            queue.append((next_filled, path + (text,)))
        if not has_transition:
            dead_ends += 1
            if dead_end_example is None:
                dead_end_example = path
    return solution, dead_ends, dead_end_example, limited, len(visited)


def validate_level(level, level_idx, max_states=1000, input_rule="crossing-reuse"):
    cells, words, errors, warnings = validate_structure(level)
    limited = False
    if not errors:
        solution, dead_ends, example, limited, state_count = search_states(cells, words, max_states, input_rule)
        print(f"[Level {level_idx}] Unique cells: {len(cells)}; explored states: {state_count}.")
        if solution is not None:
            print(f"[Level {level_idx}] Completion order: {' -> '.join(solution)}.")
        elif not limited:
            errors.append(f"No hint-free completion order under {input_rule} input limits.")
        if dead_ends:
            sequence = " -> ".join(example) or "initial state"
            warnings.append(f"Reachable dead-end states: {dead_ends}; example: {sequence}.")
        if limited:
            print_err(f"[Level {level_idx}] Undetermined: reached the {max_states}-state limit; analysis is incomplete.")
    else:
        print(f"[Level {level_idx}] Search skipped because structural validation failed.")
    for message in errors:
        print_err(f"[Level {level_idx}] Error: {message}")
    for message in warnings:
        print_err(f"[Level {level_idx}] Warning: {message}")
    return len(errors), len(warnings), limited


def main():
    args = parse_args()
    try:
        data = json.loads(Path(args.file).read_text(encoding="utf-8-sig"))
    except (OSError, ValueError, RecursionError) as error:
        print_err(f"Failed to read level JSON: {error}")
        return 2
    if not isinstance(data, list) or not data:
        print_err("Root JSON must be a non-empty array of levels.")
        return 1

    total_errors, total_warnings, any_limited = 0, 0, False
    for index, level in enumerate(data, start=1):
        errors, warnings, limited = validate_level(level, index, args.max_states, args.input_rule)
        total_errors += errors
        total_warnings += warnings
        any_limited = any_limited or limited
    print(f"Validation complete. Errors: {total_errors}, Warnings: {total_warnings}, Incomplete: {any_limited}.")
    return 2 if any_limited else 1 if total_errors else 0


if __name__ == "__main__":
    sys.exit(main())
