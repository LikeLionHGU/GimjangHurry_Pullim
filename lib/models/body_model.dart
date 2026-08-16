/// 신체 부위 모델
class BodyPart {
  final int? bodyId;
  final String name;
  final String muscle;
  final bool isFront; // true = 전면, false = 후면
  final double x;
  final double y;

  BodyPart({
    this.bodyId,
    required this.name,
    required this.muscle,
    required this.isFront,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toMap() {
    return {
      'body_id': bodyId,
      'name': name,
      'muscle': muscle,
      'front_back': isFront ? 1 : 0,
      'x': x,
      'y': y,
    };
  }

  factory BodyPart.fromMap(Map<String, dynamic> map) {
    return BodyPart(
      bodyId: map['body_id'] as int?,
      name: map['name'] as String,
      muscle: map['muscle'] as String,
      isFront: (map['front_back'] as int) == 1,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
    );
  }
}

/// 사전 정의된 신체 부위 목록
class BodyParts {
  BodyParts._();

  static final List<BodyPart> frontParts = [
    BodyPart(bodyId: 1, name: '목', muscle: '목 근육', isFront: true, x: 0.5, y: 0.08),
    BodyPart(bodyId: 2, name: '어깨', muscle: '삼각근', isFront: true, x: 0.3, y: 0.15),
    BodyPart(bodyId: 3, name: '어깨', muscle: '삼각근', isFront: true, x: 0.7, y: 0.15),
    BodyPart(bodyId: 4, name: '가슴', muscle: '대흉근', isFront: true, x: 0.5, y: 0.22),
    BodyPart(bodyId: 5, name: '팔', muscle: '이두근', isFront: true, x: 0.2, y: 0.3),
    BodyPart(bodyId: 6, name: '팔', muscle: '이두근', isFront: true, x: 0.8, y: 0.3),
    BodyPart(bodyId: 7, name: '복부', muscle: '복직근', isFront: true, x: 0.5, y: 0.35),
    BodyPart(bodyId: 8, name: '고관절', muscle: '장요근', isFront: true, x: 0.4, y: 0.45),
    BodyPart(bodyId: 9, name: '고관절', muscle: '장요근', isFront: true, x: 0.6, y: 0.45),
    BodyPart(bodyId: 10, name: '허벅지', muscle: '대퇴사두근', isFront: true, x: 0.35, y: 0.58),
    BodyPart(bodyId: 11, name: '허벅지', muscle: '대퇴사두근', isFront: true, x: 0.65, y: 0.58),
    BodyPart(bodyId: 12, name: '종아리', muscle: '전경골근', isFront: true, x: 0.35, y: 0.78),
    BodyPart(bodyId: 13, name: '종아리', muscle: '전경골근', isFront: true, x: 0.65, y: 0.78),
    BodyPart(bodyId: 14, name: '발', muscle: '족저근막', isFront: true, x: 0.35, y: 0.93),
    BodyPart(bodyId: 15, name: '발', muscle: '족저근막', isFront: true, x: 0.65, y: 0.93),
  ];

  static final List<BodyPart> backParts = [
    BodyPart(bodyId: 16, name: '목 뒤', muscle: '승모근 상부', isFront: false, x: 0.5, y: 0.08),
    BodyPart(bodyId: 17, name: '어깨 뒤', muscle: '승모근', isFront: false, x: 0.3, y: 0.15),
    BodyPart(bodyId: 18, name: '어깨 뒤', muscle: '승모근', isFront: false, x: 0.7, y: 0.15),
    BodyPart(bodyId: 19, name: '등 상부', muscle: '능형근', isFront: false, x: 0.5, y: 0.22),
    BodyPart(bodyId: 20, name: '등 중부', muscle: '광배근', isFront: false, x: 0.5, y: 0.32),
    BodyPart(bodyId: 21, name: '허리', muscle: '요방형근', isFront: false, x: 0.5, y: 0.4),
    BodyPart(bodyId: 22, name: '둔근', muscle: '대둔근', isFront: false, x: 0.35, y: 0.48),
    BodyPart(bodyId: 23, name: '둔근', muscle: '대둔근', isFront: false, x: 0.65, y: 0.48),
    BodyPart(bodyId: 24, name: '허벅지 뒤', muscle: '햄스트링', isFront: false, x: 0.35, y: 0.6),
    BodyPart(bodyId: 25, name: '허벅지 뒤', muscle: '햄스트링', isFront: false, x: 0.65, y: 0.6),
    BodyPart(bodyId: 26, name: '종아리 뒤', muscle: '비복근', isFront: false, x: 0.35, y: 0.78),
    BodyPart(bodyId: 27, name: '종아리 뒤', muscle: '비복근', isFront: false, x: 0.65, y: 0.78),
  ];
}
