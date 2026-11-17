extends Node
class_name SwipeRackController

signal word_changed(current_word: String)
signal word_submitted(current_word: String)

var current_letters: Array[String] = []
@export var level_controller: LevelController

func set_level_controller(controller: LevelController) -> void:
	clear_selection()
	level_controller = controller

func clear_selection() -> void:
	current_letters.clear()
	word_changed.emit("")

func append_letter(letter: String) -> void:
	var next_word := "".join(current_letters) + letter
	if level_controller != null and not level_controller.can_select_text(next_word):
		return
	current_letters.append(letter)
	word_changed.emit("".join(current_letters))

func submit() -> void:
	var current_word := "".join(current_letters)
	if current_letters.size() >= 2 and (level_controller == null or level_controller.can_select_text(current_word)):
		word_submitted.emit("".join(current_letters))
	clear_selection()
