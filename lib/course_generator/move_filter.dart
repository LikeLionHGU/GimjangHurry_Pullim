import '../assets/move_assets.dart';
import 'models/course_request.dart';

/// 입력 조건(보유 도구, 피로 부위)에 맞는 후보 동작을 필터링한다.
class MoveFilter {
  const MoveFilter();

  /// [request]의 보유 도구로 수행 가능하면서,
  /// 피로 부위에 해당하는 동작만 후보로 추출한다.
  ///
  /// 반환된 리스트는 빈 리스트일 수 있다 (조건에 맞는 동작 없음).
  List<Move> filterCandidates(CourseRequest request) {
    final ownedToolSet = request.ownedToolSet;
    final fatigueBodySet = request.fatigueBodyIndexes;

    // 1. 보유 도구로 수행 가능한 동작 필터
    // 2. 그 중 피로 부위에 해당하는 동작만 추출
    return kMoves.values.where((move) {
      // 동작의 사용 가능 도구 중 하나라도 보유하고 있어야 함
      final hasMatchingTool = move.tool.any(ownedToolSet.contains);
      if (!hasMatchingTool) return false;

      // 동작의 대상 부위 중 하나라도 피로 부위에 포함되어야 함
      final hasMatchingBody = move.body.any(fatigueBodySet.contains);
      return hasMatchingBody;
    }).toList();
  }

  /// 후보 동작 각각에 대해, 보유 도구 중 가장 우선순위가 높은 도구 인덱스를 반환한다.
  /// 동작의 tool 리스트 순서가 우선순위이므로, 보유 도구와 첫 번째로 매칭되는 것을 선택한다.
  int bestToolForMove(Move move, Set<int> ownedToolSet) {
    for (final toolIndex in move.tool) {
      if (ownedToolSet.contains(toolIndex)) return toolIndex;
    }
    // 필터를 통과했으면 반드시 하나는 매칭되므로 여기까지 올 일은 없다.
    return move.tool.first;
  }
}
