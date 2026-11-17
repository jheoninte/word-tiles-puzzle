extends Node
class_name TutorialController

signal step_changed(step: int, title: String, body: String, action_text: String)
signal tutorial_finished()

enum Step { NONE, SELECT_LETTER, SUBMIT_WORD, CROSSING_REUSE }

var current_step: int = Step.NONE
var completed: bool = false
var is_replay: bool = false

func setup(already_completed: bool, has_existing_progress: bool) -> void:
	completed = already_completed
	is_replay = false
	current_step = Step.NONE
	if not completed and not has_existing_progress:
		_enter_step(Step.SELECT_LETTER)

func is_active() -> bool:
	return current_step != Step.NONE

func replay(can_practice: bool = true) -> void:
	is_replay = true
	_enter_step(Step.SELECT_LETTER if can_practice else Step.CROSSING_REUSE)

func on_valid_letter_selected() -> void:
	if current_step == Step.SELECT_LETTER:
		_enter_step(Step.SUBMIT_WORD)

func on_target_word_solved() -> void:
	if current_step == Step.SUBMIT_WORD:
		_enter_step(Step.CROSSING_REUSE)

func complete_current_step() -> void:
	if current_step == Step.CROSSING_REUSE:
		_finish()

func skip() -> void:
	if is_active():
		_finish()

func _enter_step(step: int) -> void:
	current_step = step
	match step:
		Step.SELECT_LETTER:
			step_changed.emit(step, "1/3 글자 선택하기", "화면을 위로 밀어 타일을 찾고, 누르거나 스와이프하세요.", "")
		Step.SUBMIT_WORD:
			step_changed.emit(step, "2/3 정답 단어 완성하기", "보드의 정답을 만들고 제출하세요. 스와이프는 손을 떼면 제출됩니다.", "")
		Step.CROSSING_REUSE:
			step_changed.emit(step, "3/3 남은 수량과 ↻", "숫자는 남은 빈 칸 수입니다. ↻ 글자는 0개여도 정답에 다시 쓸 수 있습니다.", "계속 플레이")

func _finish() -> void:
	completed = true
	current_step = Step.NONE
	is_replay = false
	tutorial_finished.emit()
