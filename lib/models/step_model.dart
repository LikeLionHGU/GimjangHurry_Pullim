/// 코스 스텝 모델 (ERD: STEP 테이블)
class StepModel {
  final int? usedId;
  final int courseId;
  final int moveId;
  final int toolId;
  final int order; // 순서
  final String? reason; // 추천 사유
  final int time; // 동작시간 (초)

  StepModel({
    this.usedId,
    required this.courseId,
    required this.moveId,
    required this.toolId,
    required this.order,
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
    String? reason,
    int? time,
  }) {
    return StepModel(
      usedId: usedId ?? this.usedId,
      courseId: courseId ?? this.courseId,
      moveId: moveId ?? this.moveId,
      toolId: toolId ?? this.toolId,
      order: order ?? this.order,
      reason: reason ?? this.reason,
      time: time ?? this.time,
    );
  }
}
