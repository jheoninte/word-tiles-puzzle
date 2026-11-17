# Data Schema

## Level JSON

```json
{
  "theme": "자연과 휴식",
  "rows": 5,
  "cols": 5,
  "difficulty": 42,
  "words": [
    { "word": "STAR", "r": 0, "c": 0, "dir": "H" }
  ],
  "bonusWords": ["TEA", "ART"]
}
```

## Save JSON (web prototype localStorage)

```json
{
  "levelIdx": 0,
  "coins": 130,
  "soundEnabled": true,
  "filledCoords": [[0, 0], [0, 1]],
  "foundBonusWords": ["TEA"],
  "rewardClaimed": false,
  "updatedAt": 1794792373000
}
```

`rewardClaimed`는 현재 레벨의 클리어 보상(+30 코인) 지급 여부입니다. 정답 또는 힌트로 보드를 완성하면 한 번만 지급하고 진행도와 함께 저장합니다. 다음 레벨 이동이나 레벨 초기화 시 `false`로 초기화합니다.

이 필드가 없는 기존 저장은 보드가 완성되어 있으면 `true`, 미완성이면 `false`로 복원합니다. 완성된 기존 저장에는 보상을 다시 지급하지 않습니다.

## Godot ConfigFile

기존 `user://word_tiles_save_v1.cfg`의 `[progress]`에 `level_idx`, `coins`, `sound_enabled`, `filled_coords`, `bonus_words`와 boolean `reward_claimed`를 저장합니다. 좌표는 `[[row,col], ...]`입니다. 이전 저장에 `reward_claimed`가 없으면 복원 보드가 이미 완성된 경우에만 지급 완료로 취급합니다.

`GameManager.commit_progress()`는 진행도·재화·설정·완료 상태를 함께 갱신하고 임시 ConfigFile 저장 후 rename합니다. 기존 `save_progress()` 등의 인터페이스는 유지합니다. 실패 시 이전 파일을 유지하고 `save_failed(error)`를 보내며, 실제 게임 UI에서도 실패를 알립니다. 자세한 로드 보정과 검증 범위는 `GODOT_PLAYABLE.md`를 참고하세요.

Godot 전용 boolean `tutorial_completed`는 동일한 `[progress]`에 저장한다. 키 누락·잘못된 타입은 false이며, 건너뛰기·완료 시 true로 저장한다. 도움말 재생은 완료 상태를 초기화하지 않는다. 기존 진행이 있는 사용자에게 자동 안내를 생략해도 완료 필드를 임의로 true로 만들지는 않는다. 중간 안내 단계는 저장하지 않는다. 자세한 동작과 검증은 `ONBOARDING.md`를 따른다.

오디오 추가 필드는 boolean `music_enabled`·`effects_enabled`(기본 true), float `music_volume`(0.65)·`effects_volume`(0.8)다. `sound_enabled`는 전체 음소거를 계속 담당한다. 유효한 음량은 0~1로 제한하며 누락·잘못된 타입·NaN·무한대는 기본값을 사용한다. 기존 commit_progress 인자 수는 그대로다. 상세 제어는 `AUDIO.md`를 따른다. 언어별 진행 저장은 아직 구현 전이며 이 필드 추가와 구분한다.

## dictionary.json

```json
{
  "STAR": "밤하늘에 빛나는 별",
  "TREE": "줄기와 가지, 잎을 가진 나무"
}
```
