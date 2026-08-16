import 'fatigue_entry.dart';

/// 코스 생성 요청 모델.
///
/// [fatigueEntries]: 피로한 부위 목록 (BodyFace + BodyPart + 피로도).
/// [ownedTools]: 보유한 도구 인덱스 목록.
/// [availableTime]: 가용 시간 (초).
class CourseRequest {
  const CourseRequest({
    required this.fatigueEntries,
    required this.ownedTools,
    required this.availableTime,
  });

  /// 피로 부위 목록. 각 항목은 (앞/뒤, 구역, 피로도)를 포함.
  final List<FatigueEntry> fatigueEntries;

  /// 보유한 도구 인덱스 목록.
  final List<int> ownedTools;

  /// 가용 시간 (초 단위).
  final int availableTime;

  /// 모든 피로 부위에 해당하는 Body 인덱스 Set (확장된 결과).
  Set<int> get fatigueBodyIndexes =>
      fatigueEntries.expand((e) => e.bodyIndexes).toSet();

  /// Body 인덱스 → 해당 피로도. 여러 entry에 겹치면 높은 쪽을 취한다.
  Map<int, int> get fatigueMap {
    final map = <int, int>{};
    for (final entry in fatigueEntries) {
      for (final idx in entry.bodyIndexes) {
        final current = map[idx] ?? 0;
        if (entry.level > current) map[idx] = entry.level;
      }
    }
    return map;
  }

  /// 보유 도구 인덱스 Set.
  Set<int> get ownedToolSet => ownedTools.toSet();

  @override
  String toString() =>
      'CourseRequest(fatigue: $fatigueEntries, tools: $ownedTools, time: ${availableTime}s)';
}
