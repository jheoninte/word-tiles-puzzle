# Word Tiles - Relaxing Puzzle

`Word Tiles - Relaxing Puzzle`는 스와이프 기반 단어 퍼즐을 빠르게 실험하고, 이후 Godot 모바일 프로젝트로 확장할 수 있도록 정리한 continuation-ready 저장소입니다.

## 포함 내용

- `web-prototype/index.html`: 브라우저에서 즉시 실행 가능한 단일 파일 프로토타입
- `tools/level_generator.py`: 교차형 단어 퍼즐 레벨 생성기
- `docs/`: 기획/데이터 스키마 문서
- `godot-project/`: Godot 4.x에서 실행하는 오프라인 게임과 핵심 스크립트

## 빠른 실행

### 웹 프로토타입

정적 파일이라 바로 더블클릭으로 열어도 되지만, 로컬 스토리지와 상대 경로 테스트를 위해 간단한 서버 실행을 권장합니다.

```bash
python -m http.server 8080 --directory web-prototype
```

이후 브라우저에서 `http://localhost:8080` 접속.

### 레벨 생성기

```bash
python tools/level_generator.py --count 20 --output godot-project/data/levels.generated.json
```

### Godot 게임

Godot에서 `godot-project/project.godot`을 열고 F5로 실행합니다. 메인 씬, 기본 3개 레벨, 탭/스와이프, 보상과 저장이 연결되어 있습니다. 실제 검증 버전은 Godot 4.7.2이며 자세한 실행법·검증 범위·미구현 항목은 `docs/GODOT_PLAYABLE.md`를 참고하세요.

## 현재 구현 범위

- 스와이프/클릭 기반 입력
- 교차 칸 중복 차감 방지형 타일 카운트 계산
- 보너스 단어 및 코인 보상
- 랜덤 힌트와 로컬 저장
- Web Audio API 효과음 토글
- Godot 메인 씬, 작은 화면 스크롤 UI, 교차 글자 재사용, 오프라인 일괄 저장
- Godot 첫 실행 튜토리얼·도움말, 미완성 정답 숨김, 48초 BGM·효과음 10종·독립 음량 저장

## 다음 권장 작업

`docs/LAUNCH_SCOPE.md`의 1~9 순서로 진행한다. 언어별 일반 450+일일 30, ko/en/ja가 목표이며 현재 구현된 기본 레벨은 3개다. 다음은 세 언어 UI·언어별 진행 기반과 작은 화면 조작 개선이다. 아트 명세·문구·콘텐츠 첫 묶음은 `docs/GEMINI_LAUNCH_CONTENT_TASK.md`로 Gemini와 협업한다. 소스 전달본은 `python -B tools/prepare_launch_handoff.py`로 만든다.
