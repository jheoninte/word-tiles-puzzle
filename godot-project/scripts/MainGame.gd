extends Control

const CELL_SCENE: PackedScene = preload("res://scenes/BoardCell.tscn")
const TILE_SCENE: PackedScene = preload("res://scenes/LetterTile.tscn")
const NO_POINTER := -2

@export var show_debug_answers: bool = false

@onready var level_controller: LevelController = $LevelController
@onready var swipe_controller: SwipeRackController = $SwipeRackController
@onready var game_audio: GameAudio = $GameAudio
@onready var tutorial_controller: TutorialController = $TutorialController
@onready var safe_margin: MarginContainer = $SafeMargin
@onready var scroll: ScrollContainer = $SafeMargin/Scroll
@onready var content: VBoxContainer = $SafeMargin/Scroll/Content

var levels_data: Array = []
var current_level_idx: int = 0
var coins: int = 100
var sound_enabled: bool = true
var reward_claimed: bool = false
var found_bonus_words: Array[String] = []
var cells: Dictionary = {}
var tiles: Array[LetterTile] = []
var level_label: Label
var theme_label: Label
var coin_label: Label
var status_label: Label
var target_label: Label
var bonus_label: Label
var current_word_button: Button
var sound_button: Button
var help_button: Button
var tutorial_card: PanelContainer
var tutorial_title_label: Label
var tutorial_body_label: Label
var tutorial_action_button: Button
var tutorial_skip_button: Button
var tutorial_tween: Tween
var settings_panel: VBoxContainer
var master_sound_button: Button
var music_button: Button
var effects_button: Button
var music_slider: HSlider
var effects_slider: HSlider
var settings_save_timer: Timer
var next_button: Button
var board_grid: GridContainer
var rack_grid: GridContainer
var playable: bool = false
var active_pointer: int = NO_POINTER
var pointer_start: Vector2
var drag_moved: bool = false
var left_rack: bool = false
var last_tile: LetterTile

func _ready() -> void:
	_build_ui()
	if not _load_levels():
		status_label.text = "레벨 데이터를 읽을 수 없습니다."
		return
	swipe_controller.word_changed.connect(_on_word_changed)
	swipe_controller.word_submitted.connect(_on_word_submitted)
	swipe_controller.set_level_controller(level_controller)
	tutorial_controller.step_changed.connect(_on_tutorial_step_changed)
	tutorial_controller.tutorial_finished.connect(_on_tutorial_finished)
	_restore_progress()
	_apply_audio_settings()
	playable = true
	_build_level()
	var has_progress := current_level_idx > 0 or not level_controller.filled_coords.is_empty() or not found_bonus_words.is_empty()
	tutorial_controller.setup(GameManager.tutorial_completed, has_progress)
	if _is_board_completed():
		status_label.text = _completion_message()
	elif GameManager.last_load_error not in [OK, ERR_FILE_NOT_FOUND]:
		status_label.text = "저장 데이터를 읽지 못해 기본 상태로 시작했습니다."
	get_viewport().size_changed.connect(_refresh_layout)
	content.resized.connect(_resize_grids)
	call_deferred("_refresh_layout")

func _make_label(parent: Node, value: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _make_button(parent: Node, value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func _build_ui() -> void:
	var game_theme := Theme.new()
	game_theme.default_font_size = 16
	game_theme.set_color("font_color", "Label", Color("#293241"))
	game_theme.set_color("font_color", "Button", Color("#293241"))
	game_theme.set_color("font_hover_color", "Button", Color("#293241"))
	game_theme.set_color("font_pressed_color", "Button", Color("#293241"))
	game_theme.set_color("font_disabled_color", "Button", Color("#92958f"))
	var button_colors := {"normal": "#fffaf1", "hover": "#fff1d8", "pressed": "#f5d9a5", "disabled": "#e6e1d8"}
	for state in button_colors:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(button_colors[state])
		style.set_corner_radius_all(10)
		style.content_margin_left = 10.0
		style.content_margin_right = 10.0
		style.content_margin_top = 6.0
		style.content_margin_bottom = 6.0
		game_theme.set_stylebox(state, "Button", style)
	theme = game_theme
	var header := HBoxContainer.new()
	content.add_child(header)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info)
	level_label = _make_label(info, "WORD TILES", 22)
	theme_label = _make_label(info, "", 14)
	coin_label = _make_label(header, "코인 100")
	coin_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	coin_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	sound_button = _make_button(header, "소리 켬", _toggle_sound)
	sound_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	sound_button.tooltip_text = "게임 효과음 켜기/끄기"
	_build_tutorial_card()
	var board_center := CenterContainer.new()
	content.add_child(board_center)
	board_grid = GridContainer.new()
	board_grid.add_theme_constant_override("h_separation", 6)
	board_grid.add_theme_constant_override("v_separation", 6)
	board_center.add_child(board_grid)
	current_word_button = _make_button(content, "·", _submit_selection)
	current_word_button.add_theme_font_size_override("font_size", 26)
	status_label = _make_label(content, "타일을 이어 단어를 만드세요.", 14)
	var rack_center := CenterContainer.new()
	content.add_child(rack_center)
	rack_grid = GridContainer.new()
	rack_grid.columns = 3
	rack_grid.add_theme_constant_override("h_separation", 8)
	rack_grid.add_theme_constant_override("v_separation", 8)
	rack_center.add_child(rack_grid)
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	content.add_child(actions)
	_make_button(actions, "지우기", _cancel_selection)
	_make_button(actions, "제출", _submit_selection)
	_make_button(actions, "힌트 -30 코인", _give_hint)
	next_button = _make_button(actions, "다음 레벨", _next_level)
	next_button.disabled = true
	help_button = _make_button(content, "도움말", _on_help_pressed)
	_make_button(content, "설정", _on_settings_pressed)
	_build_settings()
	target_label = _make_label(content, "정답 단어")
	bonus_label = _make_label(content, "찾은 보너스: 없음", 14)
	_make_label(content, "글자를 누른 뒤 제출하거나 스와이프하세요. 같은 글자는 랙 밖으로 나갔다 돌아와 다시 선택합니다. ↻는 채워진 글자 재사용입니다.", 13)

func _build_settings() -> void:
	settings_panel = VBoxContainer.new()
	settings_panel.visible = false
	settings_panel.add_theme_constant_override("separation", 8)
	content.add_child(settings_panel)
	master_sound_button = _make_button(settings_panel, "전체 소리 켬", _toggle_sound)
	music_button = _make_button(settings_panel, "음악 켬", _toggle_music)
	_make_label(settings_panel, "배경 음악 음량", 14)
	music_slider = HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	music_slider.custom_minimum_size.y = 44
	music_slider.tooltip_text = "배경 음악 음량"
	music_slider.value_changed.connect(_on_music_volume_changed)
	settings_panel.add_child(music_slider)
	effects_button = _make_button(settings_panel, "효과음 켬", _toggle_effects)
	_make_label(settings_panel, "효과음 음량", 14)
	effects_slider = HSlider.new()
	effects_slider.min_value = 0.0
	effects_slider.max_value = 1.0
	effects_slider.step = 0.05
	effects_slider.custom_minimum_size.y = 44
	effects_slider.tooltip_text = "효과음 음량"
	effects_slider.value_changed.connect(_on_effects_volume_changed)
	settings_panel.add_child(effects_slider)
	_make_button(settings_panel, "설정 닫기", _on_settings_pressed)
	settings_save_timer = Timer.new()
	settings_save_timer.one_shot = true
	settings_save_timer.wait_time = 0.3
	settings_save_timer.timeout.connect(_save_current)
	add_child(settings_save_timer)

func _apply_audio_settings() -> void:
	game_audio.set_enabled(false)
	game_audio.set_music_enabled(GameManager.music_enabled)
	game_audio.set_effects_enabled(GameManager.effects_enabled)
	game_audio.set_music_volume(GameManager.music_volume)
	game_audio.set_effects_volume(GameManager.effects_volume)
	game_audio.set_enabled(sound_enabled)

func _on_settings_pressed() -> void:
	if not playable:
		return
	_cancel_selection()
	game_audio.play_cue("button")
	settings_panel.visible = not settings_panel.visible
	if settings_panel.visible:
		scroll.call_deferred("ensure_control_visible", settings_panel)

func _toggle_music() -> void:
	if not playable:
		return
	GameManager.music_enabled = not GameManager.music_enabled
	game_audio.set_music_enabled(GameManager.music_enabled)
	_refresh_ui()
	_save_current()

func _toggle_effects() -> void:
	if not playable:
		return
	GameManager.effects_enabled = not GameManager.effects_enabled
	game_audio.set_effects_enabled(GameManager.effects_enabled)
	game_audio.play_cue("button")
	_refresh_ui()
	_save_current()

func _on_music_volume_changed(value: float) -> void:
	if not playable:
		return
	GameManager.music_volume = value
	game_audio.set_music_volume(value)
	settings_save_timer.start()

func _on_effects_volume_changed(value: float) -> void:
	if not playable:
		return
	GameManager.effects_volume = value
	game_audio.set_effects_volume(value)
	settings_save_timer.start()

func _build_tutorial_card() -> void:
	tutorial_card = PanelContainer.new()
	tutorial_card.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#eef4f8")
	style.border_color = Color("#3d5a80")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	tutorial_card.add_theme_stylebox_override("panel", style)
	content.add_child(tutorial_card)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	tutorial_card.add_child(body)
	tutorial_title_label = _make_label(body, "", 15)
	tutorial_title_label.add_theme_color_override("font_color", Color("#3d5a80"))
	tutorial_body_label = _make_label(body, "", 14)
	tutorial_body_label.custom_minimum_size.y = 64
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	body.add_child(buttons)
	tutorial_action_button = _make_button(buttons, "계속 플레이", _on_tutorial_action_pressed)
	tutorial_action_button.visible = false
	tutorial_skip_button = _make_button(buttons, "건너뛰기", _on_tutorial_skip_pressed)

func _on_tutorial_step_changed(_step: int, title: String, body: String, action_text: String) -> void:
	tutorial_title_label.text = title
	tutorial_body_label.text = body
	tutorial_action_button.visible = not action_text.is_empty()
	tutorial_card.visible = true
	if tutorial_tween != null and tutorial_tween.is_valid():
		tutorial_tween.kill()
	tutorial_card.modulate.a = 0.0
	tutorial_tween = create_tween()
	tutorial_tween.tween_property(tutorial_card, "modulate:a", 1.0, 0.18)

func _on_tutorial_finished() -> void:
	_cancel_selection()
	if tutorial_tween != null and tutorial_tween.is_valid():
		tutorial_tween.kill()
	tutorial_card.visible = false
	GameManager.tutorial_completed = true
	if playable:
		_save_current()

func _on_tutorial_action_pressed() -> void:
	if playable:
		tutorial_controller.complete_current_step()

func _on_tutorial_skip_pressed() -> void:
	if playable:
		tutorial_controller.skip()

func _on_help_pressed() -> void:
	if not playable:
		return
	_cancel_selection()
	if tutorial_controller.is_active():
		tutorial_controller.skip()
	else:
		tutorial_controller.replay(not _is_board_completed())
		scroll.call_deferred("ensure_control_visible", tutorial_card)

func _load_levels() -> bool:
	var file := FileAccess.open("res://data/levels.json", FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Array or parsed.is_empty():
		return false
	for entry in parsed:
		if not entry is Dictionary or not entry.get("words") is Array or entry["words"].is_empty():
			return false
		if int(entry.get("rows", 0)) <= 0 or int(entry.get("cols", 0)) <= 0:
			return false
	levels_data = parsed
	return true

func _restore_progress() -> void:
	current_level_idx = clampi(GameManager.current_level_idx, 0, levels_data.size() - 1)
	coins = GameManager.coins
	sound_enabled = GameManager.sound_enabled
	var level: Dictionary = levels_data[current_level_idx]
	level_controller.load_level(level)
	if current_level_idx != GameManager.current_level_idx:
		return
	var cell_map := level_controller._build_cell_map()
	var valid_coords: Array = []
	for coord in GameManager.saved_filled_coords:
		if cell_map.has("%s,%s" % [coord[0], coord[1]]):
			valid_coords.append(coord)
	level_controller.load_level(level, valid_coords)
	for word in GameManager.saved_bonus_words:
		if level.get("bonusWords", []).has(word) and not found_bonus_words.has(word):
			found_bonus_words.append(word)
	reward_claimed = GameManager.reward_claimed if GameManager.reward_claimed_known else _is_board_completed()
	if _is_board_completed():
		reward_claimed = true

func _build_level() -> void:
	_cancel_selection()
	for child in board_grid.get_children():
		board_grid.remove_child(child)
		child.queue_free()
	for child in rack_grid.get_children():
		rack_grid.remove_child(child)
		child.queue_free()
	cells.clear()
	tiles.clear()
	var level: Dictionary = levels_data[current_level_idx]
	var cell_map := level_controller._build_cell_map()
	board_grid.columns = int(level["cols"])
	for row in range(int(level["rows"])):
		for col in range(int(level["cols"])):
			var key := "%s,%s" % [row, col]
			var cell: BoardCell = CELL_SCENE.instantiate()
			cell.setup_cell(row, col, String(cell_map.get(key, "")), level_controller.filled_coords.has(key))
			board_grid.add_child(cell)
			cells[key] = cell
	var letters: Array = cell_map.values()
	letters.sort()
	var seen: Dictionary = {}
	for value in letters:
		var letter := String(value)
		if seen.has(letter):
			continue
		seen[letter] = true
		var tile: LetterTile = TILE_SCENE.instantiate()
		tile.setup_tile(letter, 0)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.tile_selected.connect(swipe_controller.append_letter)
		rack_grid.add_child(tile)
		tiles.append(tile)
	_refresh_ui()
	_refresh_layout()

func _on_word_changed(word: String) -> void:
	current_word_button.text = word if not word.is_empty() else "·"
	if playable:
		_refresh_rack()
		if not word.is_empty():
			game_audio.play_cue("select")
			tutorial_controller.on_valid_letter_selected()

func _refresh_rack() -> void:
	var counts := level_controller.recalculate_tile_counts()
	var selected := "".join(swipe_controller.current_letters)
	for tile in tiles:
		var remaining := int(counts.get(tile.letter, 0))
		var available := maxi(0, remaining - selected.count(tile.letter))
		var next_text := selected + tile.letter
		var allowed := level_controller.can_select_text(next_text)
		tile.set_remaining(available)
		tile.set_selectable(allowed, allowed and not level_controller._fits_remaining_tiles(next_text))

func _refresh_ui() -> void:
	level_label.text = "LEVEL %d" % [current_level_idx + 1]
	theme_label.text = String(levels_data[current_level_idx].get("theme", ""))
	coin_label.text = "코인 %d" % coins
	sound_button.text = "소리 켬" if sound_enabled else "소리 끔"
	master_sound_button.text = "전체 소리 켬" if sound_enabled else "전체 소리 끔"
	music_button.text = "음악 켬" if GameManager.music_enabled else "음악 끔"
	effects_button.text = "효과음 켬" if GameManager.effects_enabled else "효과음 끔"
	music_slider.set_value_no_signal(GameManager.music_volume)
	effects_slider.set_value_no_signal(GameManager.effects_volume)
	next_button.disabled = not _is_board_completed() or current_level_idx >= levels_data.size() - 1
	var targets := PackedStringArray()
	var solved_count := 0
	for word in levels_data[current_level_idx]["words"]:
		var solved := level_controller._is_word_solved(word)
		if solved:
			solved_count += 1
		var text := String(word["word"])
		var shown := text if solved or (show_debug_answers and OS.is_debug_build()) else "□".repeat(text.length())
		targets.append(("✓ " if solved else "· ") + shown)
	target_label.text = "찾은 단어 %d / %d\n" % [solved_count, levels_data[current_level_idx]["words"].size()] + "   ".join(targets)
	bonus_label.text = "찾은 보너스: " + (", ".join(found_bonus_words) if not found_bonus_words.is_empty() else "없음")
	var cell_map := level_controller._build_cell_map()
	for key in cells:
		var cell: BoardCell = cells[key]
		if level_controller.filled_coords.has(key) and not cell.is_filled:
			cell.set_filled_with_pop(String(cell_map[key]))
	_refresh_rack()

func _is_board_completed() -> bool:
	if levels_data.is_empty():
		return false
	for word in levels_data[current_level_idx]["words"]:
		if not level_controller._is_word_solved(word):
			return false
	return true

func _completion_message() -> String:
	return "모든 레벨을 완료했습니다!" if current_level_idx == levels_data.size() - 1 else "스테이지 클리어!"

func _check_level_clear() -> void:
	if not _is_board_completed():
		return
	var awarded := not reward_claimed
	if awarded:
		coins += 30
		reward_claimed = true
		game_audio.play_cue("clear")
	status_label.text = _completion_message() + (" +30 코인" if awarded else "")

func _on_word_submitted(word: String) -> void:
	if not playable:
		return
	_reset_gesture()
	var answer: Dictionary = {}
	var cue := "success"
	for item in levels_data[current_level_idx]["words"]:
		if String(item["word"]) == word and not level_controller._is_word_solved(item):
			answer = item
			break
	if not answer.is_empty():
		level_controller.mark_word_solved(answer)
		coins += maxi(10, word.length() * 5)
		status_label.text = "정답! " + word
		tutorial_controller.on_target_word_solved()
	elif level_controller.can_submit_bonus(word) and not found_bonus_words.has(word):
		cue = "bonus"
		found_bonus_words.append(word)
		coins += 15
		status_label.text = "보너스! %s +15 코인" % word
	else:
		status_label.text = "정답이나 받을 수 있는 보너스가 아닙니다."
		game_audio.play_cue("error")
		swipe_controller.clear_selection()
		return
	_check_level_clear()
	if not _is_board_completed():
		game_audio.play_cue(cue)
	swipe_controller.clear_selection()
	_refresh_ui()
	_save_current()

func _submit_selection() -> void:
	if playable:
		swipe_controller.submit()

func _give_hint() -> void:
	if not playable:
		return
	if _is_board_completed():
		status_label.text = _completion_message()
		return
	if coins < 30:
		status_label.text = "코인이 부족합니다."
		game_audio.play_cue("error")
		return
	_cancel_selection()
	var hint := level_controller.reveal_random_hint()
	if hint.is_empty():
		return
	coins -= 30
	status_label.text = "힌트로 한 칸을 열었습니다."
	_check_level_clear()
	if not _is_board_completed():
		game_audio.play_cue("hint")
	_refresh_ui()
	_save_current()

func _next_level() -> void:
	if not playable or not _is_board_completed() or current_level_idx >= levels_data.size() - 1:
		return
	_cancel_selection()
	current_level_idx += 1
	found_bonus_words.clear()
	reward_claimed = false
	level_controller.load_level(levels_data[current_level_idx])
	_build_level()
	status_label.text = "다음 레벨입니다."
	_save_current()

func _toggle_sound() -> void:
	if not playable:
		return
	sound_enabled = not sound_enabled
	game_audio.set_enabled(sound_enabled)
	if sound_enabled:
		game_audio.play_cue("select")
	_refresh_ui()
	_save_current()

func _save_current() -> void:
	var coords: Array = []
	for key in level_controller.filled_coords:
		var parts := String(key).split(",")
		coords.append([int(parts[0]), int(parts[1])])
	var error := GameManager.commit_progress(current_level_idx, coords, found_bonus_words, coins, sound_enabled, reward_claimed)
	if error != OK:
		status_label.text = "진행도 저장 실패 (%d). 게임은 계속할 수 있습니다." % error

func _tile_at(position: Vector2) -> LetterTile:
	if not scroll.get_global_rect().has_point(position):
		return null
	for tile in tiles:
		if tile.is_visible_in_tree() and tile.get_global_rect().has_point(position):
			return tile
	return null

func _begin_pointer(position: Vector2, pointer: int) -> void:
	if active_pointer != NO_POINTER:
		return
	var tile := _tile_at(position)
	if tile == null or tile.disabled:
		return
	active_pointer = pointer
	pointer_start = position
	drag_moved = false
	left_rack = false
	last_tile = tile
	swipe_controller.append_letter(tile.letter)
	get_viewport().set_input_as_handled()

func _move_pointer(position: Vector2) -> void:
	drag_moved = drag_moved or position.distance_to(pointer_start) > 8.0
	var tile := _tile_at(position)
	if tile == null:
		left_rack = true
	elif (tile != last_tile or left_rack) and not tile.disabled:
		swipe_controller.append_letter(tile.letter)
		last_tile = tile
		left_rack = false
	get_viewport().set_input_as_handled()

func _end_pointer() -> void:
	var should_submit := drag_moved
	_reset_gesture()
	if should_submit:
		swipe_controller.submit()
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not playable:
		return
	if event is InputEventScreenTouch:
		if event.canceled and event.index == active_pointer:
			_cancel_selection()
		elif event.pressed:
			_begin_pointer(event.position, event.index)
		elif event.index == active_pointer:
			_end_pointer()
	elif event is InputEventScreenDrag and event.index == active_pointer:
		_move_pointer(event.position)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_pointer(event.position, -1)
		elif active_pointer == -1:
			_end_pointer()
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and active_pointer == -1:
		_move_pointer(event.position)

func _reset_gesture() -> void:
	active_pointer = NO_POINTER
	drag_moved = false
	left_rack = false
	last_tile = null

func _cancel_selection() -> void:
	_reset_gesture()
	swipe_controller.clear_selection()

func _refresh_layout() -> void:
	for side in ["left", "top", "right", "bottom"]:
		safe_margin.add_theme_constant_override("margin_" + side, 12)
	if OS.get_name() in ["iOS", "Android"]:
		var safe := DisplayServer.get_display_safe_area()
		var window_rect := Rect2i(DisplayServer.window_get_position(), DisplayServer.window_get_size())
		var clipped := safe.intersection(window_rect)
		if clipped.has_area():
			var inverse := get_viewport().get_screen_transform().affine_inverse()
			var safe_start := inverse * Vector2(clipped.position)
			var safe_end := inverse * Vector2(clipped.end)
			var viewport_size := get_viewport_rect().size
			safe_margin.add_theme_constant_override("margin_left", maxi(12, ceili(safe_start.x) + 12))
			safe_margin.add_theme_constant_override("margin_top", maxi(12, ceili(safe_start.y) + 12))
			safe_margin.add_theme_constant_override("margin_right", maxi(12, ceili(viewport_size.x - safe_end.x) + 12))
			safe_margin.add_theme_constant_override("margin_bottom", maxi(12, ceili(viewport_size.y - safe_end.y) + 12))
	_resize_grids()

func _resize_grids() -> void:
	if not playable:
		return
	var available := content.size.x if content.size.x > 0 else get_viewport_rect().size.x - 24.0
	var cell_size := clampf(floorf((available - 6.0 * (board_grid.columns - 1)) / board_grid.columns), 24.0, 46.0)
	for cell in cells.values():
		cell.custom_minimum_size = Vector2(cell_size, cell_size)
	var count := tiles.size()
	var preferred_columns := mini(2, maxi(1, count)) if count <= 4 else (3 if count <= 9 else 4)
	var fitting_columns := maxi(1, floori((available + 8.0) / 66.0))
	rack_grid.columns = mini(preferred_columns, fitting_columns)
	var tile_size := clampf(floorf((available - 8.0 * (rack_grid.columns - 1)) / rack_grid.columns), 62.0, 88.0)
	for tile in tiles:
		tile.custom_minimum_size = Vector2(tile_size, tile_size)

func _notification(what: int) -> void:
	if not playable:
		return
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST]:
		var reason := "focus" if what == NOTIFICATION_APPLICATION_FOCUS_OUT else "pause"
		game_audio.set_suspended(true, reason)
		_cancel_selection()
		_save_current()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		game_audio.set_suspended(false, "focus")
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		game_audio.set_suspended(false, "pause")
