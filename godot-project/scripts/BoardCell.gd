extends PanelContainer
class_name BoardCell

signal cell_clicked(r: int, c: int)

@onready var char_label: Label = $CharLabel

var grid_r: int = 0
var grid_c: int = 0
var target_char: String = ""
var is_filled: bool = false
var style_box := StyleBoxFlat.new()

func _ready() -> void:
	custom_minimum_size = Vector2(46, 46)
	style_box.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", style_box)
	_apply_visual_state()

func setup_cell(r: int, c: int, ch: String, filled: bool) -> void:
	grid_r = r
	grid_c = c
	target_char = ch
	is_filled = filled
	_apply_visual_state()

func set_filled_with_pop(ch: String) -> void:
	target_char = ch
	is_filled = true
	_apply_visual_state()
	scale = Vector2(0.8, 0.8)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)

func _apply_visual_state() -> void:
	if not is_instance_valid(char_label):
		return
	if target_char == "":
		style_box.bg_color = Color(0, 0, 0, 0)
		char_label.text = ""
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	mouse_filter = Control.MOUSE_FILTER_STOP
	if is_filled:
		style_box.bg_color = Color("#4a7c59")
		char_label.text = target_char
		char_label.modulate = Color.WHITE
	else:
		style_box.bg_color = Color.WHITE
		char_label.text = ""

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and target_char != "":
		cell_clicked.emit(grid_r, grid_c)
