extends Node
class_name SwipeRackController

signal word_changed(current_word: String)
signal word_submitted(current_word: String)

var current_letters: Array[String] = []

func clear_selection() -> void:
	current_letters.clear()
	word_changed.emit("")

func append_letter(letter: String) -> void:
	current_letters.append(letter)
	word_changed.emit("".join(current_letters))

func submit() -> void:
	if current_letters.size() >= 2:
		word_submitted.emit("".join(current_letters))
	clear_selection()
