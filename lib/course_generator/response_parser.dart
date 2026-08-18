import '../assets/move_assets.dart';
import 'models/course.dart';
import 'models/course_request.dart';
import 'models/course_step.dart';
import 'move_filter.dart';

/// OpenAI 응답 JSON을 [Course] 모델로 변환하고 유효성을 검증한다.
///
/// LLM 응답에는 toolIndex가 포함되지 않으므로,
/// 각 동작에 대해 보유 도구 중 최적 도구를 자동 배정한다.
class ResponseParser {
  const ResponseParser({this.moveFilter = const MoveFilter()});

  final MoveFilter moveFilter;

  /// JSON 응답을 [Course]로 파싱하고 유효성을 검증한다.
  Course parseResponse(Map<String, dynamic> json, CourseRequest request) {
    final errors = <String>[];
    final warnings = <String>[];

    final name = json['name'] as String;
    final rawSteps = json['steps'] as List<dynamic>;
    final totalDuration = json['totalDuration'] as int;
    final summary = json['summary'] as String;

    final steps = <CourseStep>[];
    int computedTotal = 0;

    for (var i = 0; i < rawSteps.length; i++) {
      final raw = rawSteps[i] as Map<String, dynamic>;
      final moveIndex = raw['moveIndex'] as int;
      final duration = raw['duration'] as int;
      final reason = raw['reason'] as String;
      final stepLabel = 'Step ${i + 1} (move $moveIndex)';

      // moveIndex 존재 확인
      final move = kMoves[moveIndex];
      if (move == null) {
        errors.add('$stepLabel: 존재하지 않는 동작 인덱스입니다.');
        continue;
      }

      // 도구 자동 배정
      final toolIndex = moveFilter.bestToolForMove(move, request.ownedToolSet);

      // duration 범위 체크
      if (duration < move.time.min || duration > move.time.max) {
        warnings.add(
          '$stepLabel: duration ${duration}초가 허용 범위 '
          '${move.time.min}~${move.time.max}초를 벗어납니다.',
        );
      }

      final step = CourseStep(
        moveIndex: moveIndex,
        toolIndex: toolIndex,
        duration: duration,
        reason: reason,
      );

      steps.add(step);
      computedTotal += duration;
    }

    // 총 시간 검증
    final maxAllowed = (request.availableTime * 1.1).ceil();
    if (computedTotal > maxAllowed) {
      warnings.add(
        '계산된 총 시간($computedTotal초)이 가용 시간(${request.availableTime}초)의 '
        '110%($maxAllowed초)를 초과합니다.',
      );
    }

    if ((totalDuration - computedTotal).abs() > 30) {
      warnings.add(
        'LLM 보고 totalDuration($totalDuration초)과 '
        '실제 계산값($computedTotal초)의 차이가 30초 이상입니다.',
      );
    }

    if (errors.isNotEmpty) {
      throw CourseValidationException(errors: errors, warnings: warnings);
    }

    if (steps.isEmpty) {
      throw CourseValidationException(
        errors: ['코스에 동작이 하나도 없습니다.'],
        warnings: warnings,
      );
    }

    return Course(
      name: name,
      steps: steps,
      totalDuration: computedTotal,
      summary: summary,
      request: request,
    );
  }
}

/// 코스 유효성 검증 실패 예외.
class CourseValidationException implements Exception {
  const CourseValidationException({
    required this.errors,
    this.warnings = const [],
  });

  final List<String> errors;
  final List<String> warnings;

  @override
  String toString() {
    final buffer = StringBuffer('CourseValidationException:\n');
    for (final e in errors) {
      buffer.writeln('  [ERROR] $e');
    }
    for (final w in warnings) {
      buffer.writeln('  [WARN] $w');
    }
    return buffer.toString();
  }
}
