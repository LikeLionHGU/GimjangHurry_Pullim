# assets — 근막이완 에셋 데이터

근막이완 프로그램의 기초 데이터를 정의하는 순수 Dart 파일들.  
외부 의존성 없이 상수(const)로만 구성되어 있다.

---

## 파일 구조

| 파일 | 내용 | 인덱스 범위 |
|------|------|-------------|
| `body_assets.dart` | 신체 부위 42개 | 1~42 (전면 1~22, 후면 23~42) |
| `move_assets.dart` | 근막이완 동작 67개 | 1~67 |
| `tool_assets.dart` | 도구 13개 | 1~13 |

---

## body_assets.dart

42개 신체 부위. 각 부위는 인덱스, 근육명, 전면/후면, 부위 구역, 좌표(xy)를 포함.

- `kBodies` — `Map<int, Body>` 전체 조회
- `bodyOf(index)` — 단건 조회
- `bodiesOf(indexes)` — 다건 조회
- `bodiesOfFace(face)` — 전면/후면 필터
- `bodiesOfPart(face, part)` — 구역별 필터

## move_assets.dart

67개 근막이완 동작. 각 동작은 인덱스, 이름, 자세(Posture), 대상 부위(body index 리스트), 사용 가능 도구(tool index 리스트, 첫 번째가 권장), 설명, 시간 범위(min/max 초, 편측 기준)를 포함.

- `kMoves` — `Map<int, Move>` 전체 조회
- `moveOf(index)` — 단건 조회
- `movesByBody(bodyIndex)` — 부위별 필터
- `movesByTool(toolIndex)` — 도구별 필터
- `movesByOwnedTools(ownedToolIndexes)` — 보유 도구로 수행 가능한 동작 필터
- `movesByPosture(posture)` — 자세별 필터
- `movesWithoutFloor()` — 바닥 불필요 동작만

## tool_assets.dart

13개 도구. 폼롤러(5종), 마사지볼(6종), 스틱(2종).

- `kTools` — `Map<int, Tool>` 전체 조회
- `toolOf(index)` — 단건 조회
- `toolsOf(indexes)` — 다건 조회
- `toolsByCategory(category)` — 카테고리별 필터

---

## 데이터 관계

```
Move.body  → Body.index   (동작이 어떤 부위에 해당하는지)
Move.tool  → Tool.index   (동작에 사용 가능한 도구, 순서 = 우선순위)
```

---

## 참조 방법

```dart
import 'package:likelion_mid_hackathon/assets/body_assets.dart';
import 'package:likelion_mid_hackathon/assets/move_assets.dart';
import 'package:likelion_mid_hackathon/assets/tool_assets.dart';
```
