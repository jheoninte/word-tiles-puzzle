extends Button
class_name LetterTile

signal tile_selected(letter: String)

var letter: String = ""
var remaining: int = 0
var is_reusable: bool = false

func setup_tile(next_letter: String, count: int) -> void:
	letter = next_letter
	set_remaining(count)

func set_remaining(count: int) -> void:
	remaining = maxi(0, count)
	set_selectable(remaining > 0)

func set_selectable(selectable: bool, reuse: bool = false) -> void:
	disabled = not selectable
	is_reusable = selectable and (reuse or remaining <= 0)
	text = "%s\n%d%s" % [letter, remaining, " ↻" if is_reusable else ""]
	tooltip_text = "채워진 글자를 정답에 다시 사용" if is_reusable else letter

func _pressed() -> void:
	if not disabled:
		tile_selected.emit(letter)
