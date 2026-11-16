extends Button
class_name LetterTile

signal tile_selected(letter: String)

var letter: String = ""
var remaining: int = 0

func setup_tile(next_letter: String, count: int) -> void:
	letter = next_letter
	remaining = count
	text = "%s\n%d" % [letter, remaining]
	disabled = remaining <= 0

func set_remaining(count: int) -> void:
	remaining = count
	text = "%s\n%d" % [letter, remaining]
	disabled = remaining <= 0

func _pressed() -> void:
	if remaining > 0:
		tile_selected.emit(letter)
