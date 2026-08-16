/// 코스를 구성하는 개별 동작 단계.
class CourseStep {
  const CourseStep({
    required this.moveIndex,
    required this.toolIndex,
    required this.duration,
    required this.reason,
  });

  /// 동작 인덱스 (kMoves 참조).
  final int moveIndex;

  /// 사용할 도구 인덱스 (kTools 참조).
  final int toolIndex;

  /// 이 단계에 배정된 시간 (초).
  final int duration;

  /// LLM이 이 동작을 선택한 이유.
  final String reason;

  /// JSON Map으로부터 생성.
  factory CourseStep.fromJson(Map<String, dynamic> json) {
    return CourseStep(
      moveIndex: json['moveIndex'] as int,
      toolIndex: json['toolIndex'] as int,
      duration: json['duration'] as int,
      reason: json['reason'] as String,
    );
  }

  /// JSON Map으로 변환.
  Map<String, dynamic> toJson() => {
        'moveIndex': moveIndex,
        'toolIndex': toolIndex,
        'duration': duration,
        'reason': reason,
      };

  @override
  String toString() =>
      'CourseStep(move: $moveIndex, tool: $toolIndex, '
      'duration: ${duration}s, reason: $reason)';
}
