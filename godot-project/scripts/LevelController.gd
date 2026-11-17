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

func _build_cell_map() -> Dictionary:
	var cell_map := {}
	for word in level_data.get("words", []):
		var word_text := String(word["word"])
		for idx in range(word_text.length()):
			var row := int(word["r"]) + (idx if String(word["dir"]) == "V" else 0)
			var col := int(word["c"]) + (idx if String(word["dir"]) == "H" else 0)
			cell_map["%s,%s" % [row, col]] = word_text[idx]
	return cell_map

func reveal_random_hint() -> Array:
	var remaining: Array = []
	var cell_map := _build_cell_map()
	for key in cell_map:
		if not filled_coords.has(key):
			var parts := String(key).split(",")
			remaining.append([int(parts[0]), int(parts[1]), cell_map[key]])
	if remaining.is_empty():
		return []
	var choice: Array = remaining[randi() % remaining.size()]
	filled_coords["%s,%s" % [choice[0], choice[1]]] = true
	return choice

func recalculate_tile_counts() -> Dictionary:
	var counts := {}
	var cell_map := _build_cell_map()
	for key in cell_map:
		if not filled_coords.has(key):
			var letter := String(cell_map[key])
			counts[letter] = int(counts.get(letter, 0)) + 1
	return counts

func _is_word_solved(word: Dictionary) -> bool:
	var word_text := String(word["word"])
	for index in range(word_text.length()):
		var row := int(word["r"]) + (index if String(word["dir"]) == "V" else 0)
		var col := int(word["c"]) + (index if String(word["dir"]) == "H" else 0)
		if not filled_coords.has("%s,%s" % [row, col]):
			return false
	return true

func _fits_remaining_tiles(text: String) -> bool:
	var counts := recalculate_tile_counts()
	for index in range(text.length()):
		var letter := text[index]
		var available := int(counts.get(letter, 0))
		if available <= 0:
			return false
		counts[letter] = available - 1
	return true

func can_select_text(text: String) -> bool:
	if _fits_remaining_tiles(text):
		return true
	for word in level_data.get("words", []):
		if not _is_word_solved(word) and String(word["word"]).begins_with(text):
			return true
	return false

func can_submit_bonus(text: String) -> bool:
	if text.length() < 2 or not level_data.get("bonusWords", []).has(text):
		return false
	for word in level_data.get("words", []):
		if String(word["word"]) == text:
			return false
	return _fits_remaining_tiles(text)
