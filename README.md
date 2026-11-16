# Word Tiles - Relaxing Puzzle

`Word Tiles - Relaxing Puzzle`는 스와이프 기반 단어 퍼즐을 빠르게 실험하고, 이후 Godot 모바일 프로젝트로 확장할 수 있도록 정리한 continuation-ready 저장소입니다.

## 포함 내용

- `web-prototype/index.html`: 브라우저에서 즉시 실행 가능한 단일 파일 프로토타입
- `tools/level_generator.py`: 교차형 단어 퍼즐 레벨 생성기
- `docs/`: 기획/데이터 스키마 문서
- `godot-project/`: Godot 4.x 이식용 스캐폴드와 핵심 스크립트

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

## 현재 구현 범위

- 스와이프/클릭 기반 입력
- 교차 칸 중복 차감 방지형 타일 카운트 계산
- 보너스 단어 및 코인 보상
- 랜덤 힌트와 로컬 저장
- Web Audio API 효과음 토글
- Godot 이식용 데이터/스크립트 스캐폴드

## 다음 권장 작업

1. 더 큰 영어/한국어 사전 연결
2. 난이도 밸런싱과 자동 레벨 검증
3. Godot 씬 구성(`MainGame.tscn`, `LetterTile.tscn`, `BoardCell.tscn`) 완성
4. 광고/상점/일일 챌린지 UI 고도화
