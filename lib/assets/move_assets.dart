/// move_assets.dart
///
/// 동작(move) 에셋. 총 67개.
/// 인덱스(1~67)로 조회한다.
///
///   final move = kMoves[38]!;                 // 대둔근 4자 다리로 누르기
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

  /// 동작 이름. '근육 이름 + 자세 + 동작' 형식이며 도구 이름은 넣지 않는다.
  final String name;

  /// 시작 자세.
  final Posture posture;

  /// 해당되는 부위 인덱스들.
  final List<int> body;

  /// 사용 가능한 도구 인덱스들. 첫 번째가 기본 권장 도구.
  final List<int> tool;

  /// 동작 설명. 줄바꿈으로 구분된 정확히 4줄이며 순서가 고정되어 있다.
  /// 1줄 시작 자세(posture 와 일치), 2줄 도구 놓을 위치,
  /// 3줄 움직이는 방법과 압력 조절, 4줄 주의·중단 신호.
  /// 한 줄은 한 문장, 40자 이내. 어떤 도구로도 성립하는 표현만 쓴다.
  final String description;

  /// 권장 수행 시간 범위(초, 편측 기준).
  /// min 은 시간이 부족할 때 줄일 수 있는 하한, max 는 여유가 있을 때의 상한.
  final ({int min, int max}) time;

  /// 동작 이미지 에셋 경로. 파일명: 01.png ~ 67.png.
  String get imagePath =>
      "assets/images/moves/${index.toString().padLeft(2, '0')}.png";

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
    name: '후두하근 누워 오래 누르기',
    posture: Posture.supine,
    body: [23],
    tool: [11, 10, 5],
    description: '바로 누워 무릎을 세우고 발바닥을 바닥에 붙인다.\n'
        '뒤통수뼈 아래 좌우 오목한 곳에 도구를 놓는다.\n'
        '턱을 살짝 당긴 채 머리 무게만 싣고 더 밀지 않는다.\n'
        '어지럽거나 물체가 겹쳐 보이면 즉시 중단한다.',
    time: (min: 90, max: 180),
  ),
  2: Move(
    index: 2,
    name: '후두하근 앉아 풀기',
    posture: Posture.seatedChair,
    body: [23],
    tool: [10, 11],
    description: '의자에 앉아 등을 등받이에 붙이고 턱을 살짝 당긴다.\n'
        '뒤통수뼈 아래 모서리 좌우에 도구를 걸고 손으로 잡는다.\n'
        '어깨를 내린 채 앞쪽 아래로 당기며 2cm만 움직인다.\n'
        '손 힘은 세지기 쉬우니 아프면 당기는 힘을 뺀다.',
    time: (min: 60, max: 90),
  ),
  3: Move(
    index: 3,
    name: '견갑거근 벽에 걸어 누르기',
    posture: Posture.standingWall,
    body: [24],
    tool: [7, 9, 10, 11],
    description: '벽에 등을 대고 서서 누르는 쪽 팔로 반대 어깨를 감싼다.\n'
        '어깨뼈 위 모서리 안쪽에 도구를 건다.\n'
        '무릎을 굽혔다 펴며 3~5cm 위아래로 움직인다.\n'
        '목 옆 깊은 곳에는 신경이 지나므로 세게 누르지 않는다.',
    time: (min: 60, max: 90),
  ),

  // ───── 목 옆면 ─────
  4: Move(
    index: 4,
    name: '흉쇄유돌근 집어서 풀기',
    posture: Posture.seatedChair,
    body: [1],
    tool: [10],
    description: '의자에 앉아 고개를 누를 쪽으로 살짝 기울인다.\n'
        '목 옆으로 도드라지는 굵은 근육을 엄지와 검지로 집는다.\n'
        '누르지 말고 들어올린 채 귀 뒤·중간·쇄골 위로 옮긴다.\n'
        '맥박이 만져지면 손을 뒤로 옮기고 양쪽을 함께 잡지 않는다.',
    time: (min: 45, max: 60),
  ),
  5: Move(
    index: 5,
    name: '목 옆 쓸어내리기',
    posture: Posture.seatedChair,
    body: [1, 24],
    tool: [10],
    description: '의자에 앉아 등을 세우고 어깨를 내린다.\n'
        '목 옆 뒤쪽 3분의 1 지점에 도구를 얹는다.\n'
        '고개를 반대쪽으로 기울이고 3cm 이내로 쓸어내린다.\n'
        '쇄골 바로 위 옴폭한 곳은 건너뛴다.',
    time: (min: 30, max: 45),
  ),

  // ───── 어깨 위쪽 ─────
  6: Move(
    index: 6,
    name: '상부승모근 걸어 누르기',
    posture: Posture.seatedChair,
    body: [25],
    tool: [10, 7],
    description: '의자에 앉아 목을 반대쪽으로 기울여 근육을 늘린다.\n'
        '어깨 위 두툼한 곳에 도구를 걸치고 반대손으로 당긴다.\n'
        '가장 아픈 지점에 머문 뒤 5~8cm 범위로 짧게 움직인다.\n'
        '어깨를 으쓱하지 말고 한 지점을 2분 넘게 누르지 않는다.',
    time: (min: 60, max: 90),
  ),
  7: Move(
    index: 7,
    name: '상부승모근 벽에 대고 누르기',
    posture: Posture.standingWall,
    body: [25],
    tool: [10, 9, 7],
    description: '벽 모서리에 어깨 윗면을 대고 서서 팔은 늘어뜨린다.\n'
        '어깨 위 두툼한 부분에 도구를 놓고 벽 쪽으로 기댄다.\n'
        '발을 벽에서 멀리 둘수록 압력이 커지니 발로 조절한다.\n'
        '쇄골 위 오목한 곳으로 도구가 들어가지 않게 한다.',
    time: (min: 45, max: 60),
  ),
  8: Move(
    index: 8,
    name: '상부승모근 앉아 굴리기',
    posture: Posture.seatedChair,
    body: [25],
    tool: [10],
    description: '의자에 앉아 등을 세우고 어깨를 내린다.\n'
        '반대손으로 도구를 잡고 목 옆에서 어깨 끝 쪽에 얹는다.\n'
        '목을 반대쪽으로 기울이고 한 방향으로만 길게 쓸어낸다.\n'
        '되돌아올 때는 압력을 빼고 팔꿈치를 몸에 붙인다.',
    time: (min: 45, max: 60),
  ),

  // ───── 어깨 측면·후면 ─────
  9: Move(
    index: 9,
    name: '후면삼각근 벽에 대고 굴리기',
    posture: Posture.standingWall,
    body: [26],
    tool: [7, 9, 5, 10, 1],
    description: '벽에 어깨 뒤를 대고 서서 반대쪽 어깨를 감싸 안는다.\n'
        '어깨 뒤에 가로로 만져지는 뼈 바로 아래에 도구를 놓는다.\n'
        '무릎을 굽혔다 펴며 굴린 뒤 좌우로도 짧게 문지른다.\n'
        '뼈 위와 겨드랑이 한가운데는 누르지 않는다.',
    time: (min: 60, max: 90),
  ),
  10: Move(
    index: 10,
    name: '중간삼각근 옆으로 누워 굴리기',
    posture: Posture.sideLying,
    body: [2],
    tool: [5, 9, 10, 1],
    description: '옆으로 누워 누르는 쪽 팔을 머리 위로 뻗고 힘을 뺀다.\n'
        '어깨 끝 튀어나온 뼈에서 2~3cm 아래에 도구를 놓는다.\n'
        '어깨 바깥에서 팔 중간까지 길게 위아래로 굴린다.\n'
        '뼈 위를 직접 누르거나 팔을 안쪽으로 비틀지 않는다.',
    time: (min: 45, max: 60),
  ),
  11: Move(
    index: 11,
    name: '극하근 벽에 누르고 팔 돌리기',
    posture: Posture.standingWall,
    body: [27],
    tool: [7, 9, 10, 11, 5],
    description: '벽에 등을 대고 서서 반대쪽 어깨를 감싸 안는다.\n'
        '어깨뼈 뒷면 오목한 곳에 도구를 놓는다.\n'
        '무릎을 굽혔다 펴며 압력을 조절한 뒤 팔을 바깥으로 돌린다.\n'
        '어깨뼈에서 튀어나온 부분 위는 누르지 않는다.',
    time: (min: 60, max: 90),
  ),
  12: Move(
    index: 12,
    name: '소원근 누워 팔 당기기',
    posture: Posture.supine,
    body: [28],
    tool: [9, 10, 7],
    description: '바로 누워 무릎을 세우고 팔을 90°로 든다.\n'
        '어깨뼈 바깥 모서리 위쪽에 도구를 깐다.\n'
        '반대손으로 팔을 몸 쪽으로 천천히 당긴다.\n'
        '어깨뼈가 바닥에서 뜨거나 아프면 당김을 줄인다.',
    time: (min: 60, max: 90),
  ),

  // ───── 날개뼈 사이 ─────
  13: Move(
    index: 13,
    name: '능형근 어깨뼈 안쪽 누르기',
    posture: Posture.supine,
    body: [29],
    tool: [7, 11, 9, 10, 2],
    description: '바로 누워 무릎을 세우고 양팔을 가슴 앞에서 교차한다.\n'
        '어깨뼈 안쪽 모서리에서 안으로 1~2cm에 도구를 놓는다.\n'
        '짧게 위아래로 움직이며 아픈 지점에 머문다.\n'
        '척추 한가운데 튀어나온 돌기는 누르지 않는다.',
    time: (min: 60, max: 90),
  ),
  14: Move(
    index: 14,
    name: '중부승모근 등 위쪽 굴리기',
    posture: Posture.supine,
    body: [30],
    tool: [2, 1, 11, 7],
    description: '폼롤러를 가로로 놓고 등 윗부분을 얹어 눕는다.\n'
        '무릎을 세우고 양팔을 가슴 앞에서 교차한다.\n'
        '엉덩이를 들면 압력이 커지고 내리면 작아진다.\n'
        '어깨뼈 구간만 굴리고 허리까지 내려가지 않는다.',
    time: (min: 60, max: 90),
  ),
  15: Move(
    index: 15,
    name: '어깨뼈 사이 한 칸씩 누르기',
    posture: Posture.supine,
    body: [29, 30],
    tool: [11, 6, 7, 10],
    description: '바로 누워 무릎을 세우고 손으로 머리를 받친다.\n'
        '척추 가운데 돌기를 피해 좌우 근육에 도구를 놓는다.\n'
        '한 자리에서 30초 멈춘 뒤 위아래로 한 칸씩 옮긴다.\n'
        '3~4곳만 옮기고 한 지점에 3분 이상 머물지 않는다.',
    time: (min: 90, max: 120),
  ),

  // ───── 등 넓은 부위 ─────
  16: Move(
    index: 16,
    name: '광배근 옆으로 누워 길게 굴리기',
    posture: Posture.sideLying,
    body: [32],
    tool: [2, 1, 7, 9, 5],
    description: '옆으로 누워 누르는 쪽 팔을 머리 위로 뻗는다.\n'
        '겨드랑이 바로 아래에 도구를 놓고 무릎을 굽혀 받친다.\n'
        '겨드랑이에서 골반 옆까지 굴리며 몸통을 15° 돌린다.\n'
        '겨드랑이 한가운데는 압박하지 않는다.',
    time: (min: 60, max: 90),
  ),
  17: Move(
    index: 17,
    name: '대원근 겨드랑이 뒤 누르기',
    posture: Posture.sideLying,
    body: [31],
    tool: [7, 9, 5, 10, 1, 2],
    description: '옆으로 누워 누르는 쪽 팔을 머리 위로 뻗는다.\n'
        '겨드랑이 뒤쪽 두툼한 근육의 위쪽 절반에 도구를 놓는다.\n'
        '30초 멈춰 누른 뒤 좌우로 짧게 문지른다.\n'
        '도구가 겨드랑이 한가운데로 미끄러지지 않게 한다.',
    time: (min: 45, max: 60),
  ),
  18: Move(
    index: 18,
    name: '광배근 벽에 대고 팔 올리기',
    posture: Posture.standingWall,
    body: [32, 31],
    tool: [9, 10, 7],
    description: '벽 모서리에 옆구리 위쪽을 대고 선다.\n'
        '겨드랑이 뒤쪽에 도구를 놓고 발 위치로 압력을 조절한다.\n'
        '누르는 쪽 팔을 벽을 따라 머리 위로 10회 올렸다 내린다.\n'
        '허리를 젖히지 말고 배에 힘을 유지한다.',
    time: (min: 45, max: 60),
  ),

  // ───── 척추·허리 주변 ─────
  19: Move(
    index: 19,
    name: '척추기립근 한 칸씩 누르기',
    posture: Posture.supine,
    body: [35],
    tool: [11, 6, 2, 7],
    description: '바로 누워 무릎을 세워 허리가 뜨지 않게 한다.\n'
        '척추 돌기를 피해 양옆 길게 솟은 근육에 도구를 걸친다.\n'
        '골반을 살짝 뒤로 기울인 채 한 자리에 30초씩 머문다.\n'
        '허리 구간에서는 굴리지 말고 자리만 옮긴다.',
    time: (min: 90, max: 120),
  ),
  20: Move(
    index: 20,
    name: '등 굽은 곳 펴며 굴리기',
    posture: Posture.supine,
    body: [35, 30],
    tool: [2, 1, 11, 4],
    description: '폼롤러를 가로로 두고 등 윗부분을 얹어 눕는다.\n'
        '무릎을 세우고 손으로 머리 뒤를 받쳐 목을 지지한다.\n'
        '배에 힘을 준 채 허리가 아니라 등만 뒤로 젖힌다.\n'
        '롤러가 허리까지 내려가지 않게 한 칸씩만 옮긴다.',
    time: (min: 60, max: 90),
  ),
  21: Move(
    index: 21,
    name: '요방형근 45° 기울여 누르기',
    posture: Posture.supine,
    body: [36],
    tool: [7, 9, 6, 10],
    description: '바로 누워 무릎을 세우고 몸을 45° 옆으로 기울인다.\n'
        '갈비뼈와 골반뼈 사이, 척추 바깥 4~6cm에 도구를 둔다.\n'
        '누르는 쪽 팔을 머리 위로 뻗고 3~5cm 범위로만 움직인다.\n'
        '갈비뼈 바로 아래 깊은 곳은 찌르지 않는다.',
    time: (min: 60, max: 90),
  ),
  22: Move(
    index: 22,
    name: '허리 양옆 오래 누르기',
    posture: Posture.supine,
    body: [35],
    tool: [6, 11, 10],
    description: '바로 누워 무릎을 세우고 발바닥을 바닥에 붙인다.\n'
        '척추 돌기를 피해 허리뼈 양옆 솟은 근육에 도구를 둔다.\n'
        '굴리지 말고 45~60초씩 2~3곳으로 자리만 옮긴다.\n'
        '허리는 낮은 압력이 원칙이니 체중을 다 싣지 않는다.',
    time: (min: 90, max: 120),
  ),

  // ───── 가슴 앞쪽 ─────
  23: Move(
    index: 23,
    name: '대흉근 문틀에 기대 풀기',
    posture: Posture.standingWall,
    body: [3],
    tool: [7, 9, 10, 5],
    description: '서서 문틀이나 벽 모서리에 기대고 팔을 45~90° 벌린다.\n'
        '쇄골 아래 2~3cm나 겨드랑이 앞 두툼한 근육에 도구를 댄다.\n'
        '쇄골 아래를 따라 좌우로 굴리며 발로 체중을 조절한다.\n'
        '겨드랑이 한가운데로는 도구를 넣지 않는다.',
    time: (min: 60, max: 90),
  ),
  24: Move(
    index: 24,
    name: '소흉근 쇄골 아래 누르기',
    posture: Posture.standingWall,
    body: [4],
    tool: [10, 9, 7],
    description: '서서 벽 모서리에 기대고 누르는 쪽 팔은 늘어뜨린다.\n'
        '쇄골 바깥 아래 단단한 뼈에서 안쪽 아래로 3~5cm에 댄다.\n'
        '20~30초 멈춘 뒤 근육 방향을 따라 아주 짧게만 옮긴다.\n'
        '저릿한 느낌이 오면 신경이 지나는 자리이니 즉시 옮긴다.',
    time: (min: 45, max: 60),
  ),
  25: Move(
    index: 25,
    name: '폼롤러 세로로 가슴 열기',
    posture: Posture.supine,
    body: [3, 4],
    tool: [1, 4, 2],
    description: '폼롤러를 세로로 두고 꼬리뼈부터 머리까지 얹어 눕는다.\n'
        '무릎을 세우고 발을 어깨너비로 벌려 균형을 잡는다.\n'
        '팔을 T자로 벌려 늘어뜨린 뒤 W자, Y자로 바꾼다.\n'
        '허리를 젖히지 말고 갈비뼈를 바닥 쪽에 붙인다.',
    time: (min: 120, max: 180),
  ),

  // ───── 겨드랑이 밑 갈비뼈 ─────
  26: Move(
    index: 26,
    name: '전거근 옆으로 누워 굴리기',
    posture: Posture.sideLying,
    body: [5],
    tool: [1, 5, 2, 10],
    description: '옆으로 누워 누르는 쪽 팔을 머리 위로 뻗는다.\n'
        '겨드랑이 아래 갈비뼈 바깥면에 도구를 놓는다.\n'
        '무릎을 굽히고 위쪽 손으로 바닥을 짚어 압력을 조절한다.\n'
        '갈비뼈가 뻗은 방향을 따라 천천히 움직이며 숨을 쉰다.',
    time: (min: 45, max: 60),
  ),
  27: Move(
    index: 27,
    name: '전거근 갈비뼈 누르고 숨쉬기',
    posture: Posture.sideLying,
    body: [5],
    tool: [9, 10, 7, 8],
    description: '옆으로 누워 누르는 쪽 팔을 머리 위로 뻗는다.\n'
        '겨드랑이 아래 4~6번 갈비뼈 바깥면에 도구를 놓는다.\n'
        '갈비뼈 하나씩 옮기며 20~30초씩 멈춰 옆구리로 숨 쉰다.\n'
        '체중을 거의 싣지 않은 채 시작해 조금씩만 늘린다.',
    time: (min: 60, max: 90),
  ),

  // ───── 복부·옆구리 ─────
  28: Move(
    index: 28,
    name: '복직근 엎드려 눌러 숨쉬기',
    posture: Posture.prone,
    body: [6],
    tool: [10, 5, 9],
    description: '엎드려 팔꿈치로 상체를 받치고 무릎을 살짝 굽힌다.\n'
        '갈비뼈 아래나 배 근육 바깥쪽 가장자리에 도구를 깐다.\n'
        '굴리지 말고 3~4곳을 30~45초씩 옮긴다.\n'
        '배꼽 둘레 한가운데와 식사 직후에는 하지 않는다.',
    time: (min: 90, max: 120),
  ),
  29: Move(
    index: 29,
    name: '복사근 옆으로 누워 굴리기',
    posture: Posture.sideLying,
    body: [7],
    tool: [1, 10, 9, 5],
    description: '옆으로 누워 누르는 쪽 팔을 머리 위로 뻗는다.\n'
        '갈비뼈 아래부터 골반 위까지 옆구리 바깥면에 도구를 둔다.\n'
        '무릎을 굽혀 몸을 받치고 갈비뼈 방향을 따라 움직인다.\n'
        '배 정면으로 도구가 넘어오지 않게 한다.',
    time: (min: 45, max: 60),
  ),
  30: Move(
    index: 30,
    name: '옆구리 벽에 대고 숨쉬기',
    posture: Posture.standingWall,
    body: [7],
    tool: [10, 9, 8],
    description: '벽 모서리에 옆구리를 대고 서서 팔을 머리 위로 든다.\n'
        '갈비뼈 아래쪽 옆면에 도구를 놓는다.\n'
        '2~3곳을 20~30초씩 옮기며 옆구리로 숨을 넣는다.\n'
        '발을 벽에서 멀리 둘수록 세지니 조금씩만 옮긴다.',
    time: (min: 45, max: 60),
  ),

  // ───── 위팔 ─────
  31: Move(
    index: 31,
    name: '이두근 책상에 대고 누르기',
    posture: Posture.seatedChair,
    body: [8],
    tool: [5, 9, 10, 1, 2],
    description: '의자에 앉아 팔꿈치를 살짝 굽혀 책상 위에 올린다.\n'
        '위팔 앞면 아래에 도구를 두고 상체를 앞으로 기울인다.\n'
        '어깨에서 팔꿈치 쪽으로 굴리며 손바닥을 번갈아 돌린다.\n'
        '팔 안쪽 오목한 홈에는 도구가 닿지 않게 한다.',
    time: (min: 45, max: 60),
  ),
  32: Move(
    index: 32,
    name: '삼두근 옆으로 누워 굴리기',
    posture: Posture.sideLying,
    body: [33],
    tool: [5, 7, 9, 1, 2],
    description: '옆으로 누워 누르는 쪽 팔을 머리 위로 뻗는다.\n'
        '팔 뒤쪽 아래에 도구를 놓고 반대손으로 바닥을 짚는다.\n'
        '겨드랑이 뒤에서 팔꿈치 쪽으로 굴리며 팔을 돌린다.\n'
        '팔꿈치 안쪽 찌릿한 지점 위는 지나가지 않는다.',
    time: (min: 45, max: 60),
  ),
  33: Move(
    index: 33,
    name: '상완근 팔꿈치 위 누르기',
    posture: Posture.seatedChair,
    body: [9],
    tool: [7, 9, 5],
    description: '의자에 앉아 팔을 책상에 올리고 손등이 위로 오게 한다.\n'
        '팔꿈치 주름 위 3~7cm, 알통 바깥 경계에 도구를 둔다.\n'
        '팔꿈치를 살짝 굽힌 채 20~30초씩 두 번 멈춰 누른다.\n'
        '팔꿈치 앞 오목한 곳에는 도구가 닿지 않게 한다.',
    time: (min: 30, max: 45),
  ),
  34: Move(
    index: 34,
    name: '위팔 앞뒤 굴리기',
    posture: Posture.seatedChair,
    body: [8, 33],
    tool: [5],
    description: '의자에 앉아 팔을 몸 앞에 두고 팔꿈치를 살짝 굽힌다.\n'
        '반대손으로 도구를 잡고 위팔 앞면에 감싸듯 얹는다.\n'
        '앞면을 8~10회 왕복한 뒤 뒷면으로 옮겨 같게 반복한다.\n'
        '팔 안쪽 면과 관절 위는 건너뛰고 힘을 완전히 뺀다.',
    time: (min: 45, max: 60),
  ),

  // ───── 아랫팔 ─────
  35: Move(
    index: 35,
    name: '전완굴근 팔뚝 안쪽 굴리기',
    posture: Posture.seatedChair,
    body: [10],
    tool: [8, 9, 5],
    description: '의자에 앉아 팔꿈치를 책상에 두고 손바닥을 위로 편다.\n'
        '반대손으로 도구를 잡고 팔뚝 안쪽에 댄다.\n'
        '팔꿈치에서 손목 쪽으로 굴린 뒤 직각 방향으로도 민다.\n'
        '팔꿈치 안쪽 뼈와 손목 주름 위는 건너뛴다.',
    time: (min: 45, max: 60),
  ),
  36: Move(
    index: 36,
    name: '전완신근 팔뚝 바깥 굴리기',
    posture: Posture.seatedChair,
    body: [34],
    tool: [9, 8, 7],
    description: '의자에 앉아 팔을 책상에 두고 손등을 위로 둔다.\n'
        '팔꿈치 바깥 뼈에서 손목 쪽 2~6cm 지점에 도구를 댄다.\n'
        '반대손으로 도구를 잡고 팔뚝 바깥면을 따라 굴린다.\n'
        '통증이 심할 때는 뼈에 붙는 자리를 피하고 근육만 민다.',
    time: (min: 45, max: 60),
  ),
  37: Move(
    index: 37,
    name: '팔뚝 책상에 대고 원 그리기',
    posture: Posture.seatedChair,
    body: [10, 34],
    tool: [8, 9, 10],
    description: '의자에 앉아 어깨를 내리고 팔에 힘을 뺀다.\n'
        '책상 위에 도구를 놓고 팔뚝이나 손바닥을 얹는다.\n'
        '상체 무게를 살짝 실은 채 원을 그리듯 움직인다.\n'
        '손목 주름 위는 직접 누르지 않는다.',
    time: (min: 45, max: 60),
  ),

  // ───── 엉덩이 뒤쪽 ─────
  38: Move(
    index: 38,
    name: '대둔근 4자 다리로 누르기',
    posture: Posture.seatedFloor,
    body: [37],
    tool: [7, 9, 2, 10, 3],
    description: '바닥에 앉아 도구 위에 한쪽 엉덩이를 얹는다.\n'
        '같은쪽 발목을 반대쪽 무릎에 올려 다리를 4자로 겹친다.\n'
        '손으로 뒤를 짚어 체중을 조절하고 천천히 굴린다.\n'
        '엉덩이 아래 만져지는 단단한 뼈 위는 누르지 않는다.',
    time: (min: 60, max: 90),
  ),
  39: Move(
    index: 39,
    name: '대둔근 바닥에 앉아 굴리기',
    posture: Posture.seatedFloor,
    body: [37],
    tool: [2, 1, 3, 5],
    description: '바닥에 앉아 폼롤러를 엉덩이 아래 가로로 놓는다.\n'
        '양손으로 뒤를 짚고 두 다리를 굽혀 발을 바닥에 둔다.\n'
        '몸통을 좌우로 기울이며 굴리고 세게 하려면 다리를 겹친다.\n'
        '엉덩이 아래 단단한 뼈 위에서는 멈추지 않는다.',
    time: (min: 60, max: 90),
  ),
  40: Move(
    index: 40,
    name: '이상근 4자 다리로 오래 누르기',
    posture: Posture.seatedFloor,
    body: [38],
    tool: [7, 9, 10, 2],
    description: '바닥에 앉아 발목을 반대쪽 무릎에 올려 4자로 겹친다.\n'
        '허리 아래 옴폭한 곳과 고관절 옆 뼈의 중간에 도구를 둔다.\n'
        '손으로 뒤를 짚어 체중을 조절하고 굴리지 않고 머문다.\n'
        '다리로 저릿하게 뻗치면 도구를 1~2cm 바깥으로 옮긴다.',
    time: (min: 60, max: 90),
  ),
  41: Move(
    index: 41,
    name: '엉치뼈 옆 누르기',
    posture: Posture.supine,
    body: [37],
    tool: [11, 10, 9, 6],
    description: '바로 누워 무릎을 세운다.\n'
        '엉치뼈 가운데를 피해 좌우 가장자리에 도구를 걸친다.\n'
        '한 자리에서 30~45초 머문 뒤 옆으로 옮긴다.\n'
        '엉치뼈 한가운데는 직접 누르지 않는다.',
    time: (min: 60, max: 90),
  ),

  // ───── 골반 옆쪽 ─────
  42: Move(
    index: 42,
    name: '중둔근 옆으로 누워 누르기',
    posture: Posture.sideLying,
    body: [11],
    tool: [7, 9, 2, 1, 10],
    description: '옆으로 누워 아래쪽 다리는 펴고 위쪽 다리는 굽힌다.\n'
        '골반뼈 위 테두리에서 2~5cm 아래에 도구를 놓는다.\n'
        '위쪽 발로 앞 바닥을 짚는 정도로 압력을 조절한다.\n'
        '고관절 옆 튀어나온 뼈 위는 피한다.',
    time: (min: 45, max: 60),
  ),
  43: Move(
    index: 43,
    name: '대퇴근막장근 엎드려 누르기',
    posture: Posture.prone,
    body: [13],
    tool: [7, 9, 1, 2, 5],
    description: '엎드려 몸을 45° 기울이고 반대쪽 다리는 굽혀 앞에 둔다.\n'
        '골반 앞쪽 뼈에서 바깥쪽 아래로 3~5cm에 도구를 놓는다.\n'
        '3~5cm 범위로 움직이며 다리를 안팎으로 돌린다.\n'
        '골반 앞쪽 튀어나온 뼈 위는 누르지 않는다.',
    time: (min: 45, max: 60),
  ),
  44: Move(
    index: 44,
    name: '소둔근 앞으로 기울여 누르기',
    posture: Posture.sideLying,
    body: [12],
    tool: [9, 7, 10],
    description: '옆으로 눕되 몸통을 앞으로 20~30° 기울인다.\n'
        '고관절 옆 뼈에서 앞쪽 위로 3~4cm 지점에 도구를 놓는다.\n'
        '위쪽 발로 바닥을 짚어 압력을 조절하고 30~60초 머문다.\n'
        '다리로 뻗치는 통증이 있으면 즉시 자리를 옮긴다.',
    time: (min: 60, max: 90),
  ),

  // ───── 허벅지 앞쪽 ─────
  45: Move(
    index: 45,
    name: '대퇴사두근 엎드려 굴리기',
    posture: Posture.prone,
    body: [14],
    tool: [2, 1, 3, 7],
    description: '엎드려 팔꿈치로 상체를 받친다.\n'
        '허벅지 앞에 도구를 가로로 놓는다.\n'
        '골반 앞에서 무릎 위 5cm까지 길게 굴린다.\n'
        '허리가 젖혀지지 않게 배에 힘을 유지한다.',
    time: (min: 60, max: 90),
  ),
  46: Move(
    index: 46,
    name: '대퇴직근 앉아 굴리기',
    posture: Posture.seatedChair,
    body: [15],
    tool: [5, 9],
    description: '의자 끝에 앉아 다리를 앞으로 뻗고 무릎을 살짝 굽힌다.\n'
        '양손으로 도구를 잡고 허벅지 앞면에 얹는다.\n'
        '안쪽·가운데·바깥쪽 세 줄로 나눠 무릎 위까지 민다.\n'
        '무릎 관절 위는 지나지 않는다.',
    time: (min: 45, max: 60),
  ),
  47: Move(
    index: 47,
    name: '무릎 위 사두 집중 누르기',
    posture: Posture.prone,
    body: [14],
    tool: [7, 9, 5, 10],
    description: '엎드려 팔꿈치로 상체를 지탱한다.\n'
        '무릎뼈 위 5~10cm 지점에 도구를 놓는다.\n'
        '30초 머문 뒤 무릎을 굽혔다 펴며 근육이 지나가게 한다.\n'
        '무릎뼈와 그 아래 힘줄 위에는 도구를 두지 않는다.',
    time: (min: 45, max: 60),
  ),
  48: Move(
    index: 48,
    name: '내측광근 다리 벌려 굴리기',
    posture: Posture.prone,
    body: [16],
    tool: [5, 2, 9, 10],
    description: '엎드려 누르는 쪽 다리를 옆으로 90° 벌린다.\n'
        '무릎뼈 안쪽 위 5~10cm 구간 아래에 도구를 놓는다.\n'
        '짧게 위아래와 사선으로 움직인다.\n'
        '무릎 안쪽 관절 틈까지 내려가지 않는다.',
    time: (min: 45, max: 60),
  ),

  // ───── 허벅지 뒤쪽 ─────
  49: Move(
    index: 49,
    name: '햄스트링 바닥에 앉아 굴리기',
    posture: Posture.seatedFloor,
    body: [39],
    tool: [2, 1, 3, 7],
    description: '바닥에 앉아 도구 위에 허벅지 뒤를 얹고 엉덩이를 든다.\n'
        '손으로 바닥을 짚어 체중을 조절하고 다리를 안팎으로 돌린다.\n'
        '엉덩이 아래 단단한 뼈 밑에서 무릎 위 5cm까지 굴린다.\n'
        '무릎 뒤 오목한 곳은 지나가지 않는다.',
    time: (min: 60, max: 90),
  ),
  50: Move(
    index: 50,
    name: '햄스트링 위쪽 앉아 누르기',
    posture: Posture.seatedChair,
    body: [39],
    tool: [7, 9, 10],
    description: '단단한 의자에 앉아 상체를 앞으로 기울인다.\n'
        '엉덩이 아래 단단한 뼈에서 3~5cm 밑에 도구를 놓는다.\n'
        '같은쪽 발목을 반대 무릎에 올리면 더 깊이 닿는다.\n'
        '저릿한 느낌이 다리로 뻗치면 즉시 자리를 옮긴다.',
    time: (min: 60, max: 90),
  ),
  51: Move(
    index: 51,
    name: '햄스트링 의자에 앉아 굴리기',
    posture: Posture.seatedChair,
    body: [39],
    tool: [5],
    description: '의자에 앉아 무릎을 120°쯤 굽히고 발을 앞에 둔다.\n'
        '양손으로 도구를 잡고 허벅지 뒤에 감듯이 얹는다.\n'
        '안쪽·바깥쪽 두 줄로 나눠 엉덩이 밑에서 무릎 위까지 민다.\n'
        '무릎 뒤 오목한 곳은 건너뛴다.',
    time: (min: 45, max: 60),
  ),

  // ───── 허벅지 안쪽 ─────
  52: Move(
    index: 52,
    name: '내전근 다리 벌려 굴리기',
    posture: Posture.prone,
    body: [18],
    tool: [1, 2, 5, 9],
    description: '엎드려 누르는 쪽 다리를 옆으로 90° 벌린다.\n'
        '허벅지 안쪽 아래에 도구를 대각선으로 놓는다.\n'
        '사타구니 앞 뼈에서 5cm 아래부터 길게 굴린다.\n'
        '멍이 들기 쉬우니 처음에는 약한 압력으로만 한다.',
    time: (min: 60, max: 90),
  ),
  53: Move(
    index: 53,
    name: '내전근 위쪽 눌러 풀기',
    posture: Posture.prone,
    body: [18],
    tool: [9, 10, 7],
    description: '엎드려 누르는 쪽 다리를 옆으로 90° 벌린다.\n'
        '사타구니 앞 뼈에서 5cm 아래 허벅지 안쪽에 도구를 놓는다.\n'
        '팔꿈치로 상체를 받쳐 2~3곳을 20~30초씩 옮긴다.\n'
        '맥박이 만져지면 즉시 바깥쪽 아래로 옮긴다.',
    time: (min: 45, max: 60),
  ),
  54: Move(
    index: 54,
    name: '내전근 앉아 굴리기',
    posture: Posture.seatedChair,
    body: [18],
    tool: [5],
    description: '의자에 앉아 무릎을 옆으로 열고 발바닥을 바닥에 붙인다.\n'
        '양손으로 도구를 잡고 허벅지 안쪽 면에 얹는다.\n'
        '허벅지 중간에서 무릎 위까지 굴린다.\n'
        '사타구니 쪽으로 너무 올라가지 않는다.',
    time: (min: 45, max: 60),
  ),

  // ───── 허벅지 바깥쪽 ─────
  55: Move(
    index: 55,
    name: '외측광근 30° 기울여 굴리기',
    posture: Posture.sideLying,
    body: [17],
    tool: [2, 1, 7, 9],
    description: '옆으로 눕되 몸을 앞으로 30° 기울인다.\n'
        '허벅지 바깥면 아래에 도구를 놓는다.\n'
        '위쪽 발로 바닥을 짚고 고관절 옆 뼈부터 무릎 위까지 민다.\n'
        '완전히 옆으로 누우면 뼈만 눌리니 30°를 유지한다.',
    time: (min: 60, max: 90),
  ),
  56: Move(
    index: 56,
    name: '외측광근 깊게 굴리기',
    posture: Posture.sideLying,
    body: [17],
    tool: [3, 2, 7],
    description: '옆으로 눕고 몸을 앞으로 30° 기울인다.\n'
        '허벅지 바깥면 아래에 도구를 놓는다.\n'
        '위쪽 발로 바닥을 짚어 체중을 절반만 싣고 10cm씩 굴린다.\n'
        '무릎 바깥 관절 틈에서 5cm 위에서 멈춘다.',
    time: (min: 45, max: 60),
  ),
  57: Move(
    index: 57,
    name: '무릎 위 외측광근 누르기',
    posture: Posture.sideLying,
    body: [17],
    tool: [5, 9, 10],
    description: '옆으로 누워 몸을 앞으로 30° 기울인다.\n'
        '무릎뼈 바깥 위 5~10cm 구간에만 도구를 놓는다.\n'
        '위쪽 발로 바닥을 짚고 5cm 범위로 무릎을 굽혔다 편다.\n'
        '무릎 바깥 관절 틈에는 도구가 닿지 않게 한다.',
    time: (min: 45, max: 60),
  ),

  // ───── 종아리 뒤쪽 ─────
  58: Move(
    index: 58,
    name: '비복근 앉아 굴리기',
    posture: Posture.seatedChair,
    body: [40],
    tool: [2, 1, 7],
    description: '의자에 앉아 발을 앞에 두고 무릎을 살짝 굽힌다.\n'
        '양손으로 도구를 잡고 종아리 뒤에 얹는다.\n'
        '발목 힘을 뺀 채 무릎 아래에서 발목 위까지 굴린다.\n'
        '무릎 뒤 오목한 곳에서 5cm 아래부터 시작한다.',
    time: (min: 60, max: 90),
  ),
  59: Move(
    index: 59,
    name: '비복근 바닥에 앉아 굴리기',
    posture: Posture.seatedFloor,
    body: [40],
    tool: [2, 1, 3, 5],
    description: '바닥에 앉아 도구 위에 종아리를 얹고 엉덩이를 든다.\n'
        '손으로 바닥을 짚어 체중을 조절하고 발목 힘을 뺀다.\n'
        '무릎 아래 5cm에서 발목 위 5cm까지 굴리며 다리를 돌린다.\n'
        '처음부터 두 다리를 겹쳐 올리지 않는다.',
    time: (min: 60, max: 90),
  ),
  60: Move(
    index: 60,
    name: '가자미근 무릎 굽혀 누르기',
    posture: Posture.seatedFloor,
    body: [41],
    tool: [7, 9, 5],
    description: '바닥에 앉아 무릎을 30~45° 굽혀 바깥 근육을 느슨히 한다.\n'
        '종아리 아래 3분의 1 지점에 도구를 놓는다.\n'
        '반대쪽 다리로 압력을 조절하고 발목을 안팎으로 돌린다.\n'
        '종아리 뒤 깊은 한가운데는 세게 누르지 않는다.',
    time: (min: 45, max: 60),
  ),
  61: Move(
    index: 61,
    name: '아킬레스건 위쪽 누르기',
    posture: Posture.seatedFloor,
    body: [42],
    tool: [11, 10, 9],
    description: '바닥에 앉아 무릎을 살짝 굽히고 발목 힘을 뺀다.\n'
        '아킬레스건 자체를 피해 좌우 가장자리에 도구를 댄다.\n'
        '발목 위 5~12cm를 2~3곳으로 나눠 20~30초씩 머문다.\n'
        '힘줄 위를 직접 세게 누르지 않는다.',
    time: (min: 45, max: 60),
  ),

  // ───── 정강이 앞/옆 ─────
  62: Move(
    index: 62,
    name: '전경골근 앉아 굴리기',
    posture: Posture.seatedChair,
    body: [19],
    tool: [5, 9],
    description: '의자에 앉아 다리를 반대 무릎 위에 올린다.\n'
        '정강이 뼈 바깥 1~2cm 근육 위에 도구를 얹는다.\n'
        '발목 힘을 빼고 무릎 아래 5cm에서 발목 위까지 굴린다.\n'
        '정강이 앞 날카로운 뼈 위는 누르지 않는다.',
    time: (min: 45, max: 60),
  ),
  63: Move(
    index: 63,
    name: '전경골근 네발기기 굴리기',
    posture: Posture.quadruped,
    body: [19],
    tool: [1, 2, 5],
    description: '네발기기 자세로 엎드려 손에 체중을 나눠 싣는다.\n'
        '정강이 아래에 도구를 가로로 놓는다.\n'
        '다리를 살짝 안쪽으로 돌리고 앞뒤로 몸을 움직인다.\n'
        '무릎이 아프면 무릎 밑에 쿠션을 깐다.',
    time: (min: 45, max: 60),
  ),
  64: Move(
    index: 64,
    name: '비골근 옆으로 누워 굴리기',
    posture: Posture.sideLying,
    body: [20],
    tool: [5, 7, 9],
    description: '옆으로 누워 종아리 바깥면 아래에 도구를 놓는다.\n'
        '무릎 바깥 아래 튀어나온 뼈에서 5cm 밑부터 시작한다.\n'
        '위쪽 발로 앞 바닥을 짚어 압력을 조절하며 굴린다.\n'
        '발등이 저리면 즉시 아래쪽으로 옮긴다.',
    time: (min: 45, max: 60),
  ),

  // ───── 발바닥 ─────
  65: Move(
    index: 65,
    name: '족저근막 굴리고 발가락 들기',
    posture: Posture.seatedChair,
    body: [21],
    tool: [9, 8, 10, 7],
    description: '의자에 앉아 발바닥 아래에 도구를 둔다.\n'
        '뒤꿈치 안쪽에서 앞으로 1~2cm부터 아치 전체를 굴린다.\n'
        '마지막에 발가락을 들어 아치를 팽팽히 하고 다시 굴린다.\n'
        '뒤꿈치 뼈 위는 세게 누르지 않는다.',
    time: (min: 60, max: 90),
  ),
  66: Move(
    index: 66,
    name: '발바닥 앞쪽 원 그리기',
    posture: Posture.seatedChair,
    body: [22],
    tool: [8, 9, 10, 4],
    description: '의자에 앉아 발바닥 앞쪽에 도구를 둔다.\n'
        '발가락 뿌리 볼록한 부분 바로 뒤에 도구를 맞춘다.\n'
        '체중을 조금씩 실으며 안쪽과 바깥쪽을 원 그리듯 민다.\n'
        '저릿하게 뻗치는 느낌이 나면 즉시 중단한다.',
    time: (min: 45, max: 60),
  ),
  67: Move(
    index: 67,
    name: '발 아치 서서 늘리기',
    posture: Posture.standing,
    body: [21],
    tool: [4, 9],
    description: '서서 벽이나 의자를 손으로 잡아 균형을 잡는다.\n'
        '도구의 평평한 면을 바닥에 두고 둥근 면에 아치를 얹는다.\n'
        '뒤꿈치와 발가락은 바닥에 댄 채 체중을 서서히 싣는다.\n'
        '통증 없이 당김만 느껴지는 범위까지만 한다.',
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
