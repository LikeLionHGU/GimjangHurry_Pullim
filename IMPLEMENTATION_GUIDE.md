# 풀림 - 근막 이완 코스 앱 구현 가이드

## 내가 담당한 기능

| 기능 | 상태 | 설명 |
|------|------|------|
| 홈페이지 | 완료 | 서비스 소개, 이용 흐름, 주의사항 |
| 라이브러리 | 완료 | 저장된 코스 목록, 이력 전체 보기 |
| 마이페이지 | 완료 | 통계, 보유 도구, 최근 기록, 도구 추가 |
| 자세 측정 | 완료 | Google ML Kit Pose Detection 연동 |
| 로컬 DB | 완료 | sqflite 기반 전체 테이블 |
| Google 로그인 | 완료 | Firebase Auth + Google Sign-In |

---

## 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점 (Firebase 초기화, Provider 설정)
│
├── constants/                         # 상수 정의
│   ├── app_colors.dart                # 색상 (검정 배경 + 연두 액센트)
│   ├── app_theme.dart                 # 다크 테마 설정
│   └── app_strings.dart               # 한글 문자열 상수
│
├── models/                            # 데이터 모델 (ERD 기반)
│   ├── user_model.dart                # 사용자
│   ├── tool_model.dart                # 도구 (폼롤러/마사지볼) + OwnedTool
│   ├── course_model.dart              # 코스
│   ├── step_model.dart                # 코스 스텝
│   ├── move_model.dart                # 동작 (에셋)
│   ├── body_model.dart                # 신체 부위 (전면/후면 좌표 포함)
│   └── posture_result_model.dart      # 자세 측정 결과
│
├── services/                          # 비즈니스 로직
│   ├── database_helper.dart           # 로컬 DB (sqflite) 전체 CRUD
│   ├── auth_service.dart              # Google 로그인 처리
│   └── pose_analyzer.dart             # ML Kit 포즈 분석 (각도 계산, 문제 감지)
│
├── providers/                         # 상태 관리
│   └── app_provider.dart              # 로그인 상태, 네비게이션 인덱스
│
├── widgets/                           # 공통 위젯
│   └── common_widgets.dart            # SectionCard, CourseItemCard, ToolCard, StatCard 등
│
└── screens/                           # 화면
    ├── main_shell.dart                # BottomNavigationBar (홈/라이브러리/마이페이지)
    ├── auth/
    │   └── login_screen.dart          # 구글 로그인 화면
    ├── home/
    │   ├── home_screen.dart           # 홈 화면 (이용 흐름, 주의사항, 면책)
    │   ├── service_intro_screen.dart  # 서비스 소개 상세 + 주의사항 상세
    │   └── caution_screen.dart        # (export 파일)
    ├── library/
    │   ├── library_screen.dart        # 저장된 코스 목록
    │   └── library_all_screen.dart    # 이력 전체 보기
    ├── mypage/
    │   ├── mypage_screen.dart         # 마이페이지 (통계, 도구, 기록, 도구추가 바텀시트)
    │   └── owned_tools_screen.dart    # 보유 도구 전체 보기
    └── posture/
        ├── posture_screen.dart        # 카메라 + ML Kit 자세 측정
        └── posture_result_screen.dart # 측정 결과 화면
```

---

## 앱 흐름

```
앱 시작
  → 스플래시 (로딩)
  → 로그인 안됨? → LoginScreen (구글 로그인)
  → 로그인 됨? → MainShell
                    ├── 홈 탭: 서비스 소개, 이용 흐름, 주의사항
                    ├── 라이브러리 탭: 저장된 코스 목록, 시작하기
                    └── 마이페이지 탭: 통계, 보유 도구, 자세 점검하기
                                          └── PostureScreen (카메라 + ML Kit)
                                              └── PostureResultScreen (결과)
```

---

## 로컬 DB 테이블 구성

| 테이블 | 용도 |
|--------|------|
| users | 사용자 정보 (user_id, name, email, created_at) |
| tools | 사전 정의 도구 11종 (폼롤러 6 + 마사지볼 5) |
| owned_tools | 사용자가 보유한 도구 (user_id ↔ tool_id) |
| courses | 생성/실행된 코스 |
| steps | 코스 내 각 단계 (도구, 동작, 시간, 피로도 전/후) |
| moves | 동작 에셋 10종 (이완 방법 설명 포함) |
| posture_results | 자세 측정 결과 (각도, 문제부위, 요약) |

앱 최초 실행 시 `tools` 테이블에 11종, `moves` 테이블에 10종 기본 데이터가 자동 삽입됩니다.

---

## 자세 측정 동작 방식

1. 카메라 권한 요청 → 전면 카메라 열기
2. "자세 측정 시작" 버튼 누르면 카메라 스트림 시작
3. ML Kit PoseDetector가 각 프레임에서 포즈 감지
4. PoseAnalyzer가 관절 각도 계산 (어깨, 팔꿈치, 고관절, 무릎, 기울기)
5. 10프레임 누적 후 평균 각도 산출
6. 각도 기준으로 문제 부위 감지 (어깨 비대칭, 무릎 구부러짐 등)
7. 결과를 DB에 저장하고 결과 화면으로 이동

---

## 다른 팀원이 연결할 부분 (TODO)

코드에 `// TODO` 주석으로 표시해놓음:

| 위치 | 연결할 기능 |
|------|-------------|
| `service_intro_screen.dart` "도구 등록하고 시작하기" 버튼 | 온보딩 → 도구 등록 화면 |
| `library_screen.dart` "시작하기" 버튼 | 코스 실행 화면 |
| `library_all_screen.dart` 코스 아이템 onTap | 코스 재실행 또는 상세 |
| `posture_result_screen.dart` "맞춤 코스 생성하기" 버튼 | 자세 기반 코스 생성 |

---

## 빌드 전 필요한 설정

### 1. Windows Developer Mode 활성화
```
설정 → 개발자 설정 → 개발자 모드 ON
```

### 2. Firebase 설정
- Firebase Console에서 프로젝트 생성
- Android: `android/app/google-services.json` 추가
- iOS: `ios/Runner/GoogleService-Info.plist` 추가
- `flutterfire configure` 실행하거나 수동 설정

### 3. Android 카메라 권한
`android/app/src/main/AndroidManifest.xml`에 추가:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### 4. Android minSdkVersion
`android/app/build.gradle.kts`에서:
```kotlin
minSdk = 23  // ML Kit 최소 요구사항
```

### 5. 패키지 설치
```bash
flutter pub get
```

---

## 사용된 주요 패키지

| 패키지 | 용도 |
|--------|------|
| firebase_core / firebase_auth | Firebase 초기화, 인증 |
| google_sign_in | 구글 로그인 |
| google_mlkit_pose_detection | 자세 측정 (포즈 감지) |
| camera | 카메라 프리뷰 + 이미지 스트림 |
| sqflite | 로컬 SQLite DB |
| provider | 상태 관리 |
| shared_preferences | 로그인 상태 유지 |
| permission_handler | 카메라 권한 요청 |
| intl | 날짜/시간 포맷 |

---

## 디자인 특징

- **다크 테마** 전체 적용 (배경: #000000)
- **액센트 색상**: 연두/라임 (#CDFF00) - GUI 디자인 그대로
- **카드 배경**: #1E1E1E
- **BottomNavigationBar**: 홈 / 라이브러리 / 마이페이지 3탭
- GUI에서 보이는 둥근 카드, 번호 뱃지, 도구 그리드 등 공통 위젯으로 구현
