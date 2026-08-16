/// 코스 스텝 모델 (ERD: STEP 테이블)
class StepModel {
  final int? usedId;
  final int courseId;
  final int moveId;
  final int toolId;
  final int order; // 순서
  final int before; // 피로도 전
  final int after; // 피로도 후
  final String? reason; // 추천 사유
  final int time; // 동작시간 (초)

  StepModel({
    this.usedId,
    required this.courseId,
    required this.moveId,
    required this.toolId,
    required this.order,
    this.before = 5,
    this.after = 5,
    this.reason,
    required this.time,
  });

  String get formattedTime {
    final min = time ~/ 60;
    final sec = time % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'used_id': usedId,
      'course_id': courseId,
      'move_id': moveId,
      'tool_id': toolId,
      'order_num': order,
      'before_fatigue': before,
      'after_fatigue': after,
      'reason': reason,
      'time': time,
    };
  }

  factory StepModel.fromMap(Map<String, dynamic> map) {
    return StepModel(
      usedId: map['used_id'] as int?,
      courseId: map['course_id'] as int,
      moveId: map['move_id'] as int,
      toolId: map['tool_id'] as int,
      order: map['order_num'] as int,
      before: map['before_fatigue'] as int? ?? 5,
      after: map['after_fatigue'] as int? ?? 5,
      reason: map['reason'] as String?,
      time: map['time'] as int,
    );
  }

  StepModel copyWith({
    int? usedId,
    int? courseId,
    int? moveId,
    int? toolId,
    int? order,
    int? before,
    int? after,
    String? reason,
    int? time,
  }) {
    return StepModel(
      usedId: usedId ?? this.usedId,
      courseId: courseId ?? this.courseId,
      moveId: moveId ?? this.moveId,
      toolId: toolId ?? this.toolId,
      order: order ?? this.order,
      before: before ?? this.before,
      after: after ?? this.after,
      reason: reason ?? this.reason,
      time: time ?? this.time,
    );
  }
}
