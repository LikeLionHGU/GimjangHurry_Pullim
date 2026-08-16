/// move_assets.dart
///
/// 동작(move) 에셋. 총 67개.
/// 인덱스(1~67)로 조회한다.
///
///   final move = kMoves[38]!;                 // 대둔근 Figure-4 압박
///   final bodies = bodiesOf(move.body);       // body_assets.dart
///   final tools  = toolsOf(move.tool);        // tool_assets.dart
///
/// body / tool 은 각각 body_assets.dart, tool_assets.dart 의 인덱스를 참조한다.
/// tool 목록의 첫 번째 인덱스가 원본 DB의 기본(권장) 도구이며,
/// 나머지는 대체 가능 도구다. 안전상 사용이 금지된 도구는 제외되어 있다.
/// time 은 편측 기준 권장 수행 시간의 (min, max) 범위이며 단위는 초.
library move_assets;

/// 동작을 수행하는 시작 자세.
/// 코스 구성 시 자세 전환 횟수를 줄이는 정렬 기준으로 쓴다.
enum Posture {
  supine('눕기'),
  prone('엎드리기'),
  sideLying('옆으로 눕기'),
  seatedFloor('바닥 앉기'),
  seatedChair('의자 앉기'),
  standing('서기'),
  standingWall('서기(벽)'),
  quadruped('네발기기');

  const Posture(this.label);
  final String label;

  /// 바닥에 눕거나 엎드리는 자세인지. 사무실·외출 중에는 제외하는 데 쓴다.
  bool get needsFloor =>
      this == supine || this == prone || this == sideLying ||
      this == seatedFloor || this == quadruped;
}

/// 동작 한 개.
class Move {
  const Move({
    required this.index,
    required this.name,
    required this.posture,
    required this.body,
    required this.tool,
    required this.description,
    required this.time,
  });

  /// 조회용 인덱스.
  final int index;

  /// 동작 이름. 도구 이름은 포함하지 않는다.
  final String name;

  /// 시작 자세.
  final Posture posture;

  /// 해당되는 부위 인덱스들.
  final List<int> body;

  /// 사용 가능한 도구 인덱스들. 첫 번째가 기본 권장 도구.
  final List<int> tool;

  /// 자세·방법·유의사항 설명. 줄바꿈으로 구분된 3~5줄.
  final String description;

  /// 권장 수행 시간 범위(초, 편측 기준).
  /// min 은 시간이 부족할 때 줄일 수 있는 하한, max 는 여유가 있을 때의 상한.
  final ({int min, int max}) time;

  /// 설명을 줄 단위 리스트로.
  List<String> get descriptionLines => description.split('\n');

  /// 기본 배정 시간(초). 코스 편성의 시작값으로 쓴다.
  int get defaultTime => (time.min + time.max) ~/ 2;
}

/// 인덱스 → 동작.
const Map<int, Move> kMoves = <int, Move>{
  // ───── 뒷목·뒤통수 ─────
  1: Move(
    index: 1,
    name: '후두하근 누워 지속 압박',
    posture: Posture.supine,
    body: [23],
    tool: [11, 10, 5],
    description: '바로 누워 무릎을 세우고 발바닥을 바닥에 붙인다.\n'
        '도구의 홈이 목뼈 중앙을 비우도록 뒤통수뼈 아래 좌우 오목에 놓는다.\n'
        '턱을 살짝 당긴 채 머리 무게만 싣고 그 이상 밀지 않는다.\n'
        '4초 들이쉬고 8초 내쉬며 호기마다 턱을 미세하게 더 당긴다.\n'
        '어지럼·복시·삼킴 곤란이 느껴지면 즉시 중단한다.',
    time: (min: 90, max: 180),
  ),
  2: Move(
    index: 2,
    name: '후두하근 앉아 릴리스',
    posture: Posture.seatedChair,
    body: [23],
    tool: [10, 11],
    description: '의자에 앉아 등을 등받이에 붙이고 턱을 살짝 당긴다.\n'
        '도구의 돌기를 뒤통수뼈 아래 모서리 좌우에 걸고 양손으로 앞·아래로 당긴다.\n'
        '어깨는 으쓱하지 말고 내린 상태를 유지한다.\n'
        '좌우 2cm 범위로 호를 그리듯 아주 짧게 움직인다.\n'
        '손 힘이라 과압하기 쉬우니 의식적으로 약하게 당긴다.',
    time: (min: 60, max: 90),
  ),
  3: Move(
    index: 3,
    name: '견갑거근 상각 벽 홀드',
    posture: Posture.standingWall,
    body: [24],
    tool: [7, 9, 10, 11],
    description: '벽에 등을 대고 서서 압박측 팔로 반대쪽 어깨를 감싼다.\n'
        '어깨뼈 위 모서리 안쪽에 도구를 건다.\n'
        '무릎을 굽혔다 펴며 3~5cm 위아래로 움직여 압력을 조절한다.\n'
        '목 옆 깊은 곳은 신경이 지나므로 강하게 누르지 않는다.',
    time: (min: 60, max: 90),
  ),

  // ───── 목 옆면 ─────
  4: Move(
    index: 4,
    name: '흉쇄유돌근 핀서 릴리스',
    posture: Posture.seatedChair,
    body: [1],
    tool: [10],
    description: '앉거나 누워 고개를 압박할 쪽으로 살짝 기울여 근육을 느슨하게 만든다.\n'
        '엄지와 검지로 목 옆 근육 띠를 집어 살짝 들어올린다. 누르지 않는다.\n'
        '귀 뒤에서 중간, 쇄골 위 순서로 3~4곳을 10~20초씩 옮긴다.\n'
        '맥박이 느껴지면 즉시 손을 뒤쪽으로 옮기고 양쪽을 동시에 잡지 않는다.',
    time: (min: 45, max: 60),
  ),
  5: Move(
    index: 5,
    name: '측경부 스윕',
    posture: Posture.seatedChair,
    body: [1, 24],
    tool: [10],
    description: '앉아서 등을 세우고 어깨를 내린다.\n'
        '목 옆 뒤쪽 1/3 라인에 도구를 얹고 고개를 반대쪽으로 살짝 기울인다.\n'
        '3cm 이내로 아주 짧게 위아래로 쓸어내린다.\n'
        '쇄골 바로 위 오목한 삼각 구역은 건너뛴다. 약하게 하는 것이 안전의 조건이다.',
    time: (min: 30, max: 45),
  ),

  // ───── 어깨 위쪽 ─────
  6: Move(
    index: 6,
    name: '상부승모근 후크 홀드',
    posture: Posture.seatedChair,
    body: [25],
    tool: [10, 12, 7],
    description: '앉거나 서서 목을 압박 반대쪽으로 기울여 근육을 늘린다.\n'
        '도구를 어깨 위에 걸치고 반대손으로 아래로 당긴다.\n'
        '가장 아픈 지점에서 30초 머문 뒤 5~8cm 범위로 짧게 움직인다.\n'
        '어깨를 으쓱하지 않고 한 지점을 2분 넘게 누르지 않는다.',
    time: (min: 60, max: 90),
  ),
  7: Move(
    index: 7,
    name: '상부승모근 벽 압박',
    posture: Posture.standingWall,
    body: [25],
    tool: [10, 9, 7],
    description: '벽 모서리에 어깨 윗면을 대고 서서 도구가 굴러 떨어지지 않게 한다.\n'
        '어깨 위 두툼한 부분에 도구를 놓고 몸을 벽 쪽으로 기울여 압력을 만든다.\n'
        '압박측 팔은 아래로 늘어뜨려 힘을 뺀다.\n'
        '발을 벽에서 멀리 둘수록 압력이 커진다. 쇄골 위 오목으로 들어가지 않게 한다.',
    time: (min: 45, max: 60),
  ),
  8: Move(
    index: 8,
    name: '상부승모근 시티드 롤링',
    posture: Posture.seatedChair,
    body: [25],
    tool: [12, 10],
    description: '의자에 앉아 등을 세우고 어깨를 내린다.\n'
        '반대손으로 도구를 잡아 목 옆에서 어깨 끝 방향으로 얹는다.\n'
        '목을 반대쪽으로 살짝 기울이고 한 방향으로만 길게 쓸어낸다.\n'
        '되돌아올 때는 압력을 뺀다. 팔꿈치를 몸에 붙여 손 힘이 과해지지 않게 한다.',
    time: (min: 45, max: 60),
  ),

  // ───── 어깨 측면·후면 ─────
  9: Move(
    index: 9,
    name: '후면삼각근 벽 롤링',
    posture: Posture.standingWall,
    body: [26],
    tool: [7, 9, 5, 10, 1],
    description: '벽에 어깨 뒤를 대고 서고 익숙해지면 옆으로 누워 강도를 높인다.\n'
        '압박측 팔로 반대쪽 어깨를 감싸면 근육이 앞으로 밀려 나온다.\n'
        '어깨 뒤 가로 뼈 능선 바로 아래에 도구를 놓는다.\n'
        '위아래로 굴린 뒤 짧게 좌우로도 문지른다. 뼈 위와 겨드랑이 중앙은 피한다.',
    time: (min: 60, max: 90),
  ),
  10: Move(
    index: 10,
    name: '중간삼각근 측와위 롤링',
    posture: Posture.sideLying,
    body: [2],
    tool: [5, 12, 9, 10, 1],
    description: '옆으로 누워 압박측 팔을 머리 위로 뻗고 힘을 뺀다.\n'
        '어깨 맨 위 뼈에서 2~3cm 아래부터 도구를 어깨 바깥면에 놓는다.\n'
        '어깨 바깥에서 팔 중간까지 길게 위아래로 굴린다.\n'
        '뼈 위를 직접 누르지 않고 팔을 벌려 안쪽으로 돌린 자세는 피한다.',
    time: (min: 45, max: 60),
  ),
  11: Move(
    index: 11,
    name: '극하근 벽 홀드 & 회전',
    posture: Posture.standingWall,
    body: [27],
    tool: [7, 9, 10, 11, 5],
    description: '벽에 등을 대고 서서 어깨뼈 뒷면 오목한 곳에 도구를 놓는다.\n'
        '압박측 팔로 반대쪽 어깨를 감싸면 근육이 최대로 노출된다.\n'
        '무릎 굽힘 정도로 압력을 조절하며 30초 이상 머문다.\n'
        '압박을 유지한 채 팔을 바깥으로 천천히 돌린다. 어깨뼈 뼈 위는 누르지 않는다.',
    time: (min: 60, max: 90),
  ),
  12: Move(
    index: 12,
    name: '소원근 크로스바디 릴리스',
    posture: Posture.supine,
    body: [28],
    tool: [9, 10, 7],
    description: '벽에 기대 어깨뼈 바깥 모서리 위쪽에 도구를 놓고 약하게 압박한다.\n'
        '이어서 바로 누워 팔을 90° 들고 반대손으로 몸 쪽으로 당긴다.\n'
        '어깨뼈가 바닥에서 뜨지 않게 고정하는 것이 핵심이다.\n'
        '통증 없이 당김만 느껴지는 강도로 하고 관절낭을 강하게 누르지 않는다.',
    time: (min: 60, max: 90),
  ),

  // ───── 날개뼈 사이 ─────
  13: Move(
    index: 13,
    name: '능형근 견갑 내측 홀드',
    posture: Posture.supine,
    body: [29],
    tool: [7, 11, 9, 10, 2],
    description: '바로 누워 무릎을 세우고 양팔을 가슴 앞에서 교차한다.\n'
        '어깨뼈가 벌어지며 안쪽 모서리가 열린다.\n'
        '안쪽 모서리에서 안으로 1~2cm 지점에 도구를 놓는다.\n'
        '짧게 위아래로 움직이며 30초 머문다. 척추 가운데 돌기는 누르지 않는다.',
    time: (min: 60, max: 90),
  ),
  14: Move(
    index: 14,
    name: '중부승모근 흉추 롤링',
    posture: Posture.supine,
    body: [30],
    tool: [2, 1, 11, 7],
    description: '폼롤러를 가로로 놓고 등 윗부분을 얹어 눕는다.\n'
        '무릎을 세우고 양팔을 가슴 앞에서 교차하거나 머리 뒤를 받친다.\n'
        '엉덩이를 살짝 들면 압력이 커지고 내리면 작아진다.\n'
        '어깨뼈 위쪽부터 아래쪽까지만 굴리고 허리까지 내려가지 않는다.',
    time: (min: 60, max: 90),
  ),
  15: Move(
    index: 15,
    name: '견갑 사이 분절 압박',
    posture: Posture.supine,
    body: [29, 30],
    tool: [11, 6, 7, 10],
    description: '바로 누워 무릎을 세우고 손으로 머리를 받친다.\n'
        '도구의 홈이 척추 돌기를 비우도록 좌우 근육에 걸친다.\n'
        '한 분절에 자리를 잡고 30초 정지한 뒤 위아래로 한 칸씩 이동한다.\n'
        '3~4곳을 옮겨가며 진행하고 한 지점에 3분 이상 머물지 않는다.',
    time: (min: 90, max: 120),
  ),

  // ───── 등 넓은 부위 ─────
  16: Move(
    index: 16,
    name: '광배근 측와위 롱 롤링',
    posture: Posture.sideLying,
    body: [32],
    tool: [2, 1, 7, 9, 5],
    description: '옆으로 누워 압박측 팔을 머리 위로 뻗고 엄지를 천장 쪽으로 돌린다.\n'
        '겨드랑이 바로 아래에 도구를 놓고 무릎을 굽혀 몸을 안정시킨다.\n'
        '겨드랑이에서 골반 옆까지 길게 굴린다.\n'
        '몸통을 앞뒤로 15° 굴려 각도를 바꾼다. 겨드랑이 중앙은 압박하지 않는다.',
    time: (min: 60, max: 90),
  ),
  17: Move(
    index: 17,
    name: '대원근 후액와 홀드',
    posture: Posture.sideLying,
    body: [31],
    tool: [7, 9, 5, 10, 1, 2],
    description: '옆으로 누워 압박측 팔을 머리 위로 뻗는다.\n'
        '겨드랑이 뒤 두꺼운 띠의 위쪽 절반에 도구를 놓는다.\n'
        '어깨뼈 아래 모서리 바깥쪽을 기준점으로 삼는다.\n'
        '30초 정지 압박 후 짧게 좌우로 문지른다. 도구가 겨드랑이 중앙으로 미끄러지지 않게 한다.',
    time: (min: 45, max: 60),
  ),
  18: Move(
    index: 18,
    name: '광배근 벽 만세 릴리스',
    posture: Posture.standingWall,
    body: [32, 31],
    tool: [9, 10, 7],
    description: '벽 모서리에 옆구리 위쪽을 대고 선다.\n'
        '겨드랑이 뒤쪽에 도구를 놓고 발 위치로 압력을 조절한다.\n'
        '압박측 팔을 벽을 따라 만세 방향으로 10회 올렸다 내린다.\n'
        '조직이 도구 위를 지나가게 하고 허리를 젖혀 보상하지 않는다.',
    time: (min: 45, max: 60),
  ),

  // ───── 척추·허리 주변 ─────
  19: Move(
    index: 19,
    name: '척추기립근 분절 압박',
    posture: Posture.supine,
    body: [35],
    tool: [11, 6, 2, 7],
    description: '바로 누워 무릎을 세우고 발바닥을 바닥에 붙인다. 요추 보호의 핵심이다.\n'
        '도구의 홈이 척추 돌기를 비우도록 좌우 근육 기둥에 걸친다.\n'
        '골반을 살짝 뒤로 기울여 허리를 바닥 쪽에 붙인다.\n'
        '한 지점에 30초씩 머물며 한두 분절씩 이동한다. 허리 구간은 굴리지 않는다.',
    time: (min: 90, max: 120),
  ),
  20: Move(
    index: 20,
    name: '흉추 신전 롤링',
    posture: Posture.supine,
    body: [35, 30],
    tool: [2, 1, 11, 4],
    description: '폼롤러를 가로로 두고 등 윗부분을 얹어 눕는다.\n'
        '무릎을 세우고 손으로 머리 뒤를 받쳐 목을 지지한다.\n'
        '배에 약간 힘을 유지한 채 허리가 아니라 등만 뒤로 젖힌다.\n'
        '각 분절에서 멈춰 신전을 반복한다. 롤러가 허리까지 내려가지 않게 한다.',
    time: (min: 60, max: 90),
  ),
  21: Move(
    index: 21,
    name: '요방형근 45° 압박',
    posture: Posture.supine,
    body: [36],
    tool: [7, 9, 6, 10],
    description: '바로 누워 무릎을 세우고 몸을 45° 옆으로 기울인다.\n'
        '갈비뼈 아래와 골반뼈 위 사이, 척추에서 바깥으로 4~6cm 지점에 도구를 놓는다.\n'
        '압박측 팔을 만세로 뻗으면 근육이 늘어나 접근이 쉬워진다.\n'
        '3~5cm 범위로만 짧게 움직인다. 갈비뼈 바로 아래 깊은 곳은 찌르지 않는다.',
    time: (min: 60, max: 90),
  ),
  22: Move(
    index: 22,
    name: '요추 양측 지속 압박',
    posture: Posture.supine,
    body: [35],
    tool: [6, 11, 10],
    description: '바로 누워 무릎을 세우고 발바닥을 바닥에 붙인다.\n'
        '도구의 홈이 척추 돌기를 비우도록 허리뼈 양옆 근육 기둥에 놓는다.\n'
        '골반을 살짝 뒤로 기울이고 손은 배 위에 얹어 호흡을 확인한다.\n'
        '굴리지 않고 45~60초씩 2~3곳으로 위치만 옮긴다. 허리는 낮은 압력이 원칙이다.',
    time: (min: 90, max: 120),
  ),

  // ───── 가슴 앞쪽 ─────
  23: Move(
    index: 23,
    name: '대흉근 문틀 릴리스',
    posture: Posture.standingWall,
    body: [3],
    tool: [7, 9, 10, 5],
    description: '서서 문틀이나 벽 모서리에 도구를 대고 기댄다.\n'
        '압박측 팔을 몸에서 45~90° 벌린다.\n'
        '쇄골 아래 2~3cm 또는 겨드랑이 앞 두꺼운 띠에 도구를 놓는다.\n'
        '쇄골 아래를 따라 좌우로 굴리고 발 위치로 체중을 조절한다. 겨드랑이 중앙은 피한다.',
    time: (min: 60, max: 90),
  ),
  24: Move(
    index: 24,
    name: '소흉근 오구돌기 하방 홀드',
    posture: Posture.standingWall,
    body: [4],
    tool: [10, 9, 7],
    description: '서서 벽 모서리에 도구를 대고 기대며 압박측 팔은 아래로 늘어뜨린다.\n'
        '쇄골 바깥 1/3 아래의 단단한 뼈를 찾은 뒤 거기서 아래·안쪽 3~5cm에 도구를 놓는다.\n'
        '20~30초 정지 압박하며 근섬유 방향으로만 아주 짧게 이동한다.\n'
        '저림이 오면 즉시 위치를 바꾼다. 신경 통로가 인접한 부위다.',
    time: (min: 45, max: 60),
  ),
  25: Move(
    index: 25,
    name: '세로 흉곽 개방',
    posture: Posture.supine,
    body: [3, 4],
    tool: [1, 4, 2],
    description: '폼롤러를 세로로 두고 꼬리뼈부터 머리까지 척추 전체를 얹어 눕는다.\n'
        '무릎을 세우고 발을 어깨너비로 벌려 균형을 잡는다.\n'
        '팔을 T자로 벌려 손등이 바닥을 향하게 늘어뜨리고 60초 유지한다.\n'
        '이어서 W자, Y자로 팔 위치만 바꾼다. 허리를 젖혀 보상하지 않는다.',
    time: (min: 120, max: 180),
  ),

  // ───── 겨드랑이 밑 갈비뼈 ─────
  26: Move(
    index: 26,
    name: '전거근 측와위 사선 롤링',
    posture: Posture.sideLying,
    body: [5],
    tool: [1, 5, 2, 10],
    description: '옆으로 누워 압박측 팔을 머리 위로 뻗는다.\n'
        '겨드랑이 아래 갈비뼈 바깥면에 도구를 놓는다.\n'
        '무릎을 굽혀 안정시키고 위쪽 손으로 바닥을 짚어 압력을 조절한다.\n'
        '갈비뼈 결을 따라 사선으로 천천히 움직인다. 호흡을 멈추지 않는다.',
    time: (min: 45, max: 60),
  ),
  27: Move(
    index: 27,
    name: '전거근 늑골 압박 & 3D 호흡',
    posture: Posture.sideLying,
    body: [5],
    tool: [9, 10, 7, 8],
    description: '옆으로 누워 압박측 팔을 만세로 뻗는다.\n'
        '겨드랑이 아래 4~6번 갈비뼈 바깥면에 도구를 놓는다.\n'
        '체중을 거의 싣지 않은 상태에서 시작해 조금씩 늘린다.\n'
        '갈비뼈 하나씩 위치를 옮기며 20~30초 정지하고 옆구리가 부풀도록 호흡한다.',
    time: (min: 60, max: 90),
  ),

  // ───── 복부·옆구리 ─────
  28: Move(
    index: 28,
    name: '복직근 호흡 압박',
    posture: Posture.prone,
    body: [6],
    tool: [10, 5, 9],
    description: '엎드려 누워 갈비뼈 아래 또는 복근 바깥 경계에 도구를 둔다.\n'
        '팔꿈치로 상체 무게를 지탱해 체중을 거의 싣지 않은 상태로 시작한다.\n'
        '무릎을 굽히면 배가 더 이완된다.\n'
        '굴리지 않고 3~4곳을 30~45초씩 옮긴다. 배꼽 주변 정중선과 식후 시행은 피한다.',
    time: (min: 90, max: 120),
  ),
  29: Move(
    index: 29,
    name: '복사근 측와위 롤링',
    posture: Posture.sideLying,
    body: [7],
    tool: [1, 10, 9, 5],
    description: '옆으로 눕거나 45° 기울여 엎드린다.\n'
        '갈비뼈 아래부터 골반 위까지 옆구리 바깥면에 도구를 놓는다. 정면 배가 아니다.\n'
        '압박측 팔은 만세, 무릎은 굽혀 몸을 지지한다.\n'
        '갈비뼈 사선 방향을 따라 천천히 움직이며 호흡을 유지한다.',
    time: (min: 45, max: 60),
  ),
  30: Move(
    index: 30,
    name: '옆구리 벽 측방 호흡',
    posture: Posture.standingWall,
    body: [7],
    tool: [10, 9, 8],
    description: '벽 모서리에 옆구리를 대고 선다.\n'
        '갈비뼈 아래쪽 옆면에 도구를 놓는다.\n'
        '압박측 팔을 만세로 들어 옆구리를 늘린다.\n'
        '2~3곳을 20~30초씩 옮긴다. 발을 벽에서 멀리 둘수록 압력이 커진다.',
    time: (min: 45, max: 60),
  ),

  // ───── 위팔 ─────
  31: Move(
    index: 31,
    name: '이두근 책상 압박',
    posture: Posture.seatedChair,
    body: [8],
    tool: [5, 12, 9, 10, 1, 2],
    description: '의자에 앉아 팔을 책상 위 도구에 올린다.\n'
        '팔꿈치를 살짝 굽혀 근육의 힘을 뺀다.\n'
        '상체를 앞으로 기울여 팔 무게와 상체 무게로 압력을 만든다.\n'
        '어깨에서 팔꿈치 방향으로 굴리고 손바닥을 번갈아 돌려 각도를 바꾼다.\n'
        '팔 안쪽 깊은 고랑에는 도구가 닿지 않게 한다.',
    time: (min: 45, max: 60),
  ),
  32: Move(
    index: 32,
    name: '삼두근 만세 측와위 롤링',
    posture: Posture.sideLying,
    body: [33],
    tool: [5, 12, 7, 9, 1, 2],
    description: '옆으로 누워 압박측 팔을 머리 위로 뻗는다.\n'
        '팔 뒤쪽 아래에 도구를 놓고 반대손으로 바닥을 짚어 체중을 조절한다.\n'
        '겨드랑이 뒤에서 팔꿈치 방향으로 굴린다.\n'
        '팔을 안팎으로 돌려 각도를 바꾼다. 팔꿈치 안쪽 뒤 찌릿한 뼈는 피한다.',
    time: (min: 45, max: 60),
  ),
  33: Move(
    index: 33,
    name: '상완근 외측 압박',
    posture: Posture.seatedChair,
    body: [9],
    tool: [7, 9, 5, 12],
    description: '앉아서 팔을 책상 위 도구에 올린다.\n'
        '팔꿈치를 살짝 굽히고 손등이 위로 오게 돌린다.\n'
        '팔꿈치 주름에서 위로 3~7cm, 이두근 바깥 경계 바로 옆에 도구를 둔다.\n'
        '20~30초씩 두 번 정지 압박한다. 팔꿈치 앞 오목에는 닿지 않게 한다.',
    time: (min: 30, max: 45),
  ),
  34: Move(
    index: 34,
    name: '위팔 양방향 롤링',
    posture: Posture.seatedChair,
    body: [8, 33],
    tool: [12, 5],
    description: '의자에 앉아 팔을 몸 앞에 두고 팔꿈치를 살짝 굽힌다.\n'
        '반대손으로 도구를 잡고 위팔 앞면부터 감싸듯 얹는다.\n'
        '앞면을 8~10회 왕복한 뒤 뒷면으로 옮겨 같은 횟수를 반복한다.\n'
        '팔에 힘을 완전히 빼야 효과가 있다. 팔 안쪽 면과 관절 위는 건너뛴다.',
    time: (min: 45, max: 60),
  ),

  // ───── 아랫팔 ─────
  35: Move(
    index: 35,
    name: '전완굴근 롤링',
    posture: Posture.seatedChair,
    body: [10],
    tool: [12, 8, 9, 5],
    description: '앉아서 팔꿈치를 책상에 두고 손바닥이 위로 오게 한다.\n'
        '반대손으로 도구를 잡고 팔뚝 안쪽을 누른다.\n'
        '손목 힘을 완전히 빼고 팔꿈치에서 손목 방향으로 굴린다.\n'
        '결의 직각 방향으로도 짧게 문지른다. 팔꿈치 안쪽 뼈와 손목 주름은 건너뛴다.',
    time: (min: 45, max: 60),
  ),
  36: Move(
    index: 36,
    name: '전완신근 롤링',
    posture: Posture.seatedChair,
    body: [34],
    tool: [12, 9, 8, 7],
    description: '앉아서 팔을 책상에 두고 손등이 위로 오게 한다.\n'
        '반대손으로 도구를 잡고 팔뚝 바깥면을 누른다.\n'
        '팔꿈치 바깥 뼈에서 손목 방향 2~6cm가 핵심 구역이다.\n'
        '급성 통증기에는 부착부를 피하고 근육 중간만 처치한다.',
    time: (min: 45, max: 60),
  ),
  37: Move(
    index: 37,
    name: '전완 책상 원형 압박',
    posture: Posture.seatedChair,
    body: [10, 34],
    tool: [8, 9, 10, 12],
    description: '책상 위에 도구를 놓는다.\n'
        '전완 또는 손바닥을 얹고 상체 무게를 살짝 싣는다.\n'
        '어깨를 내리고 팔에 힘을 뺀 채 원을 그리듯 움직인다.\n'
        '전완 30초, 손바닥 30초로 나눠 진행한다. 손목 주름 위는 직접 누르지 않는다.',
    time: (min: 45, max: 60),
  ),

  // ───── 엉덩이 뒤쪽 ─────
  38: Move(
    index: 38,
    name: '대둔근 Figure-4 압박',
    posture: Posture.seatedFloor,
    body: [37],
    tool: [7, 9, 2, 10, 3],
    description: '바닥에 앉아 도구 위에 한쪽 엉덩이를 얹는다.\n'
        '같은쪽 발목을 반대쪽 무릎 위에 올려 숫자 4 모양을 만든다.\n'
        '손으로 뒤를 짚어 체중을 조절하고 위아래·좌우로 천천히 굴린다.\n'
        '몸통을 좌우 30° 돌려 각도를 바꾼다. 앉는 뼈 위는 직접 누르지 않는다.',
    time: (min: 60, max: 90),
  ),
  39: Move(
    index: 39,
    name: '대둔근 광범위 롤링',
    posture: Posture.seatedFloor,
    body: [37],
    tool: [2, 1, 3, 5],
    description: '바닥에 앉아 폼롤러를 엉덩이 아래 가로로 놓는다.\n'
        '양손으로 뒤를 짚고 두 다리를 굽혀 발을 바닥에 둔다.\n'
        '양쪽 동시로 시작하고 강도를 높이려면 한쪽 발목을 반대 무릎에 올린다.\n'
        '몸통을 좌우로 기울여 부위를 바꾼다. 앉는 뼈 위에서는 멈추지 않는다.',
    time: (min: 60, max: 90),
  ),
  40: Move(
    index: 40,
    name: '이상근 Figure-4 지속 압박',
    posture: Posture.seatedFloor,
    body: [38],
    tool: [7, 9, 10, 2],
    description: '바닥에 앉아 허리 뒤 딤플과 고관절 옆 뼈를 잇는 선의 중간에 도구를 놓는다.\n'
        '같은쪽 발목을 반대쪽 무릎 위에 올리면 근육이 표면으로 나온다.\n'
        '손으로 뒤를 짚어 체중을 조절하고 굴리지 않고 30~60초 머문다.\n'
        '다리로 뻗치는 전기 같은 통증이 나오면 도구를 1~2cm 바깥으로 옮긴다.',
    time: (min: 60, max: 90),
  ),
  41: Move(
    index: 41,
    name: '천골 외측 부착부 압박',
    posture: Posture.supine,
    body: [37],
    tool: [11, 10, 9, 6],
    description: '바로 누워 무릎을 세운다.\n'
        '도구의 홈이 엉치뼈 가운데를 비우도록 좌우 부착부에 걸친다.\n'
        '한 위치에서 30~45초 머문 뒤 옆으로 이동한다.\n'
        '숨을 내쉴 때 체중을 도구 쪽으로 옮긴다. 엉치뼈 정중앙은 직접 누르지 않는다.',
    time: (min: 60, max: 90),
  ),

  // ───── 골반 옆쪽 ─────
  42: Move(
    index: 42,
    name: '중둔근 측와위 압박',
    posture: Posture.sideLying,
    body: [11],
    tool: [7, 9, 2, 1, 10],
    description: '옆으로 눕고 골반뼈 능선 아래 2~5cm에 도구를 놓는다.\n'
        '아래쪽 다리는 뻗고 위쪽 다리는 굽혀 앞 바닥을 짚는다. 압력 조절의 핵심이다.\n'
        '팔꿈치로 상체를 지탱하며 짧게 위아래로 움직인다.\n'
        '몸통을 뒤로 15~30° 굴려 뒤쪽 섬유까지 접근한다. 고관절 옆 뼈는 피한다.',
    time: (min: 45, max: 60),
  ),
  43: Move(
    index: 43,
    name: '대퇴근막장근 45° 엎드림 압박',
    posture: Posture.prone,
    body: [13],
    tool: [7, 9, 1, 2, 5],
    description: '엎드려 몸을 45° 기울인다. 정면과 측면 사이 각도다.\n'
        '골반 앞쪽 뼈에서 아래·바깥 3~5cm 지점에 도구를 놓는다.\n'
        '압박측 다리는 뻗고 반대쪽 다리는 굽혀 앞에 두어 압력을 조절한다.\n'
        '3~5cm 범위로 짧게 움직이며 고관절을 안팎으로 돌린다. 골반 앞뼈는 누르지 않는다.',
    time: (min: 45, max: 60),
  ),
  44: Move(
    index: 44,
    name: '소둔근 전방경사 심부 압박',
    posture: Posture.sideLying,
    body: [12],
    tool: [9, 7, 10],
    description: '옆으로 눕되 몸통을 앞으로 20~30° 기울인다.\n'
        '고관절 옆 뼈의 앞·위쪽 3~4cm 지점에 도구를 놓는다.\n'
        '위쪽 다리는 앞 바닥을 짚어 압력을 조절한다.\n'
        '굴리지 않고 30~60초 정지 압박한다. 다리로 뻗치는 통증이 있으면 즉시 위치를 바꾼다.',
    time: (min: 60, max: 90),
  ),

  // ───── 허벅지 앞쪽 ─────
  45: Move(
    index: 45,
    name: '대퇴사두근 프론 롤링',
    posture: Posture.prone,
    body: [14],
    tool: [2, 1, 3, 12, 7],
    description: '엎드려 팔꿈치로 상체를 받친다.\n'
        '허벅지 앞에 도구를 가로로 놓는다.\n'
        '반대쪽 다리를 옆으로 굽혀 바닥에 두면 압력이 줄어든다.\n'
        '골반 앞에서 무릎 위 5cm까지 길게 굴린다. 허리가 젖혀지지 않게 배에 힘을 유지한다.',
    time: (min: 60, max: 90),
  ),
  46: Move(
    index: 46,
    name: '대퇴직근 시티드 롤링',
    posture: Posture.seatedChair,
    body: [15],
    tool: [12, 5, 9],
    description: '의자 끝에 앉아 압박측 다리를 앞으로 뻗고 뒤꿈치를 바닥에 댄다.\n'
        '무릎을 살짝 굽혀 근육의 힘을 뺀다.\n'
        '양손으로 도구를 잡고 허벅지 앞면에 얹는다.\n'
        '안쪽·가운데·바깥쪽 3열로 나누어 골반에서 무릎 위까지 굴린다. 무릎 관절 위는 지나지 않는다.',
    time: (min: 45, max: 60),
  ),
  47: Move(
    index: 47,
    name: '원위 사두 국소 압박',
    posture: Posture.prone,
    body: [14],
    tool: [7, 9, 5, 10],
    description: '엎드려 팔꿈치로 상체를 지탱한다.\n'
        '무릎뼈 위 5~10cm 지점에 도구를 놓는다.\n'
        '30초 머문 뒤 무릎을 굽혔다 펴며 조직이 도구 위를 지나가게 한다.\n'
        '좌우로만 짧게 이동한다. 무릎뼈와 그 아래 힘줄 위에는 절대 두지 않는다.',
    time: (min: 45, max: 60),
  ),
  48: Move(
    index: 48,
    name: '내측광근 개구리 롤링',
    posture: Posture.prone,
    body: [16],
    tool: [5, 12, 2, 9, 10],
    description: '엎드려 압박측 다리를 옆으로 90° 벌린다.\n'
        '허벅지 안쪽 아래에 도구를 놓는다.\n'
        '목표는 무릎뼈 안쪽 위 5~10cm 구간이다.\n'
        '짧게 위아래와 사선으로 움직인다. 무릎 안쪽 관절선까지 내려가지 않는다.',
    time: (min: 45, max: 60),
  ),

  // ───── 허벅지 뒤쪽 ─────
  49: Move(
    index: 49,
    name: '햄스트링 바닥 롤링',
    posture: Posture.seatedFloor,
    body: [39],
    tool: [2, 1, 3, 12, 7],
    description: '바닥에 앉아 도구 위에 허벅지 뒤를 얹고 손으로 바닥을 짚어 엉덩이를 든다.\n'
        '반대쪽 다리를 바닥에 내리면 압력이 약해지고 두 다리를 겹치면 강해진다.\n'
        '앉는 뼈 아래에서 무릎 위 5cm까지 굴린다.\n'
        '다리를 안팎으로 돌려 안쪽·바깥쪽 라인을 나눈다. 무릎 뒤 오목은 피한다.',
    time: (min: 60, max: 90),
  ),
  50: Move(
    index: 50,
    name: '근위 햄스트링 의자 압박',
    posture: Posture.seatedChair,
    body: [39],
    tool: [7, 9, 10],
    description: '단단한 의자에 앉는다.\n'
        '앉는 뼈에서 아래로 3~5cm, 허벅지 뒤 근육 부분에 도구를 놓는다.\n'
        '같은쪽 발목을 반대 무릎에 올리면 접근이 쉬워진다.\n'
        '상체를 앞으로 기울여 압력을 조절하며 30~45초 머문다. 저림이 뻗치면 즉시 이동한다.',
    time: (min: 60, max: 90),
  ),
  51: Move(
    index: 51,
    name: '햄스트링 의자 롤링',
    posture: Posture.seatedChair,
    body: [39],
    tool: [12, 5],
    description: '의자에 앉아 압박측 발을 앞쪽 바닥이나 낮은 발판에 둔다.\n'
        '무릎을 약 120°로 굽혀 근육의 힘을 뺀다.\n'
        '양손으로 도구를 잡고 허벅지 뒤에 감듯이 얹는다.\n'
        '안쪽·바깥쪽 2열로 나누어 엉덩이 아래에서 무릎 위까지 굴린다. 무릎 뒤 오목은 건너뛴다.',
    time: (min: 45, max: 60),
  ),

  // ───── 허벅지 안쪽 ─────
  52: Move(
    index: 52,
    name: '내전근 개구리 롤링',
    posture: Posture.prone,
    body: [18],
    tool: [1, 2, 5, 9],
    description: '엎드려 압박측 다리를 옆으로 90° 벌린다.\n'
        '허벅지 안쪽 아래에 도구를 대각선으로 놓는다.\n'
        '팔꿈치로 상체를 지지하고 치골에서 최소 5cm 아래부터 시작한다.\n'
        '근섬유 각도에 맞춰 사선으로 길게 굴린다. 처음부터 강한 압력은 멍이 생기기 쉽다.',
    time: (min: 60, max: 90),
  ),
  53: Move(
    index: 53,
    name: '내전근 근위부 압박',
    posture: Posture.prone,
    body: [18],
    tool: [9, 10, 7],
    description: '엎드려 압박측 다리를 옆으로 90° 벌린다.\n'
        '치골에서 아래로 5cm 지점, 허벅지 안쪽 근육 위에 도구를 놓는다.\n'
        '팔꿈치로 상체를 지탱해 체중을 거의 싣지 않고 시작한다.\n'
        '2~3곳을 20~30초씩 옮긴다. 맥박이 느껴지면 즉시 바깥·아래로 이동한다.',
    time: (min: 45, max: 60),
  ),
  54: Move(
    index: 54,
    name: '내전근 시티드 롤링',
    posture: Posture.seatedChair,
    body: [18],
    tool: [12, 5],
    description: '의자에 앉아 압박측 다리를 바깥으로 벌리고 무릎을 굽힌다.\n'
        '발바닥은 바닥에 붙이고 무릎을 옆으로 열어둔다.\n'
        '도구를 허벅지 안쪽 면에 얹고 양손으로 잡는다.\n'
        '허벅지 중간에서 무릎 위까지 굴린다. 사타구니 방향으로 너무 올라가지 않는다.',
    time: (min: 45, max: 60),
  ),

  // ───── 허벅지 바깥쪽 ─────
  55: Move(
    index: 55,
    name: '외측광근 30° 측와위 롤링',
    posture: Posture.sideLying,
    body: [17],
    tool: [2, 1, 12, 7, 9],
    description: '옆으로 눕되 몸을 앞으로 30° 기울인다.\n'
        '완전히 옆으로 누우면 인대와 뼈만 눌려 통증만 커진다.\n'
        '위쪽 다리를 앞 바닥에 짚어 체중을 조절한다.\n'
        '고관절 옆 뼈 아래 5cm에서 무릎 위 5cm 사이를 길게 굴린다.',
    time: (min: 60, max: 90),
  ),
  56: Move(
    index: 56,
    name: '외측광근 심부 롤링',
    posture: Posture.sideLying,
    body: [17],
    tool: [3, 2, 7],
    description: '옆으로 눕고 몸을 앞으로 30° 기울인다.\n'
        '위쪽 다리를 앞에 짚어 체중의 50~70%만 싣는다.\n'
        '압력이 점으로 집중되므로 처음부터 전 체중을 싣지 않는다.\n'
        '10cm씩 구간을 나누어 진행하고 무릎 바깥 관절선 5cm 위에서 멈춘다.',
    time: (min: 45, max: 60),
  ),
  57: Move(
    index: 57,
    name: '원위 외측광근 국소 압박',
    posture: Posture.sideLying,
    body: [17],
    tool: [5, 9, 10, 12],
    description: '옆으로 누워 몸을 앞으로 30° 기울인다.\n'
        '무릎뼈 바깥 위 5~10cm 구간에만 도구를 놓는다.\n'
        '반대쪽 다리를 앞에 짚어 압력을 조절한다.\n'
        '5cm 범위로 짧게 움직이며 무릎을 굽혔다 편다. 무릎 바깥 관절선에는 닿지 않게 한다.',
    time: (min: 45, max: 60),
  ),

  // ───── 종아리 뒤쪽 ─────
  58: Move(
    index: 58,
    name: '비복근 의자 롤링',
    posture: Posture.seatedChair,
    body: [40],
    tool: [12, 2, 1, 7],
    description: '의자에 앉아 압박측 발을 앞으로 두고 무릎을 살짝 굽힌다.\n'
        '양손으로 도구를 잡고 종아리 뒤에 얹는다.\n'
        '발목 힘을 완전히 빼고 무릎 아래에서 발목 위까지 굴린다.\n'
        '발목을 안팎으로 돌려 안쪽·바깥쪽을 구분한다. 무릎 뒤 오목에서 5cm 아래부터 시작한다.',
    time: (min: 60, max: 90),
  ),
  59: Move(
    index: 59,
    name: '비복근 바닥 롤링',
    posture: Posture.seatedFloor,
    body: [40],
    tool: [2, 1, 3, 5],
    description: '바닥에 앉아 도구 위에 종아리를 얹고 손으로 바닥을 짚어 엉덩이를 든다.\n'
        '반대쪽 다리를 바닥에 두면 압력이 약해지고 겹쳐 올리면 강해진다.\n'
        '발목 힘을 빼고 무릎 아래 5cm에서 발목 위 5cm까지 굴린다.\n'
        '다리를 안팎으로 돌려 세 면을 모두 처리한다. 처음부터 두 다리를 겹치지 않는다.',
    time: (min: 60, max: 90),
  ),
  60: Move(
    index: 60,
    name: '가자미근 무릎굴곡 압박',
    posture: Posture.seatedFloor,
    body: [41],
    tool: [7, 9, 12, 5],
    description: '바닥에 앉아 무릎을 30~45° 굽힌다. 겉근육이 느슨해지며 심부가 드러난다.\n'
        '종아리 아래 1/3 지점에 도구를 놓는다.\n'
        '반대쪽 다리로 압력을 조절하며 30~45초 머문다.\n'
        '발목을 안팎으로 돌려 각도를 바꾼다. 종아리 깊은 정중선은 강하게 누르지 않는다.',
    time: (min: 45, max: 60),
  ),
  61: Move(
    index: 61,
    name: '아킬레스 이행부 압박',
    posture: Posture.seatedFloor,
    body: [42],
    tool: [11, 10, 9, 12],
    description: '바닥에 앉아 무릎을 살짝 굽힌다.\n'
        '도구의 홈이 아킬레스건 자체를 비우도록 좌우 가장자리에 걸친다.\n'
        '반대쪽 다리로 압력을 조절하고 발목 힘을 뺀다.\n'
        '발목 위 5~12cm 구간을 2~3곳으로 나눠 20~30초씩 머문다. 건 위 강압박은 금물이다.',
    time: (min: 45, max: 60),
  ),

  // ───── 정강이 앞/옆 ─────
  62: Move(
    index: 62,
    name: '전경골근 시티드 롤링',
    posture: Posture.seatedChair,
    body: [19],
    tool: [12, 5, 9],
    description: '의자에 앉아 다리를 반대 무릎 위에 올린다.\n'
        '정강이 뼈 바깥 1~2cm 근육 위에 도구를 얹는다.\n'
        '발목 힘을 빼고 무릎 아래 5cm에서 발목 위까지 굴린다.\n'
        '발목을 위아래로 움직이며 병행한다. 정강이 앞 뼈 능선은 절대 누르지 않는다.',
    time: (min: 45, max: 60),
  ),
  63: Move(
    index: 63,
    name: '전경골근 네발기기 롤링',
    posture: Posture.quadruped,
    body: [19],
    tool: [1, 2, 5],
    description: '네발기기 자세를 만든다.\n'
        '정강이 아래에 도구를 가로로 놓고 다리를 살짝 안쪽으로 돌려 바깥 근육이 닿게 한다.\n'
        '손으로 체중을 나눠 실어 압력을 조절한다.\n'
        '앞뒤로 몸을 움직여 무릎 아래에서 발목 위까지 굴린다. 무릎이 아프면 쿠션을 깐다.',
    time: (min: 45, max: 60),
  ),
  64: Move(
    index: 64,
    name: '비골근 측와위 롤링',
    posture: Posture.sideLying,
    body: [20],
    tool: [5, 7, 9, 12],
    description: '옆으로 누워 종아리 바깥면 아래에 도구를 놓는다.\n'
        '무릎 바깥 아래 튀어나온 뼈에서 최소 5cm 아래부터 시작한다.\n'
        '위쪽 다리를 앞에 짚어 압력을 조절한다.\n'
        '바깥 복사뼈 위까지 위아래로 굴린다. 발등이 저리면 즉시 아래쪽으로 옮긴다.',
    time: (min: 45, max: 60),
  ),

  // ───── 발바닥 ─────
  65: Move(
    index: 65,
    name: '족저근막 롤링 & 윈들라스',
    posture: Posture.seatedChair,
    body: [21],
    tool: [9, 8, 10, 7],
    description: '의자에 앉아 도구를 발바닥 아래에 두고 시작한다.\n'
        '익숙해지면 서서 체중을 늘리고 반대발로 바닥을 지지한다.\n'
        '뒤꿈치 안쪽 앞 1~2cm부터 아치 전체까지 세로로 굴린다.\n'
        '마지막에 발가락을 들어 아치를 팽팽하게 만든 뒤 다시 굴린다.\n'
        '뒤꿈치 뼈 위는 강하게 누르지 않는다.',
    time: (min: 60, max: 90),
  ),
  66: Move(
    index: 66,
    name: '발 내재근 원형 압박',
    posture: Posture.seatedChair,
    body: [22],
    tool: [8, 9, 10, 4],
    description: '의자에 앉아 도구를 발바닥 앞쪽, 발가락 뿌리 볼록한 부분 바로 뒤에 놓는다.\n'
        '체중을 조금씩 실으며 조절한다.\n'
        '안쪽과 바깥쪽을 오가며 원을 그리듯 움직인다.\n'
        '발가락 사이 뼈 위는 강하게 누르지 않는다. 전기 같은 느낌이 나면 즉시 중단한다.',
    time: (min: 45, max: 60),
  ),
  67: Move(
    index: 67,
    name: '아치 스탠딩 스트레칭',
    posture: Posture.standing,
    body: [21],
    tool: [4, 9],
    description: '도구의 평평한 면을 바닥에 두고 둥근 면 위에 발 아치를 얹는다.\n'
        '벽이나 의자를 손으로 잡아 균형을 확보한다.\n'
        '뒤꿈치와 발가락은 바닥에 닿게 하고 아치만 얹는다.\n'
        '체중을 서서히 실으며 30~60초 당김을 느낀다. 통증 없이 당김만 느껴지는 범위로 한다.',
    time: (min: 60, max: 90),
  ),
};

/// 인덱스로 단건 조회.
Move? moveOf(int index) => kMoves[index];

/// 인덱스 목록으로 다건 조회. 없는 인덱스는 건너뛴다.
List<Move> movesOf(Iterable<int> indexes) =>
    indexes.map((i) => kMoves[i]).whereType<Move>().toList(growable: false);

/// 특정 부위 인덱스를 포함하는 동작들.
List<Move> movesByBody(int bodyIndex) => kMoves.values
    .where((m) => m.body.contains(bodyIndex))
    .toList(growable: false);

/// 특정 도구 인덱스를 사용할 수 있는 동작들.
List<Move> movesByTool(int toolIndex) => kMoves.values
    .where((m) => m.tool.contains(toolIndex))
    .toList(growable: false);

/// 보유한 도구들로 수행 가능한 동작들.
List<Move> movesByOwnedTools(Set<int> ownedToolIndexes) => kMoves.values
    .where((m) => m.tool.any(ownedToolIndexes.contains))
    .toList(growable: false);

/// 특정 자세의 동작들.
List<Move> movesByPosture(Posture posture) =>
    kMoves.values.where((m) => m.posture == posture).toList(growable: false);

/// 바닥에 누울 필요가 없는 동작들. (사무실·외출 모드)
List<Move> movesWithoutFloor() =>
    kMoves.values.where((m) => !m.posture.needsFloor).toList(growable: false);
