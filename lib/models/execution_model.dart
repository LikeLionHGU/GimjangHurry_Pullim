import 'dart:convert';

/// 코스 실행 기록 모델.
/// 하나의 코스에 대해 여러 실행 기록이 존재할 수 있다 (1:N 관계).
class ExecutionModel {
  final int? executionId;
  final int courseId;
  final DateTime executedAt;
  final Map<String, int> before;
  final Map<String, int> after;

  ExecutionModel({
    this.executionId,
    required this.courseId,
    DateTime? executedAt,
    this.before = const {},
    this.after = const {},
  }) : executedAt = executedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'execution_id': executionId,
      'course_id': courseId,
      'executed_at': executedAt.toIso8601String(),
      'before': jsonEncode(before),
      'after': jsonEncode(after),
    };
  }

  factory ExecutionModel.fromMap(Map<String, dynamic> map) {
    return ExecutionModel(
      executionId: map['execution_id'] as int?,
      courseId: map['course_id'] as int,
      executedAt: DateTime.parse(map['executed_at'] as String),
      before: map['before'] != null && (map['before'] as String).isNotEmpty
          ? Map<String, int>.from(jsonDecode(map['before'] as String) as Map)
          : const {},
      after: map['after'] != null && (map['after'] as String).isNotEmpty
          ? Map<String, int>.from(jsonDecode(map['after'] as String) as Map)
          : const {},
    );
  }

  ExecutionModel copyWith({
    int? executionId,
    int? courseId,
    DateTime? executedAt,
    Map<String, int>? before,
    Map<String, int>? after,
  }) {
    return ExecutionModel(
      executionId: executionId ?? this.executionId,
      courseId: courseId ?? this.courseId,
      executedAt: executedAt ?? this.executedAt,
      before: before ?? this.before,
      after: after ?? this.after,
    );
  }
}
