/// body_assets.dart
///
/// 부위(body) 에셋.
/// 인덱스(1~42)로 조회한다. 1~22는 전면(앞), 23~42는 후면(뒤).
///
///   final body = kBodies[37]!;                       // 대둔근
///   final frontThigh = bodiesOfPart(BodyFace.front, BodyPart.thigh);
///
/// xy는 몸 그림 위 스팟의 정규화 좌표(0.0~1.0).
/// x = 그림 좌측 0.0 ~ 우측 1.0, y = 그림 상단 0.0 ~ 하단 1.0.
/// 좌우 대칭 근육은 한쪽 좌표만 담았다. 반대쪽은 (1 - x)로 미러링해 쓴다.
library body_assets;

/// 전면 / 후면.
enum BodyFace {
  front('앞'),
  back('뒤');

  const BodyFace(this.label);
  final String label;
}

/// 몸 그림상의 부위 구역.
/// front 전용 : chest, abdomen, pelvis, shin, sole
/// back  전용 : upperBack, waist, hip, calf, heel
/// 공용      : neck, shoulder, arm, thigh
enum BodyPart {
  neck('목'),
  shoulder('어깨'),
  chest('가슴'),
  arm('팔'),
  abdomen('복부'),
  pelvis('골반'),
  thigh('허벅지'),
  shin('정강이'),
  sole('발바닥'),
  upperBack('등'),
  waist('허리'),
  hip('엉덩이'),
  calf('종아리'),
  heel('발뒤');

  const BodyPart(this.label);
  final String label;
}

/// 부위 한 개.
class Body {
  const Body({
    required this.index,
    required this.name,
    required this.forb,
    required this.part,
    required this.xy,
  });

  /// 조회용 인덱스.
  final int index;

  /// 근육 이름.
  final String name;

  /// 앞 / 뒤.
  final BodyFace forb;

  /// 근육 위치 구역.
  final BodyPart part;

  /// 몸 그림에서의 스팟 좌표 (x, y). 각 0.0~1.0.
  final ({double x, double y}) xy;
}

/// 인덱스 → 부위.
const Map<int, Body> kBodies = <int, Body>{
  // ─────────── 전면 (앞) ───────────
  1: Body(
    index: 1,
    name: '흉쇄유돌근',
    forb: BodyFace.front,
    part: BodyPart.neck,
    xy: (x: 0.460, y: 0.150),
  ),
  2: Body(
    index: 2,
    name: '중간삼각근',
    forb: BodyFace.front,
    part: BodyPart.shoulder,
    xy: (x: 0.315, y: 0.225),
  ),
  3: Body(
    index: 3,
    name: '대흉근',
    forb: BodyFace.front,
    part: BodyPart.chest,
    xy: (x: 0.420, y: 0.240),
  ),
  4: Body(
    index: 4,
    name: '소흉근',
    forb: BodyFace.front,
    part: BodyPart.chest,
    xy: (x: 0.420, y: 0.240),
  ),
  5: Body(
    index: 5,
    name: '전거근',
    forb: BodyFace.front,
    part: BodyPart.chest,
    xy: (x: 0.420, y: 0.240),
  ),
  6: Body(
    index: 6,
    name: '복직근',
    forb: BodyFace.front,
    part: BodyPart.abdomen,
    xy: (x: 0.440, y: 0.355),
  ),
  7: Body(
    index: 7,
    name: '복사근',
    forb: BodyFace.front,
    part: BodyPart.abdomen,
    xy: (x: 0.440, y: 0.355),
  ),
  8: Body(
    index: 8,
    name: '상완이두근',
    forb: BodyFace.front,
    part: BodyPart.arm,
    xy: (x: 0.250, y: 0.330),
  ),
  9: Body(
    index: 9,
    name: '상완근',
    forb: BodyFace.front,
    part: BodyPart.arm,
    xy: (x: 0.250, y: 0.330),
  ),
  10: Body(
    index: 10,
    name: '전완굴근',
    forb: BodyFace.front,
    part: BodyPart.arm,
    xy: (x: 0.250, y: 0.330),
  ),
  11: Body(
    index: 11,
    name: '중둔근',
    forb: BodyFace.front,
    part: BodyPart.pelvis,
    xy: (x: 0.360, y: 0.480),
  ),
  12: Body(
    index: 12,
    name: '소둔근',
    forb: BodyFace.front,
    part: BodyPart.pelvis,
    xy: (x: 0.360, y: 0.480),
  ),
  13: Body(
    index: 13,
    name: '대퇴근막장근',
    forb: BodyFace.front,
    part: BodyPart.pelvis,
    xy: (x: 0.360, y: 0.480),
  ),
  14: Body(
    index: 14,
    name: '대퇴사두근',
    forb: BodyFace.front,
    part: BodyPart.thigh,
    xy: (x: 0.390, y: 0.600),
  ),
  15: Body(
    index: 15,
    name: '대퇴직근',
    forb: BodyFace.front,
    part: BodyPart.thigh,
    xy: (x: 0.390, y: 0.600),
  ),
  16: Body(
    index: 16,
    name: '내측광근',
    forb: BodyFace.front,
    part: BodyPart.thigh,
    xy: (x: 0.390, y: 0.600),
  ),
  17: Body(
    index: 17,
    name: '외측광근',
    forb: BodyFace.front,
    part: BodyPart.thigh,
    xy: (x: 0.390, y: 0.600),
  ),
  18: Body(
    index: 18,
    name: '내전근',
    forb: BodyFace.front,
    part: BodyPart.thigh,
    xy: (x: 0.390, y: 0.600),
  ),
  19: Body(
    index: 19,
    name: '전경골근',
    forb: BodyFace.front,
    part: BodyPart.shin,
    xy: (x: 0.360, y: 0.770),
  ),
  20: Body(
    index: 20,
    name: '비골근',
    forb: BodyFace.front,
    part: BodyPart.shin,
    xy: (x: 0.360, y: 0.770),
  ),
  21: Body(
    index: 21,
    name: '족저근막',
    forb: BodyFace.front,
    part: BodyPart.sole,
    xy: (x: 0.370, y: 0.935),
  ),
  22: Body(
    index: 22,
    name: '발내재근',
    forb: BodyFace.front,
    part: BodyPart.sole,
    xy: (x: 0.370, y: 0.935),
  ),

  // ─────────── 후면 (뒤) ───────────
  23: Body(
    index: 23,
    name: '후두하근',
    forb: BodyFace.back,
    part: BodyPart.neck,
    xy: (x: 0.465, y: 0.145),
  ),
  24: Body(
    index: 24,
    name: '견갑거근',
    forb: BodyFace.back,
    part: BodyPart.neck,
    xy: (x: 0.465, y: 0.145),
  ),
  25: Body(
    index: 25,
    name: '상부승모근',
    forb: BodyFace.back,
    part: BodyPart.shoulder,
    xy: (x: 0.345, y: 0.220),
  ),
  26: Body(
    index: 26,
    name: '후면삼각근',
    forb: BodyFace.back,
    part: BodyPart.shoulder,
    xy: (x: 0.345, y: 0.220),
  ),
  27: Body(
    index: 27,
    name: '극하근',
    forb: BodyFace.back,
    part: BodyPart.shoulder,
    xy: (x: 0.345, y: 0.220),
  ),
  28: Body(
    index: 28,
    name: '소원근',
    forb: BodyFace.back,
    part: BodyPart.shoulder,
    xy: (x: 0.345, y: 0.220),
  ),
  29: Body(
    index: 29,
    name: '능형근',
    forb: BodyFace.back,
    part: BodyPart.upperBack,
    xy: (x: 0.430, y: 0.260),
  ),
  30: Body(
    index: 30,
    name: '중부승모근',
    forb: BodyFace.back,
    part: BodyPart.upperBack,
    xy: (x: 0.430, y: 0.260),
  ),
  31: Body(
    index: 31,
    name: '대원근',
    forb: BodyFace.back,
    part: BodyPart.upperBack,
    xy: (x: 0.430, y: 0.260),
  ),
  32: Body(
    index: 32,
    name: '광배근',
    forb: BodyFace.back,
    part: BodyPart.upperBack,
    xy: (x: 0.430, y: 0.260),
  ),
  33: Body(
    index: 33,
    name: '상완삼두근',
    forb: BodyFace.back,
    part: BodyPart.arm,
    xy: (x: 0.250, y: 0.330),
  ),
  34: Body(
    index: 34,
    name: '전완신근',
    forb: BodyFace.back,
    part: BodyPart.arm,
    xy: (x: 0.250, y: 0.330),
  ),
  35: Body(
    index: 35,
    name: '척추기립근',
    forb: BodyFace.back,
    part: BodyPart.waist,
    xy: (x: 0.455, y: 0.395),
  ),
  36: Body(
    index: 36,
    name: '요방형근',
    forb: BodyFace.back,
    part: BodyPart.waist,
    xy: (x: 0.455, y: 0.395),
  ),
  37: Body(
    index: 37,
    name: '대둔근',
    forb: BodyFace.back,
    part: BodyPart.hip,
    xy: (x: 0.425, y: 0.490),
  ),
  38: Body(
    index: 38,
    name: '이상근',
    forb: BodyFace.back,
    part: BodyPart.hip,
    xy: (x: 0.425, y: 0.490),
  ),
  39: Body(
    index: 39,
    name: '햄스트링',
    forb: BodyFace.back,
    part: BodyPart.thigh,
    xy: (x: 0.390, y: 0.610),
  ),
  40: Body(
    index: 40,
    name: '비복근',
    forb: BodyFace.back,
    part: BodyPart.calf,
    xy: (x: 0.360, y: 0.780),
  ),
  41: Body(
    index: 41,
    name: '가자미근',
    forb: BodyFace.back,
    part: BodyPart.calf,
    xy: (x: 0.360, y: 0.780),
  ),
  42: Body(
    index: 42,
    name: '아킬레스건',
    forb: BodyFace.back,
    part: BodyPart.heel,
    xy: (x: 0.360, y: 0.885),
  ),
};

/// 인덱스로 단건 조회.
Body? bodyOf(int index) => kBodies[index];

/// 인덱스 목록으로 다건 조회. 없는 인덱스는 건너뛴다.
List<Body> bodiesOf(Iterable<int> indexes) =>
    indexes.map((i) => kBodies[i]).whereType<Body>().toList(growable: false);

/// 전면 / 후면으로 필터.
List<Body> bodiesOfFace(BodyFace face) =>
    kBodies.values.where((b) => b.forb == face).toList(growable: false);

/// 전면·후면 + 부위 구역으로 필터.
List<Body> bodiesOfPart(BodyFace face, BodyPart part) => kBodies.values
    .where((b) => b.forb == face && b.part == part)
    .toList(growable: false);
