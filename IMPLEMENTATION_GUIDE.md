# 풀림(PULLIM) - 근막 이완 코스 앱 구현 가이드

---

## 앱 개요

근막 이완 도구(폼롤러/마사지볼)를 활용한 셀프케어 루틴 앱.
사용자의 보유 도구와 자세 분석 데이터를 기반으로 맞춤 이완 코스를 생성하고 실행합니다.

---

## 전체 앱 흐름

```
앱 시작
  → 스플래시 (PULLIM 로고, 2초)
  → DB에 사용자 있음 → 홈 화면 (MainShell)
  → DB에 사용자 없음 → 온보딩 흐름
      1. 이름 입력 ("환영합니다")
      2. 서비스 소개 (이용 흐름 + 주의사항 + 면책)
      3. 서비스 소개 상세 → "도구 등록하고 시작하기"
      4. 도구 등록 (폼롤러/마사지볼/스틱 선택)
      5. 자세 측정 안내 → 자세 촬영 → 결과
      6. 홈 화면 (MainShell)
```

---

## 프로젝트 구조

```
lib/
├── main.dart                              # 앱 진입점 (스플래시 → 온보딩 or 홈)
│
├── assets/                                # 에셋 데이터 정의 (팀원B)
│   ├── body_assets.dart                   # 신체 부위 (좌표, 전면/후면)
│   ├── move_assets.dart                   # 동작 에셋 (이완 동작 정보)
│   └── tool_assets.dart                   # 도구 에셋 (1~12번, 이미지 경로)
│
├── constants/                             # 상수
│   ├── app_colors.dart                    # 색상 팔레트 (#000 배경 + #CDFF00 액센트)
│   ├── app_strings.dart                   # 한글 문자열
│   ├── app_theme.dart                     # 다크 테마
│   └── app_typography.dart                # 폰트 스타일 (팀원B)
│
├── course_generator/                      # AI 코스 생성 모듈 (팀원B)
│   ├── course_generator.dart
│   ├── course_generator_library.dart
│   ├── env_loader.dart                    # .env API 키 로드
│   ├── move_filter.dart
│   ├── openai_client.dart
│   ├── prompt_builder.dart
│   ├── response_parser.dart
│   └── models/
│       ├── course.dart
│       ├── course_request.dart
│       ├── course_step.dart
│       ├── fatigue_entry.dart
│       └── models.dart
│
├── models/                                # 데이터 모델 (ERD 기반)
│   ├── user_model.dart                    # 사용자 (user_id, name, email)
│   ├── course_model.dart                  # 코스 (name, time, status, before/after, summary)
│   ├── step_model.dart                    # 코스 스텝 (moveId, toolId, order, time)
│   └── posture_result_model.dart          # 자세 측정 결과 (angles, issues, score)
│
├── providers/
│   └── app_provider.dart                  # 사용자 상태, 네비게이션 인덱스
│
├── screens/
│   ├── main_shell.dart                    # BottomNavigationBar (홈/라이브러리/마이페이지)
│   │
│   ├── onboard/
│   │   ├── onboarding_screen.dart         # 이름 입력 + 서비스 소개
│   │   └── tool_registration_screen.dart  # 도구 등록 + 자세측정 래퍼
│   │
│   ├── home/
│   │   ├── home_screen.dart               # 홈: 캘린더 + 연속운동 + 최근운동 + 액션카드
│   │   ├── recent_history_screen.dart     # 최근 운동 내역 전체
│   │   ├── service_intro_screen.dart      # 서비스 소개 상세 + 주의사항
│   │   └── caution_screen.dart
│   │
│   ├── library/
│   │   ├── library_screen.dart            # 저장된 코스 목록 + 시작하기
│   │   └── library_all_screen.dart        # 저장된 코스 전체 보기
│   │
│   ├── mypage/
│   │   ├── mypage_screen.dart             # 통계 + 보유도구 + 최근기록
│   │   ├── owned_tools_screen.dart        # 보유 도구 전체 + 추가 버튼
│   │   └── add_tool_screen.dart           # 도구 추가 (온보딩과 분리)
│   │
│   ├── posture/
│   │   ├── posture_guide_screen.dart      # 촬영 가이드 (자동촬영 설명 포함)
│   │   ├── posture_screen.dart            # 카메라 촬영 (자동촬영 + TTS)
│   │   └── posture_result_screen.dart     # 결과 (사진+스켈레톤, 탭, 점수, 카드)
│   │
│   └── course/                            # (팀원B)
│       ├── course_generation_screen.dart  # 코스 생성 (부위선택+AI)
│       ├── course_result_screen.dart      # 코스 결과
│       ├── course_execution_screen.dart   # 코스 실행 (타이머)
│       └── course_complete_screen.dart    # 코스 완료 (피로도 재입력)
│
├── services/
│   ├── database_helper.dart               # SQLite 전체 CRUD + 통계
│   ├── tool_registration_service.dart     # 도구 등록 (SharedPrefs + SQLite)
│   ├── course_loader.dart                 # DB 코스 → Course 객체 복원 + 복제
│   ├── course_mapper.dart                 # Course ↔ CourseModel 변환 (팀원B)
│   ├── pose_analyzer.dart                 # ML Kit 포즈 분석 (각도, 점수)
│   └── posture_to_release_service.dart    # 자세→코스 연결 (팀원B)
│
└── widgets/
    └── common_widgets.dart                # SectionCard, NumberBadge, CourseItemCard 등
```

---

## 마이페이지 통계 기준

### 총 실행 횟수

```sql
SELECT COUNT(*) FROM courses WHERE status = 'completed'
```

- **기준**: `courses` 테이블에서 `status = 'completed'`인 **모든 row의 개수**
- 같은 코스를 여러 번 실행하면 매번 새 row가 INSERT됨 (duplicateForReplay)
- 따라서 중복 코스라도 각 실행마다 +1

### 완료율

```sql
완료율 = (status='completed' 코스 수) / (전체 코스 수) × 100
```

- **기준**: 생성된 모든 코스(pending/running/completed/cancelled) 중 완료된 비율
- 코스 생성만 하고 실행 안 하면 분모만 늘어나서 완료율 감소

### 평균 피로도 감소

```
각 완료 코스의 courses.before (JSON) - courses.after (JSON) 값을 부위별로 계산
→ 전체 부위 차이의 합계 / 부위 수
```

- **기준**: 완료된 코스의 `before` (운동 전 피로도)와 `after` (운동 후 피로도) JSON 데이터
- `before`/`after`는 `{"front_shoulder": 7, "back_calf": 5, ...}` 형태
- 각 부위별로 `before - after` 계산 → 양수면 피로도 감소
- 모든 완료 코스의 모든 부위를 합산하여 평균

### 연속 운동 일수

```dart
오늘부터 과거로 연속으로 운동한 고유 날짜를 카운트
- 오늘 운동 안 했으면 어제부터 체크
- 하루에 여러 번 운동해도 1일로만 카운트
```

- **기준**: 완료된 코스의 `executed_at` 날짜를 고유 날짜 Set으로 변환
- 오늘 → 어제 → 그제... 연속으로 존재하는 날짜 수

---

## 홈 화면 캘린더

- `DateTime.now()` 기준 주간 표시 (일요일 시작)
- 좌우 화살표로 ±7일 이동 가능
- **운동한 날짜**: 완료된 코스의 `executed_at`에서 날짜 추출 → 연두색 배경
- **오늘**: 진한 연두색 배경
- **그 외**: 기본 회색 배경

---

## 자세 측정 기능

### 흐름
```
촬영 가이드 (posture_guide_screen.dart)
  - 촬영 안내 3가지
  - "가이드 위치에 맞게 서면 자동으로 촬영됩니다" 안내
  - "촬영 시작하기" 버튼
      ↓
카메라 촬영 (posture_screen.dart)
  - 정면 → 측면 순서
  - 머리 원형 + 몸통 사각형 + 발 원형 가이드
  - 감지 안 됨: 주황색 / 감지됨: 연두색
  - 자동 촬영: 프레임 안 + 15프레임 안정 → 3초 카운트다운 → 촬영
  - TTS 음성 안내 (위치 가이드, 카운트다운, 단계 전환)
      ↓
결과 화면 (posture_result_screen.dart)
  - 사진 + 스켈레톤(점+선) 오버레이
  - 정면/측면 탭 전환
  - 전체 자세 점수 (100점 만점, 원형 표시)
  - 항목별 분석 카드 (수치 + 정상/주의 뱃지 + 설명)
  - "코스 시작하기" 버튼 → 홈으로 이동
```

### 분석 항목
| 정면 | 측면 |
|------|------|
| 어깨 높이 차이 | 거북목(두개척추각) |
| 골반 기울기 | 머리 전방 이동량 |
| 몸통 기울기 | 어깨 전방활주 |
| 머리 기울기 | 몸통 전후 기울기 |
| 머리 좌우 편위 | |
| 왼쪽 무릎 정렬 | |
| 오른쪽 무릎 정렬 | |

### TTS 음성 안내 목록
- "정면 촬영을 시작합니다. 화면 중앙의 프레임 안에 전신이 들어오도록 서 주세요"
- "화면 중앙 프레임 안으로 들어와 주세요"
- "조금 왼쪽/오른쪽으로 이동해주세요"
- "카메라를 조금 위로/아래로 올려주세요"
- "뒤로 물러나 주세요" / "앞으로 다가와 주세요"
- "자세가 좋습니다. 3초 후 촬영합니다"
- "촬영합니다"
- "정면 촬영 완료. 이제 옆으로 돌아서 프레임 안에 서 주세요"
- "촬영 완료. 자세를 분석합니다"

---

## 코스 재실행 로직

저장된 코스나 최근 기록에서 코스를 다시 실행할 때:
1. `CourseLoader.duplicateForReplay(courseId)` → 기존 코스를 복제해서 **새 row INSERT** (pending 상태)
2. 새 courseId로 `CourseExecutionScreen` 실행
3. 완료 시 `course_complete_screen`에서 새 row의 status를 `completed`로 업데이트
4. → 총 실행 횟수 증가, 최근 기록에 새 항목 추가

---

## 로컬 DB 구조 (SQLite)

### 테이블

| 테이블 | 용도 |
|--------|------|
| `users` | 사용자 (user_id, name, email, created_at) |
| `tools` | 사전 정의 도구 11종 (앱 최초 실행 시 삽입) |
| `owned_tools` | 사용자 보유 도구 (user_id ↔ tool_id) |
| `courses` | 코스 (name, total_time, total_move, summary, before, after, status, progress, executed_at) |
| `steps` | 코스 스텝 (course_id, move_id, tool_id, order, reason, time) |
| `moves` | 동작 에셋 10종 (앱 최초 실행 시 삽입) |
| `posture_results` | 자세 측정 결과 (angles, issues, summary, score) |

### 데이터 흐름

```
온보딩 도구 등록 → SharedPreferences (인덱스) + SQLite owned_tools
자세 측정 완료 → SQLite posture_results (score, angles, issues 저장)
코스 생성 → SQLite courses (pending) + steps
코스 완료 → SQLite courses (completed, after 피로도, executed_at)
코스 재실행 → 기존 코스 복제 INSERT → 새 courseId로 실행
마이페이지 → 통계 쿼리 (총실행, 완료율, 피로도감소)
홈 캘린더 → executed_at 기반 운동 날짜 Set 생성
보유 도구 → SharedPreferences 인덱스 → tool_assets 이미지 매핑
```

---

## 사용 패키지

| 패키지 | 용도 |
|--------|------|
| `google_mlkit_pose_detection` | 자세 측정 (실시간 포즈 감지) |
| `camera` | 카메라 프리뷰 + 스트림 + 촬영 |
| `sqflite` + `path` | 로컬 SQLite DB |
| `provider` | 상태 관리 |
| `shared_preferences` | 사용자 ID, 온보딩 상태, 보유 도구 인덱스 |
| `permission_handler` | 카메라 권한 |
| `flutter_tts` | 자세 측정 음성 안내 |
| `intl` | 날짜 포맷 |
| `http` | OpenAI API (팀원B) |
| `flutter_dotenv` | .env 환경변수 (팀원B) |

---

## 디자인 스펙

- **배경**: #000000
- **카드**: #1E1E1E
- **Surface**: #1A1A1A
- **액센트**: #CDFF00 (연두)
- **텍스트**: 흰 → #B0B0B0 → #808080
- **BottomNav**: 3탭 (홈/라이브러리/마이페이지)
- **버튼**: 연두 배경 + 검정 텍스트, 56px, radius 12
- **자세 가이드**: 감지 안 됨=#FF6B3D(주황), 감지됨=#CDFF00(연두)

---

## 빌드 참고

- `minSdk = 23` (ML Kit 요구사항)
- Firebase 미사용 (순수 로컬 앱)
- `AndroidManifest.xml`: CAMERA + INTERNET 권한
- 앱 삭제 후 재설치: DB 스키마 변경 시 필요
- 에뮬레이터 시간대: 서울로 설정해야 날짜 정확
