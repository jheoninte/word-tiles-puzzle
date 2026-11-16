extends Node

signal coins_changed(new_coins: int, delta: int)
signal data_saved()

const SAVE_PATH := "user://word_tiles_save_v1.cfg"

var current_level_idx: int = 0
var coins: int = 100
var sound_enabled: bool = true
var saved_filled_coords: Array = []
var saved_bonus_words: Array[String] = []

func _ready() -> void:
	load_progress()

func add_coins(delta: int) -> void:
	coins = max(0, coins + delta)
	coins_changed.emit(coins, delta)
	save_progress()

func spend_coins(cost: int) -> bool:
	if coins < cost:
		return false
	coins -= cost
	coins_changed.emit(coins, -cost)
	save_progress()
	return true

func set_level_progress(level_idx: int, filled_coords: Array, bonus_words: Array[String]) -> void:
	current_level_idx = level_idx
	saved_filled_coords = filled_coords
	saved_bonus_words = bonus_words
	save_progress()

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "level_idx", current_level_idx)
	config.set_value("progress", "coins", coins)
	config.set_value("progress", "sound_enabled", sound_enabled)
	config.set_value("progress", "filled_coords", saved_filled_coords)
	config.set_value("progress", "bonus_words", saved_bonus_words)
	if config.save(SAVE_PATH) == OK:
		data_saved.emit()

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	current_level_idx = int(config.get_value("progress", "level_idx", 0))
	coins = int(config.get_value("progress", "coins", 100))
	sound_enabled = bool(config.get_value("progress", "sound_enabled", true))
	saved_filled_coords = config.get_value("progress", "filled_coords", [])
	saved_bonus_words = config.get_value("progress", "bonus_words", [])
