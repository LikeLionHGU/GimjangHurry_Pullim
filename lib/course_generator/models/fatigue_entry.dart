import '../../assets/body_assets.dart';

/// 피로 부위 입력 단위.
///
/// 사용자는 전면/후면(BodyFace)과 부위 구역(BodyPart)으로 피로 부위를 지정한다.
/// 내부적으로 해당 조합에 속하는 모든 Body 인덱스로 확장된다.
class FatigueEntry {
  const FatigueEntry({
    required this.face,
    required this.part,
    required this.level,
  });

  /// 앞/뒤.
  final BodyFace face;

  /// 몸 부위 구역.
  final BodyPart part;

  /// 피로도 (1: 가장 약함, 10: 매우 심함).
  final int level;

  /// 이 조합에 해당하는 모든 Body 인덱스를 반환한다.
  Set<int> get bodyIndexes =>
      bodiesOfPart(face, part).map((b) => b.index).toSet();

  /// 표시용 라벨. 예: "뒤 - 목"
  String get displayLabel => '${face.label} - ${part.label}';

  @override
  String toString() => 'FatigueEntry($displayLabel, level: $level)';
}
