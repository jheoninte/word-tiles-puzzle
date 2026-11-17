extends Node
class_name GameAudio

const SAMPLE_RATE := 22050
const MUSIC_STREAM: AudioStreamWAV = preload("res://audio/garden_loop.wav")
const CUES := {
	"select": {"notes": [660.0], "duration": 0.035},
	"success": {"notes": [523.25, 659.25, 783.99], "duration": 0.075},
	"bonus": {"notes": [783.99, 1046.50], "duration": 0.075},
	"hint": {"notes": [659.25, 880.0], "duration": 0.09},
	"error": {"notes": [220.0, 196.0], "duration": 0.065},
	"clear": {"notes": [523.25, 659.25, 783.99, 1046.50], "duration": 0.095},
	"button": {"notes": [440.0], "duration": 0.035},
	"coin": {"notes": [880.0, 1174.66], "duration": 0.045},
	"reward": {"notes": [659.25, 783.99, 1046.50], "duration": 0.09},
	"notice": {"notes": [392.0], "duration": 0.09},
}

var enabled: bool = true
var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var next_player: int = 0
var music_enabled: bool = true
var effects_enabled: bool = true
var music_volume: float = 0.65
var effects_volume: float = 0.8
var music_player: AudioStreamPlayer
var suspensions: Dictionary = {}

func _ready() -> void:
	for cue in CUES:
		var definition: Dictionary = CUES[cue]
		streams[cue] = _make_stream(definition["notes"], float(definition["duration"]))
	for index in range(4):
		var player := AudioStreamPlayer.new()
		player.volume_db = -18.0
		add_child(player)
		players.append(player)
	music_player = AudioStreamPlayer.new()
	var music_stream: AudioStreamWAV = MUSIC_STREAM.duplicate()
	music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music_stream.loop_begin = 0
	music_stream.loop_end = roundi(music_stream.get_length() * music_stream.mix_rate)
	music_player.stream = music_stream
	add_child(music_player)
	_update_volumes()

func _make_stream(notes: Array, duration: float) -> AudioStreamWAV:
	var note_samples := int(duration * SAMPLE_RATE)
	var gap_samples := int(0.01 * SAMPLE_RATE)
	var stride := note_samples + gap_samples
	var samples := PackedByteArray()
	samples.resize(notes.size() * stride * 2)
	for note_index in range(notes.size()):
		var frequency := float(notes[note_index])
		for sample_index in range(note_samples):
			var elapsed := float(sample_index) / SAMPLE_RATE
			var remaining := float(note_samples - 1 - sample_index) / SAMPLE_RATE
			var envelope := clampf(minf(elapsed / 0.006, remaining / 0.025), 0.0, 1.0)
			var phase := TAU * frequency * elapsed
			var wave := (sin(phase) + 0.15 * sin(phase * 2.0)) * 0.7 * envelope
			samples.encode_s16((note_index * stride + sample_index) * 2, int(wave * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	return stream

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		for player in players:
			player.stop()
	_update_music()

func set_music_enabled(value: bool) -> void:
	music_enabled = value
	_update_music()

func set_effects_enabled(value: bool) -> void:
	effects_enabled = value
	if not effects_enabled:
		for player in players:
			player.stop()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0) if is_finite(value) else 0.65
	_update_volumes()
	_update_music()

func set_effects_volume(value: float) -> void:
	effects_volume = clampf(value, 0.0, 1.0) if is_finite(value) else 0.8
	_update_volumes()

func set_suspended(value: bool, reason: String = "app") -> void:
	if value:
		suspensions[reason] = true
		for player in players:
			player.stop()
	else:
		suspensions.erase(reason)
	_update_music()

func _update_volumes() -> void:
	for player in players:
		player.volume_db = -18.0 + linear_to_db(maxf(effects_volume, 0.0001))
	if music_player != null:
		music_player.volume_db = -28.0 + linear_to_db(maxf(music_volume, 0.0001))

func _update_music() -> void:
	if music_player == null:
		return
	var should_play := enabled and music_enabled and music_volume > 0.0 and suspensions.is_empty()
	if should_play and not music_player.playing:
		music_player.play()
	music_player.stream_paused = not should_play

func play_cue(cue: String) -> void:
	if not enabled or not effects_enabled or effects_volume <= 0.0 or not suspensions.is_empty() or players.is_empty() or not streams.has(cue):
		return
	var player := players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stream = streams[cue]
	player.play()

func _exit_tree() -> void:
	set_enabled(false)
	if music_player != null:
		music_player.stop()
