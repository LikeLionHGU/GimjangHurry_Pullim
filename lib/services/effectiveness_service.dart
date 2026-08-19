import '../assets/body_assets.dart';
import '../assets/move_assets.dart';
import '../models/step_model.dart';
import 'database_helper.dart';

/// 동작 하나에 대한 부위별 효과 정보.
class MoveEffect {
  const MoveEffect({
    required this.moveIndex,
    required this.moveName,
    required this.avgReduction,
    required this.count,
  });

  /// 동작 인덱스 (kMoves 키).
  final int moveIndex;

  /// 동작 이름.
  final String moveName;

  /// 해당 부위에서의 평균 피로도 감소량 (양수 = 개선).
  final double avgReduction;

  /// 이 동작이 해당 부위에 적용된 횟수.
  final int count;
}

/// 특정 부위에 대한 효과 요약.
class PartEffectiveness {
  const PartEffectiveness({
    required this.partKey,
    required this.partLabel,
    required this.sampleCount,
    required this.avgReduction,
    required this.moves,
  });

  /// 부위 키 (예: "back_shoulder").
  final String partKey;

  /// 부위 한글 라벨 (예: "어깨").
  final String partLabel;

  /// 해당 부위에 대한 유효 실행 기록 수.
  final int sampleCount;

  /// 전체 평균 피로도 감소량.
  final double avgReduction;

  /// 동작별 효과 리스트 (감소량 높은 순 정렬).
  final List<MoveEffect> moves;
}

/// 사용자의 과거 실행 이력에서 부위별 동작 효과를 계산하는 서비스.
///
/// - 최근 30일 이내 기록만 대상
/// - 선택한 부위에 대해 유효한(before/after 모두 존재) 기록이 3개 초과(4건 이상)일 때만 결과 포함
class EffectivenessService {
  EffectivenessService({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  final DatabaseHelper _db;

  /// 부위 키 Set(예: {"back_neck", "front_shoulder"})에 대해 효과 정보를 계산한다.
  ///
  /// 조건 미충족 부위는 결과에 포함하지 않는다.
  /// 반환: 부위 키 → PartEffectiveness. 조건 충족 부위만 포함.
  Future<Map<String, PartEffectiveness>> calculate(
    Set<String> targetPartKeys,
  ) async {
    if (targetPartKeys.isEmpty) return {};

    // 1. 최근 30일 이내 실행 기록 조회
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final allExecutions = await _db.getAllExecutions();

    // 30일 이내 + before/after 모두 비어있지 않은 기록만 필터
    final validExecutions = allExecutions.where((record) {
      final (_, execution) = record;
      return execution.executedAt.isAfter(cutoff) &&
          execution.before.isNotEmpty &&
          execution.after.isNotEmpty;
    }).toList();

    if (validExecutions.isEmpty) return {};

    // 2. 부위별로 유효 기록 수 카운트 및 데이터 수집
    //    partKey → [ (execution, courseId) ] (해당 부위의 before 키를 포함하는 기록들)
    final partRecords = <String, List<_ExecutionRecord>>{};

    for (final (course, execution) in validExecutions) {
      for (final key in targetPartKeys) {
        if (execution.before.containsKey(key) &&
            execution.after.containsKey(key)) {
          partRecords.putIfAbsent(key, () => []).add(
            _ExecutionRecord(
              courseId: course.courseId!,
              beforeValue: execution.before[key]!,
              afterValue: execution.after[key]!,
            ),
          );
        }
      }
    }

    // 3. 3개 초과(4건 이상) 조건 필터
    partRecords.removeWhere((_, records) => records.length <= 3);

    if (partRecords.isEmpty) return {};

    // 4. 관련된 코스들의 steps를 한 번에 조회
    final relevantCourseIds = <int>{};
    for (final records in partRecords.values) {
      for (final r in records) {
        relevantCourseIds.add(r.courseId);
      }
    }

    final stepsCache = <int, List<StepModel>>{};
    for (final courseId in relevantCourseIds) {
      stepsCache[courseId] = await _db.getStepsByCourse(courseId);
    }

    // 5. 부위별 동작 효과 집계
    final result = <String, PartEffectiveness>{};

    for (final entry in partRecords.entries) {
      final partKey = entry.key;
      final records = entry.value;

      // 전체 평균 감소량
      final totalReduction = records.fold<int>(
        0,
        (sum, r) => sum + (r.beforeValue - r.afterValue),
      );
      final avgReduction = totalReduction / records.length;

      // 동작별 감소량 집계
      // moveIndex → [감소량 리스트]
      final moveReductions = <int, List<int>>{};

      for (final record in records) {
        final steps = stepsCache[record.courseId] ?? [];
        final reduction = record.beforeValue - record.afterValue;

        for (final step in steps) {
          // 이 동작이 해당 부위를 타겟하는지 확인
          if (_moveTargetsPart(step.moveId, partKey)) {
            moveReductions.putIfAbsent(step.moveId, () => []).add(reduction);
          }
        }
      }

      // MoveEffect 리스트 생성 (감소량 높은 순)
      final moveEffects = moveReductions.entries.map((e) {
        final moveIndex = e.key;
        final reductions = e.value;
        final move = kMoves[moveIndex];
        return MoveEffect(
          moveIndex: moveIndex,
          moveName: move?.name ?? '동작 $moveIndex',
          avgReduction: reductions.reduce((a, b) => a + b) / reductions.length,
          count: reductions.length,
        );
      }).toList()
        ..sort((a, b) => b.avgReduction.compareTo(a.avgReduction));

      // 한글 라벨 추출
      final partLabel = _partLabel(partKey);

      result[partKey] = PartEffectiveness(
        partKey: partKey,
        partLabel: partLabel,
        sampleCount: records.length,
        avgReduction: avgReduction,
        moves: moveEffects,
      );
    }

    return result;
  }

  /// 동작이 특정 face_part 키의 부위를 타겟하는지 확인.
  bool _moveTargetsPart(int moveId, String partKey) {
    final move = kMoves[moveId];
    if (move == null) return false;

    for (final bodyIdx in move.body) {
      final body = kBodies[bodyIdx];
      if (body == null) continue;
      final key =
          '${body.forb == BodyFace.front ? "front" : "back"}_${body.part.name}';
      if (key == partKey) return true;
    }
    return false;
  }

  /// face_part 키에서 한글 라벨을 추출.
  String _partLabel(String key) {
    final parts = key.split('_');
    if (parts.length < 2) return key;
    final partName = parts.sublist(1).join('_');
    const labels = {
      'neck': '목',
      'shoulder': '어깨',
      'chest': '가슴',
      'arm': '팔',
      'abdomen': '복부',
      'pelvis': '골반',
      'thigh': '허벅지',
      'shin': '정강이',
      'sole': '발바닥',
      'upperBack': '등',
      'waist': '허리',
      'hip': '엉덩이',
      'calf': '종아리',
      'heel': '발뒤',
    };
    return labels[partName] ?? partName;
  }
}

/// 내부 헬퍼: 실행 기록 1건에서 특정 부위의 before/after 값.
class _ExecutionRecord {
  const _ExecutionRecord({
    required this.courseId,
    required this.beforeValue,
    required this.afterValue,
  });

  final int courseId;
  final int beforeValue;
  final int afterValue;
}
