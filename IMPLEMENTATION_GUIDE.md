# 풀림(PULLIM) - 근막 이완 코스 앱 구현 가이드

---

## 앱 개요

근막 이완 도구(폼롤러/마사지볼)를 활용한 셀프케어 루틴 앱.
사용자의 보유 도구와 자세 분석 데이터를 기반으로 맞춤 이완 코스를 생성하고 실행합니다.

---

## 전체 앱 흐름

```
앱 시작
  → Firebase 초기화 + .env 로드 + 온보딩 상태 확인
  → 로그인 안됨 → Google 로그인 화면
  → 로그인 됨 + 온보딩 미완료 → 온보딩 흐름
      → 서비스 소개 (OnboardingScreen)
      → 도구 등록 (ToolRegistrationScreen)
      → 자세 측정 (PostureGuideScreen → PostureScreen → PostureResultScreen)
      → 홈 화면 (MainShell)
  → 로그인 됨 + 온보딩 완료 → 홈 화면 (MainShell)
```

---

## 프로젝트 구조

```
lib/
├── main.dart                              # 앱 진입점 (Firebase, .env, 온보딩 상태 체크)
│
├── assets/                                # 에셋 데이터 정의 (팀원B 담당)
│   ├── body_assets.dart                   # 신체 부위 에셋 (부위 이름, 좌표, 전면/후면)
│   ├── move_assets.dart                   # 동작 에셋 (이완 동작 정보)
│   └── tool_assets.dart                   # 도구 에셋 (인덱스 1~12, 카테고리/형태/이미지 경로)
│
├── constants/                             # 상수 정의
│   ├── app_colors.dart                    # 색상 팔레트 (검정 배경 + 연두 액센트 #CDFF00)
│   ├── app_strings.dart                   # 한글 문자열 상수
│   └── app_theme.dart                     # 다크 테마 설정 (ThemeData)
│
├── course_generator/                      # AI 코스 생성 모듈 (팀원B 담당)
│   ├── course_generator.dart              # 코스 생성 메인 로직
│   ├── course_generator_library.dart      # 라이브러리 export
│   ├── env_loader.dart                    # .env 파일 로더 (API 키)
│   ├── move_filter.dart                   # 동작 필터링
│   ├── openai_client.dart                 # OpenAI API 클라이언트
│   ├── prompt_builder.dart                # 프롬프트 빌더
│   ├── response_parser.dart               # AI 응답 파서
│   └── models/                            # 코스 생성용 모델
│       ├── course.dart
│       ├── course_request.dart
│       ├── course_step.dart
│       ├── fatigue_entry.dart
│       └── models.dart
│
├── models/                                # 데이터 모델 (ERD 기반)
│   ├── user_model.dart                    # 사용자 (user_id, name, email, created_at)
│   ├── tool_model.dart                    # 도구 + OwnedTool (DB용, 카테고리/형태 enum)
│   ├── course_model.dart                  # 코스 (name, total_time, status, progress)
│   ├── step_model.dart                    # 코스 스텝 (order, before/after 피로도, time)
│   ├── move_model.dart                    # 동작 (body, tool, name, description)
│   ├── body_model.dart                    # 신체 부위 (전면/후면 좌표 포함)
│   └── posture_result_model.dart          # 자세 측정 결과 (angles, issues, score)
│
├── providers/                             # 상태 관리
│   └── app_provider.dart                  # 로그인 상태, 네비게이션 인덱스, 사용자 정보
│
├── screens/                               # 화면
│   ├── main_shell.dart                    # BottomNavigationBar (홈/라이브러리/마이페이지)
│   ├── onboarding_screen.dart             # 온보딩: 서비스 소개 + 이용 흐름 + 주의사항
│   ├── tool_registration_screen.dart      # 온보딩: 도구 등록 + 온보딩 자세측정 래퍼
│   ├── body_selection_screen.dart         # 코스 생성: 부위 선택 (팀원B 담당)
│   │
│   ├── auth/
│   │   └── login_screen.dart              # Google 로그인 화면
│   │
│   ├── home/
│   │   ├── home_screen.dart               # 홈: PULLIM 로고 + 주간 캘린더 + 연속운동
│   │   │                                  #      + 최근 운동 + 코스생성/점검기반 카드
│   │   ├── service_intro_screen.dart      # 서비스 소개 상세
│   │   └── caution_screen.dart            # 주의사항/면책 상세
│   │
│   ├── library/
│   │   ├── library_screen.dart            # 라이브러리: 저장된 코스 목록 + 시작하기
│   │   └── library_all_screen.dart        # 이력 전체 보기
│   │
│   ├── mypage/
│   │   ├── mypage_screen.dart             # 마이페이지: 통계 + 보유 도구(이미지) + 최근 기록
│   │   └── owned_tools_screen.dart        # 보유 도구 전체 보기
│   │
│   └── posture/
│       ├── posture_guide_screen.dart      # 촬영 가이드 ("내 몸을 먼저 확인할게요")
│       ├── posture_screen.dart            # 카메라 촬영 (정면→측면, 자동촬영, TTS 음성안내)
│       └── posture_result_screen.dart     # 결과: 사진+스켈레톤, 정면/측면 탭, 점수, 항목별 분석
│
├── services/                              # 비즈니스 로직 / 데이터 레이어
│   ├── auth_service.dart                  # Google Sign-In + Firebase Auth
│   ├── database_helper.dart               # SQLite DB (sqflite) - 전체 CRUD
│   ├── pose_analyzer.dart                 # ML Kit 포즈 분석 (각도 계산, 문제 감지, 점수)
│   └── tool_registration_service.dart     # 도구 등록 (SharedPreferences + SQLite 이중 저장)
│
└── widgets/                               # 공통 위젯
    └── common_widgets.dart                # SectionCard, NumberBadge, CourseItemCard,
                                           # ToolCard, StatCard
```

---

## 담당 분배

| 담당자 | 기능 |
|--------|------|
| 나 | 홈페이지, 라이브러리, 마이페이지, 자세 측정, 로컬 DB, Google 로그인, 온보딩 통합 |
| 팀원B | 도구 등록 UI, 코스 생성(AI), 부위 선택, 코스 실행, 에셋 데이터 |

---

## 로컬 DB 구조 (SQLite)

### 테이블

| 테이블 | 용도 |
|--------|------|
| `users` | 사용자 (user_id, name, email, created_at) |
| `tools` | 사전 정의 도구 11종 - 앱 최초 실행 시 자동 삽입 |
| `owned_tools` | 사용자 보유 도구 (user_id ↔ tool_id) |
| `courses` | 생성/실행된 코스 (name, total_time, status, progress) |
| `steps` | 코스 내 각 단계 (move_id, tool_id, order, before/after 피로도) |
| `moves` | 동작 에셋 10종 - 앱 최초 실행 시 자동 삽입 |
| `posture_results` | 자세 측정 결과 (angles, issues, summary, score) |

### 데이터 흐름

```
온보딩 도구 등록 → SharedPreferences (인덱스) + SQLite owned_tools
자세 측정 완료 → SQLite posture_results (score, angles, issues 저장)
코스 실행 완료 → SQLite courses + steps (피로도 전/후 기록)
마이페이지 → SQLite에서 통계 쿼리 (총 실행, 완료율, 평균 피로도 감소)
홈 화면 → SQLite에서 최근 코스 조회
라이브러리 → SQLite에서 저장/완료된 코스 조회
보유 도구 → SharedPreferences에서 인덱스 → tool_assets로 이미지/이름 매핑
```

---

## 자세 측정 기능 상세

### 흐름
```
촬영 가이드 화면 (posture_guide_screen.dart)
  → "촬영 시작하기" 버튼
카메라 촬영 화면 (posture_screen.dart)
  → 정면 촬영 (자동: 프레임 감지 → 안정 → 3초 카운트다운 → 촬영)
  → 4초 전환 대기 + 음성 안내 ("옆으로 돌아서 주세요")
  → 측면 촬영 (동일 로직)
  → DB 저장 → 결과 화면 이동
결과 화면 (posture_result_screen.dart)
  → 사진 + 스켈레톤 오버레이
  → 정면/측면 탭 전환
  → 전체 자세 점수 (100점 만점)
  → 항목별 분석 카드 (수치 + 정상/주의 뱃지 + 설명)
  → "코스 시작하기" 버튼
```

### 핵심 기술
- **Google ML Kit Pose Detection**: 실시간 포즈 감지 (스트림 모드)
- **자동 촬영**: 전신 감지 + 프레임 안에 위치 + 15프레임 안정 → 3초 카운트다운
- **TTS 음성 안내** (`flutter_tts`): 위치 가이드, 촬영 카운트다운, 단계 전환 음성
- **분석 항목**:
  - 정면: 어깨 높이 차이, 골반 기울기, 몸통 기울기, 머리 기울기, 머리 좌우 편위, 좌/우 무릎 정렬
  - 측면: 거북목 각도, 머리 전방 이동량, 어깨 전방활주, 몸통 전후 기울기

### 주요 플래그 (중복 촬영 방지)
- `_frontCaptured`: 정면 촬영 완료 플래그
- `_sideCaptured`: 측면 촬영 완료 플래그
- `_waitingForPhaseTransition`: 정면→측면 전환 대기 중 (4초)
- `_countingDown`: 카운트다운 진행 중
- `_isCapturing`: 사진 촬영 처리 중

---

## 홈 화면

- **PULLIM** 로고
- **주간 캘린더**: `DateTime.now()` 기반, 일요일 시작, 오늘 연두색 강조
- **연속 운동 N일차**: 총 실행 횟수 기반
- **최근 운동**: DB에서 최근 완료 코스 1건
- **코스 생성하기** (연두 카드): → 부위 선택 화면 (팀원B)
- **점검 기반 코스** (다크 카드): → 자세 측정 가이드 화면

---

## 라이브러리

- **저장된 코스 목록**: `courses` 테이블에서 `save = 1` 조회
- **코스 선택 시**: 테두리 강조 + "시작하기" 버튼 표시
- **이력 전체 보기**: 모든 완료 코스 스크롤 목록

---

## 마이페이지

- **사용자 이름** (Provider에서 가져옴)
- **자세 점검하기** 버튼 → 촬영 가이드 화면
- **통계 3종** (DB 쿼리):
  - 총 실행 횟수: `SELECT COUNT(*) FROM courses WHERE status = 'completed'`
  - 완료율: 완료 / 전체 코스 비율
  - 평균 피로도 감소: `AVG(before_fatigue - after_fatigue)`
- **보유 도구**: SharedPreferences 인덱스 → tool_assets 이미지 표시
- **최근 기록**: DB에서 최근 3건

---

## 사용된 패키지

| 패키지 | 용도 |
|--------|------|
| `firebase_core` / `firebase_auth` | Firebase 초기화, 인증 |
| `google_sign_in` | Google 로그인 |
| `google_mlkit_pose_detection` | 자세 측정 (포즈 감지) |
| `camera` | 카메라 프리뷰 + 이미지 스트림 + 사진 촬영 |
| `sqflite` + `path` | 로컬 SQLite DB |
| `provider` | 상태 관리 |
| `shared_preferences` | 로그인 유지, 온보딩 상태, 보유 도구 인덱스 |
| `permission_handler` | 카메라 권한 요청 |
| `flutter_tts` | 자세 측정 음성 안내 |
| `intl` | 날짜 포맷 |
| `http` | OpenAI API 호출 (팀원B) |
| `flutter_dotenv` | .env 환경변수 로드 (팀원B) |

---

## 디자인 스펙

- **배경**: #000000 (순수 검정)
- **카드 배경**: #1E1E1E
- **Surface**: #1A1A1A
- **액센트**: #CDFF00 (연두/라임)
- **텍스트**: 흰색 → #B0B0B0 (보조) → #808080 (3차)
- **BottomNavigationBar**: 3탭 (홈 / 라이브러리 / 마이페이지)
- **버튼**: 연두 배경 + 검정 텍스트, 높이 56px, radius 12

---

## 빌드 참고

- `minSdk = 23` (ML Kit 요구사항)
- `AndroidManifest.xml`: CAMERA + INTERNET 권한 설정됨
- `google-services.json`: Firebase Console에서 다운 → `android/app/`에 위치해야 함
- 에뮬레이터 시간대: 한국(서울)으로 설정해야 날짜 정확
