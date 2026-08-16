import 'course_step.dart';

/// 생성된 근막이완 코스.
class Course {
  const Course({
    required this.steps,
    required this.totalDuration,
    required this.summary,
  });

  /// 코스를 구성하는 동작 단계 리스트 (순서대로).
  final List<CourseStep> steps;

  /// 총 소요 시간 (초). 편측 동작의 양쪽 수행 시간 포함.
  final int totalDuration;

  /// 코스 요약 설명 (LLM 생성).
  final String summary;

  /// JSON Map으로부터 생성.
  factory Course.fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List<dynamic>)
        .map((e) => CourseStep.fromJson(e as Map<String, dynamic>))
        .toList();
    return Course(
      steps: steps,
      totalDuration: json['totalDuration'] as int,
      summary: json['summary'] as String,
    );
  }

  /// JSON Map으로 변환.
  Map<String, dynamic> toJson() => {
        'steps': steps.map((s) => s.toJson()).toList(),
        'totalDuration': totalDuration,
        'summary': summary,
      };

  @override
  String toString() =>
      'Course(steps: ${steps.length}, totalDuration: ${totalDuration}s)\n'
      'Summary: $summary';
}
