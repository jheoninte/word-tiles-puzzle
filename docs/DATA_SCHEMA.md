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
  "updatedAt": 1794792373000
}
```

## dictionary.json

```json
{
  "STAR": "밤하늘에 빛나는 별",
  "TREE": "줄기와 가지, 잎을 가진 나무"
}
```
