# assets — 앱 리소스 (이미지)

Flutter 앱에서 사용하는 이미지 리소스 디렉토리.
`pubspec.yaml`의 `flutter.assets`에 등록되어 `Image.asset()`으로 참조한다.

---

## 디렉토리 구조

```
assets/
└── images/
    ├── front.png         ← 전면 인체 이미지 (부위 선택 화면)
    ├── back.png          ← 후면 인체 이미지 (부위 선택 화면)
    ├── tools/            ← 도구 이미지 (tool-01.png ~ tool-11.png)
    ├── moves/            ← 동작 이미지 (추후 추가 예정)
    └── muscles/          ← 근육 이미지 (추후 추가 예정)
```

---

## 파일 명명 규칙

| 폴더 | 패턴 | 예시 |
|------|------|------|
| `tools/` | `tool-{인덱스 2자리}.png` | `tool-01.png`, `tool-11.png` |
| `moves/` | (미정) | — |
| `muscles/` | (미정) | — |

도구 이미지 인덱스는 `lib/assets/tool_assets.dart`의 `kTools` 인덱스와 1:1 대응한다.

---

## 참조 방법

```dart
// 도구 이미지
Image.asset('assets/images/tools/tool-01.png');

// Tool 객체에서 직접
final tool = kTools[1]!;
Image.asset(tool.imagePath);  // → 'assets/images/tools/tool-01.png'

// 인체 이미지
Image.asset('assets/images/front.png');
Image.asset('assets/images/back.png');
```
