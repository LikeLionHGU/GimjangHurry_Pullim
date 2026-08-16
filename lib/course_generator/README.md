# course_generator — AI 근막이완 코스 생성 엔진

피로한 신체 부위, 보유 도구, 가용 시간, 부위별 피로도를 입력받아  
최적의 근막이완 동작 코스를 생성하는 Dart 라이브러리.

로컬 필터링으로 후보 동작을 좁힌 뒤, OpenAI GPT-4o가 최종 동작 선택 · 순서 배치 · 시간 배분 · 선택 이유를 결정한다.

---

## 디렉토리 구조

```
course_generator/
├── course_generator_library.dart  ← barrel export (외부에서 이 파일 하나만 import)
├── course_generator.dart          ← 메인 엔진 클래스 (파이프라인 통합)
├── move_filter.dart               ← 로컬 필터링 (보유 도구 × 피로 부위 교집합)
├── prompt_builder.dart            ← OpenAI 프롬프트 조립 + JSON schema 정의
├── env_loader.dart                ← 환경변수 로드 (flutter_dotenv 기반, 웹/모바일/데스크톱 호환)
├── openai_client.dart             ← OpenAI Chat Completions API HTTP 클라이언트
├── response_parser.dart           ← LLM 응답 JSON → Course 모델 변환 + 유효성 검증
└── models/
    ├── models.dart                ← 모델 barrel export
    ├── course_request.dart        ← 입력 모델 (fatigueEntries, ownedTools, availableTime)
    ├── fatigue_entry.dart         ← 피로 부위 단위 (BodyFace + BodyPart + level)
    ├── course.dart                ← 출력 모델 (steps, totalDuration, summary)
    ├── course_step.dart           ← 코스 단계 모델 (moveIndex, toolIndex, duration, side, reason)
    └── side.dart                  ← 편측/양측 enum (left, right, both)
```

---

## 파이프라인 흐름

```
CourseRequest (fatigueEntries: [FatigueEntry(face, part, level), ...])
      │
      │  FatigueEntry.bodyIndexes로 해당 구역의 모든 근육 인덱스를 확장
      ▼
┌─────────────┐   조건에 맞는 동작만 추출
│ MoveFilter  │   (보유 도구로 수행 가능 ∩ 피로 부위 해당)
└─────┬───────┘
      │ List<Move> candidates
      ▼
┌──────────────┐   후보 동작 + 조건 → system/user prompt + JSON schema
│ PromptBuilder│
└─────┬────────┘
      │ (system, user, schema)
      ▼
┌──────────────┐   OpenAI Chat Completions API 호출
│ OpenAiClient │   - model: gpt-4o
└─────┬────────┘   - response_format: json_schema (structured output)
      │ Map<String, dynamic> responseJson
      ▼
┌───────────────┐  JSON → Course 변환, 유효성 검증
│ ResponseParser│  (인덱스 존재, 도구 매칭, 시간 범위, 총 시간 초과 등)
└─────┬─────────┘
      │
      ▼
   Course (최종 결과)
```

---

## 사용법

```dart
import 'package:likelion_mid_hackathon/course_generator/course_generator_library.dart';

final generator = CourseGenerator();

final course = await generator.generateCourse(
  CourseRequest(
    fatigueEntries: [
      FatigueEntry(face: BodyFace.back, part: BodyPart.neck, level: 4),      // 뒤-목
      FatigueEntry(face: BodyFace.back, part: BodyPart.shoulder, level: 3),  // 뒤-어깨
      FatigueEntry(face: BodyFace.back, part: BodyPart.waist, level: 5),     // 뒤-허리
    ],
    ownedTools: [11, 7, 2],   // tool index 목록
    availableTime: 1200,      // 초 (20분)
  ),
);

// 결과 접근
print(course.summary);           // 코스 요약 (한국어)
print(course.totalDuration);     // 총 소요 시간 (초)
for (final step in course.steps) {
  print('${step.moveIndex} → ${step.duration}초 (${step.side.label}) | ${step.reason}');
}

generator.dispose();
```

---

## 입력 (CourseRequest)

| 필드 | 타입 | 설명 |
|------|------|------|
| `fatigueEntries` | `List<FatigueEntry>` | 피로 부위 목록. 각 항목은 (BodyFace, BodyPart, 피로도) |
| `ownedTools` | `List<int>` | 보유 도구 인덱스. tool_assets.dart 인덱스 참조 |
| `availableTime` | `int` | 가용 시간 (초 단위) |

### FatigueEntry

| 필드 | 타입 | 설명 |
|------|------|------|
| `face` | `BodyFace` | 앞(front) / 뒤(back) |
| `part` | `BodyPart` | 부위 구역 (neck, shoulder, chest, arm, thigh 등) |
| `level` | `int` | 피로도 (1~5) |
| `bodyIndexes` | `Set<int>` (getter) | 해당 face+part에 속하는 모든 Body 인덱스 (자동 확장) |

## 출력 (Course)

| 필드 | 타입 | 설명 |
|------|------|------|
| `steps` | `List<CourseStep>` | 동작 단계 리스트 (순서대로) |
| `totalDuration` | `int` | 총 소요 시간 (초). 편측 동작은 ×2 반영 |
| `summary` | `String` | 코스 요약 설명 (LLM 생성, 한국어) |

### CourseStep

| 필드 | 타입 | 설명 |
|------|------|------|
| `moveIndex` | `int` | 동작 인덱스 (kMoves 참조) |
| `toolIndex` | `int` | 사용 도구 인덱스 (kTools 참조) |
| `duration` | `int` | 배정 시간 (초, 편측 기준) |
| `side` | `Side` | left / right / both |
| `reason` | `String` | LLM이 이 동작을 선택한 이유 |

---

## 에셋 의존성

이 엔진은 `lib/assets/` 아래의 에셋 데이터에 의존한다:

- **body_assets.dart** — 42개 신체 부위 (인덱스 1~42), BodyFace/BodyPart enum 포함
- **move_assets.dart** — 67개 근막이완 동작 (인덱스 1~67), 각 동작이 부위·도구·자세·시간 범위를 포함
- **tool_assets.dart** — 13개 도구 (인덱스 1~13), 폼롤러/마사지볼/스틱 3종류

---

## 환경 설정

| 항목 | 값 |
|------|------|
| 환경변수 | `OPENAI_API_KEY` (필수, `.env` 파일에 설정) |
| Dart SDK | ^3.10.1 |
| 외부 패키지 | `http: ^1.2.0`, `flutter_dotenv: ^6.0.1` |

`.env` 파일은 `flutter_dotenv`를 통해 앱 assets로 번들링되어 로드된다.
`main.dart`에서 `await EnvLoader.load()`를 호출하면 이후 어디서든 `EnvLoader.get(key)`로 접근 가능.

---

## 예외 처리

| 예외 | 발생 조건 |
|------|-----------|
| `NoCandidatesException` | 조건에 맞는 후보 동작이 0개 |
| `OpenAiException` | API 키 없음, 인증 실패, rate limit, 서버 오류, JSON 파싱 실패 |
| `CourseValidationException` | 응답의 moveIndex/toolIndex가 유효하지 않음 |

---

## 테스트 · 확장

- 모든 컴포넌트는 생성자 주입 가능 → mock 객체로 단위 테스트 가능
- `OpenAiClient`의 `httpClient` 파라미터에 mock client 주입
- `previewCandidates(request)` 로 필터 결과만 미리 확인 가능
- 추후 확장 예정: `floorAvailable` 파라미터 (바닥 사용 가능 여부 필터)
