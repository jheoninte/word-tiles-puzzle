extends Node
class_name LevelController

var level_data: Dictionary = {}
var filled_coords: Dictionary = {}

func load_level(next_level: Dictionary, preload_filled: Array = []) -> void:
	level_data = next_level
	filled_coords.clear()
	for coord in preload_filled:
		if coord.size() >= 2:
			filled_coords["%s,%s" % [coord[0], coord[1]]] = true

func mark_word_solved(word: Dictionary) -> void:
	var word_text := String(word["word"])
	for idx in range(word_text.length()):
		var row := int(word["r"]) + (idx if String(word["dir"]) == "V" else 0)
		var col := int(word["c"]) + (idx if String(word["dir"]) == "H" else 0)
		filled_coords["%s,%s" % [row, col]] = true

func reveal_random_hint() -> Array:
	var remaining: Array = []
	for word in level_data.get("words", []):
		var word_text := String(word["word"])
		for idx in range(word_text.length()):
			var row := int(word["r"]) + (idx if String(word["dir"]) == "V" else 0)
			var col := int(word["c"]) + (idx if String(word["dir"]) == "H" else 0)
			var key := "%s,%s" % [row, col]
			if not filled_coords.has(key):
				remaining.append([row, col, word_text[idx]])
	if remaining.is_empty():
		return []
	var choice := remaining[randi() % remaining.size()]
	filled_coords["%s,%s" % [choice[0], choice[1]]] = true
	return choice

func recalculate_tile_counts() -> Dictionary:
	var counts := {}
	for word in level_data.get("words", []):
		var word_text := String(word["word"])
		for idx in range(word_text.length()):
			var row := int(word["r"]) + (idx if String(word["dir"]) == "V" else 0)
			var col := int(word["c"]) + (idx if String(word["dir"]) == "H" else 0)
			var key := "%s,%s" % [row, col]
			if filled_coords.has(key):
				continue
			var letter := word_text[idx]
			counts[letter] = int(counts.get(letter, 0)) + 1
	return counts
