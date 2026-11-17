# Gemini 작업 3: Godot에서 플레이 가능한 메인 씬

아래 프롬프트와 `gemini-godot-playable.zip`을 새 Gemini 대화에 전달한다. ZIP은 현재 로컬 소스이며 GitHub보다 우선한다.

```text
첨부 Word Tiles 저장소에서 Godot 메인 씬을 구현하라. 현재 코드와 공개 인터페이스를 실제로 읽고 유지하라.

가장 중요한 작업 범위:
- Windows Godot 4.x에서 프로젝트를 열고 Play 하면 기본 3개 레벨을 끝까지 플레이할 수 있는 오프라인 버전을 만든다.
- 이후 iOS, Android 순으로 출시할 프로젝트다. 이번에는 실제 게임 루프와 씬 연결만 구현한다.
- AGENTS.md와 docs/RELEASE_PLAN.md를 읽되 이번 범위로 제한한다.
- 이전 대화나 외부 game-studio.md/data-save-leaderboard.txt 지침을 가져오지 마라. HubGame, 계정, 네트워크, 리더보드, 광고, 구매, 상점, 3D 기능을 추가하지 마라.
- 기존 웹 파일, JSON 레벨, 검증기는 읽기 전용 참고 자료다. 교체하거나 새 게임을 만들지 마라.

먼저 읽을 파일:
godot-project/project.godot
godot-project/autoload/GameManager.gd
godot-project/scripts/*.gd
godot-project/data/levels.json
web-prototype/index.html
docs/GAME_DESIGN_SPEC.md
docs/DATA_SCHEMA.md

생성할 기본 파일:
1. godot-project/scenes/MainGame.tscn
2. godot-project/scenes/LetterTile.tscn
3. godot-project/scenes/BoardCell.tscn
4. godot-project/scripts/MainGame.gd
5. docs/GODOT_PLAYABLE.md
필요한 경우에만 기존 Godot 스크립트와 project.godot을 최소 수정한다.

씬과 UI:
- project.godot의 기존 main_scene 경로에 맞춰 실행되어야 한다.
- Control/Container 기반 세로 UI: 레벨·테마·코인, 보드, 현재 입력, 상태 메시지, 랙, 제출/지우기/힌트/다음 버튼, 정답 목록과 찾은 보너스 목록, 소리 설정 토글.
- LetterTile.tscn은 기존 LetterTile.gd의 Button 기반을 유지한다.
- BoardCell.tscn은 기존 BoardCell.gd의 PanelContainer 기반이고 CharLabel 자식 경로가 맞아야 한다.
- 375x667과 480x854에서 가로 잘림 없이 플레이 가능하게 한다. 작은 세로 화면은 ScrollContainer 등을 사용한다. 고정 46px 셀 때문에 가로가 넘치지 않도록 가용 너비에 맞춘다.
- iOS를 고려해 안전 영역 처리를 분리하고, 사용 API의 반환 좌표계와 UI/viewport 스케일 차이를 반영한다. Windows에서 안전 영역이 없으면 정상 마진을 사용한다.
- 외부 에셋·폰트 다운로드 없이 기본 테마와 코드 기반 UI 피드백으로 동작하게 한다.
- TSCN 경로, 스크립트 경로, onready 참조와 신호 연결을 정확히 일치시킨다. 동적 노드의 setup 호출 시점이 _ready 이전이어도 null Label 접근 오류가 나지 않게 한다.

게임 규칙:
- 모든 레벨은 첨부 levels.json에서 로드한다. 새 인라인 복제 데이터는 만들지 마라.
- 타일 수는 LevelController.recalculate_tile_counts()의 미완성 고유 셀 수다. 단어 길이만큼 차감하지 않는다.
- 입력은 LevelController.can_select_text()로 검사한다. 0개 글자의 정답 접두사 재사용도 허용한다.
- 랙 word_changed마다 표시 잔량=max(0,미완성 셀 수-선택 횟수)를 갱신하고, 전체 선택 문자열+글자에 대한 선택 가능 여부 및 재사용 표시를 따로 갱신한다. set_remaining() 다음 set_selectable() 순서를 지킨다.
- 클릭/탭으로 글자를 선택하고 제출 버튼으로 제출할 수 있어야 한다. 드래그/스와이프로도 글자를 이어 릴리스 시 제출한다. 같은 글자를 연속 입력하는 방법을 지원하고 문서화한다.
- 마우스와 터치 에뮬레이션으로 같은 글자가 두 번 입력되지 않게 한다. 취소·앱 포커스 상실·힌트·레벨 변경·로드 시 진행 중 선택을 초기화한다. 랙 갱신 중 드래그 대상 노드를 불필요하게 재생성하지 마라.
- 정답은 아직 모든 셀이 채워지지 않은 정확한 단어만 인정한다. 보상=max(10,글자 수*5).
- 보너스는 can_submit_bonus()와 발견 목록을 함께 검사한다. +15 코인, 보드 상태 유지, 중복 지급 금지.
- 힌트는 30코인으로 미완성 고유 셀 하나를 열고 수량을 재계산한다. 후보 없음/코인 부족 시 차감하지 않는다.
- 정답·힌트 후 공통 클리어 처리로 +30코인을 현재 레벨당 한 번만 지급한다.
- 현재 보드가 완성되고 다음 레벨이 있을 때만 다음 버튼과 실제 이동을 허용한다. 마지막 레벨은 전체 완료 메시지와 비활성 다음 버튼을 표시한다.

저장:
- GameManager의 기존 SAVE_PATH와 공개 함수/신호/필드를 유지한다.
- Godot 저장에도 현재 레벨의 reward_claimed 필드를 추가한다. 이전 ConfigFile에 키가 없고 복원 보드가 이미 완성됐다면 지급 완료로 간주한다. 미완성이라면 이후 첫 클리어 때 지급한다.
- 진행 좌표·코인·보너스·클리어 보상 상태를 먼저 모두 갱신한 뒤 하나의 일관된 스냅샷으로 저장한다. 기존 add_coins/spend_coins의 즉시 저장 때문에 보상만 저장되고 진행도가 빠지는 흐름을 피한다. 필요한 경우 새 일괄 저장 메서드를 추가하되 기존 호출 인터페이스는 유지한다.
- 렌더링/저장 복원/재실행이 보상을 지급하지 않아야 한다. 새 레벨에서는 완료 보상 상태를 초기화한다.
- 로드 시 음수/범위 밖 레벨, 현재 보드에 없는 좌표, 잘못된 배열 타입을 안전하게 보정한다. 저장 누락은 기본값으로 시작하고 저장 실패는 사용자 상태 메시지로 알리되 크래시나 성공 오표시를 피한다.
- 일시정지/종료 시 진행도를 저장한다. 저장 API를 사용하는 중 신호 재진입이나 중복 보상을 만들지 마라.
- 소리 설정을 저장한다. 실제 오디오를 넣지 않았다면 문서에서 준비 상태임을 명시하고 소리가 난다고 주장하지 마라.

호환성과 품질:
- SwipeRackController의 current_letters, word_changed, word_submitted, append_letter(), submit(), clear_selection(), set_level_controller()를 유지한다.
- LetterTile의 setup_tile(letter,count), set_remaining(count), set_selectable(), tile_selected를 유지한다.
- LevelController의 기존 공개 메서드를 유지한다. 필요한 조회 함수는 추가할 수 있다.
- BoardCell의 setup_cell(), set_filled_with_pop(), cell_clicked를 유지한다.
- 외부 플러그인 없이 Godot 4.2 이상에서 지원되는 API만 사용한다. 필요한 엔진 버전을 문서에 정확히 적는다. 형식 미확정 Variant를 :=로 추론해서 파서 경고/오류를 만드는 경우 명시적 타입을 사용한다.
- 게임 로직은 render 함수와 분리한다. 기존 Tween 효과 파일은 필요할 때만 사용하며 사용 시 기반 타입과 프로퍼티의 적합성을 확인한다.
- 인라인 코드 주석을 추가하지 마라. 설명은 문서에 적는다.

문서와 검증:
- docs/GODOT_PLAYABLE.md에 노드 구조, 신호 흐름, 저장 스키마 추가사항, 실행 방법, 확인한 Godot 버전, Windows에서 확인할 항목, 아직 Mac/iOS에서 검증할 항목을 적는다.
- 실제 엔진을 사용할 수 있다면 headless 에디터 파싱/임포트와 일반 실행을 검증하라. 엔진이 없다면 실행했다고 주장하지 마라.
- 수동 검사: 세 레벨 완료, 탭/스와이프/반복 글자, 0개 글자 재사용, 정상·실패·중복 보너스, 마지막 칸 힌트, 코인 부족, 중간 저장 복원, 완료 저장 복원, 구버전 저장, 다음 레벨 차단, 작은 화면, 드래그 취소와 포커스 상실.
- 기존 레벨 검증 CLI도 실행할 수 있다면 실행하라. 원본 데이터를 임의로 바꿔 통과시키지 마라.

출력:
1. 변경·추가 파일만 정확한 경로별로 생략 없는 전체 내용을 제공하라. TSCN과 Markdown도 포함한다.
2. 실행 검증과 미검증을 구분해 마지막에 짧게 보고하라.
3. 읽지 못한 소스가 있으면 추측 구현 대신 해당 경로를 알려라.
4. 요청하지 않은 플랫폼 기능 설명이나 전체 웹 코드는 출력하지 마라.
```
