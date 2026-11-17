extends Node

signal coins_changed(new_coins: int, delta: int)
signal data_saved()
signal save_failed(error: int)

const SAVE_PATH := "user://word_tiles_save_v1.cfg"

var current_level_idx: int = 0
var coins: int = 100
var sound_enabled: bool = true
var music_enabled: bool = true
var effects_enabled: bool = true
var music_volume: float = 0.65
var effects_volume: float = 0.8
var saved_filled_coords: Array = []
var saved_bonus_words: Array[String] = []
var reward_claimed: bool = false
var reward_claimed_known: bool = false
var tutorial_completed: bool = false
var last_save_error: Error = OK
var last_load_error: Error = OK

func _ready() -> void:
	load_progress()

func add_coins(delta: int) -> void:
	coins = max(0, coins + delta)
	coins_changed.emit(coins, delta)
	save_progress()

func spend_coins(cost: int) -> bool:
	if cost < 0 or coins < cost:
		return false
	coins -= cost
	coins_changed.emit(coins, -cost)
	save_progress()
	return true

func set_level_progress(level_idx: int, filled_coords: Array, bonus_words: Array[String]) -> void:
	if current_level_idx != level_idx:
		reward_claimed = false
		reward_claimed_known = true
	current_level_idx = level_idx
	saved_filled_coords = filled_coords.duplicate(true)
	saved_bonus_words.assign(bonus_words)
	save_progress()

func commit_progress(level_idx: int, filled_coords: Array, bonus_words: Array[String], next_coins: int, next_sound: bool, next_reward_claimed: bool) -> Error:
	var previous_coins := coins
	current_level_idx = level_idx
	saved_filled_coords = filled_coords.duplicate(true)
	saved_bonus_words.assign(bonus_words)
	coins = maxi(0, next_coins)
	sound_enabled = next_sound
	reward_claimed = next_reward_claimed
	reward_claimed_known = true
	save_progress()
	if coins != previous_coins:
		coins_changed.emit(coins, coins - previous_coins)
	return last_save_error

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "level_idx", current_level_idx)
	config.set_value("progress", "coins", coins)
	config.set_value("progress", "sound_enabled", sound_enabled)
	config.set_value("progress", "music_enabled", music_enabled)
	config.set_value("progress", "effects_enabled", effects_enabled)
	config.set_value("progress", "music_volume", music_volume)
	config.set_value("progress", "effects_volume", effects_volume)
	config.set_value("progress", "filled_coords", saved_filled_coords)
	config.set_value("progress", "bonus_words", saved_bonus_words)
	config.set_value("progress", "tutorial_completed", tutorial_completed)
	if reward_claimed_known:
		config.set_value("progress", "reward_claimed", reward_claimed)
	var temporary_path := SAVE_PATH + ".tmp"
	last_save_error = config.save(temporary_path)
	if last_save_error == OK:
		last_save_error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary_path), ProjectSettings.globalize_path(SAVE_PATH))
	if last_save_error == OK:
		data_saved.emit()
	else:
		save_failed.emit(last_save_error)

func load_progress() -> void:
	current_level_idx = 0
	coins = 100
	sound_enabled = true
	music_enabled = true
	effects_enabled = true
	music_volume = 0.65
	effects_volume = 0.8
	saved_filled_coords.clear()
	saved_bonus_words.clear()
	reward_claimed = false
	reward_claimed_known = false
	tutorial_completed = false
	var config := ConfigFile.new()
	last_load_error = config.load(SAVE_PATH)
	if last_load_error != OK:
		return
	var stored_level: Variant = config.get_value("progress", "level_idx", 0)
	var stored_coins: Variant = config.get_value("progress", "coins", 100)
	var stored_sound: Variant = config.get_value("progress", "sound_enabled", true)
	if stored_level is int:
		current_level_idx = stored_level
	if stored_coins is int:
		coins = maxi(0, stored_coins)
	if stored_sound is bool:
		sound_enabled = stored_sound
	var stored_music: Variant = config.get_value("progress", "music_enabled", true)
	var stored_effects: Variant = config.get_value("progress", "effects_enabled", true)
	var stored_music_volume: Variant = config.get_value("progress", "music_volume", 0.65)
	var stored_effects_volume: Variant = config.get_value("progress", "effects_volume", 0.8)
	if stored_music is bool:
		music_enabled = stored_music
	if stored_effects is bool:
		effects_enabled = stored_effects
	if (stored_music_volume is float or stored_music_volume is int) and is_finite(float(stored_music_volume)):
		music_volume = clampf(float(stored_music_volume), 0.0, 1.0)
	if (stored_effects_volume is float or stored_effects_volume is int) and is_finite(float(stored_effects_volume)):
		effects_volume = clampf(float(stored_effects_volume), 0.0, 1.0)
	var stored_coords: Variant = config.get_value("progress", "filled_coords", [])
	if stored_coords is Array:
		for coord in stored_coords:
			if coord is Array and coord.size() == 2 and coord[0] is int and coord[1] is int:
				saved_filled_coords.append([coord[0], coord[1]])
	var stored_bonus: Variant = config.get_value("progress", "bonus_words", [])
	if stored_bonus is Array:
		for word in stored_bonus:
			if word is String and not saved_bonus_words.has(word):
				saved_bonus_words.append(word)
	if config.has_section_key("progress", "reward_claimed"):
		var stored_reward: Variant = config.get_value("progress", "reward_claimed", false)
		if stored_reward is bool:
			reward_claimed = stored_reward
			reward_claimed_known = true
	if config.has_section_key("progress", "tutorial_completed"):
		var stored_tutorial: Variant = config.get_value("progress", "tutorial_completed", false)
		if stored_tutorial is bool:
			tutorial_completed = stored_tutorial
