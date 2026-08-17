import 'dart:convert';

/// 코스 상태
enum CourseStatus { pending, running, completed, cancelled }

/// 코스 모델
class CourseModel {
  final int? courseId;
  final String name;
  final int totalTime; // 초 단위
  final int totalMove;
  final String? summary;
  final Map<String, int> before;
  final Map<String, int> after;
  final bool isSaved;
  final DateTime? executedAt;
  final CourseStatus status;
  final int progress; // 0~100 퍼센트

  CourseModel({
    this.courseId,
    required this.name,
    required this.totalTime,
    required this.totalMove,
    this.summary,
    this.before = const {},
    this.after = const {},
    this.isSaved = false,
    this.executedAt,
    this.status = CourseStatus.pending,
    this.progress = 0,
  });

  String get formattedTime {
    final minutes = totalTime ~/ 60;
    return '$minutes분';
  }

  Map<String, dynamic> toMap() {
    return {
      'course_id': courseId,
      'name': name,
      'total_time': totalTime,
      'total_move': totalMove,
      'summary': summary,
      'before': jsonEncode(before),
      'after': jsonEncode(after),
      'save': isSaved ? 1 : 0,
      'executed_at': executedAt?.toIso8601String(),
      'status': status.name,
      'progress': progress,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      courseId: map['course_id'] as int?,
      name: map['name'] as String,
      totalTime: map['total_time'] as int,
      totalMove: map['total_move'] as int,
      summary: map['summary'] as String?,
      before: map['before'] != null
          ? Map<String, int>.from(jsonDecode(map['before'] as String) as Map)
          : const {},
      after: map['after'] != null
          ? Map<String, int>.from(jsonDecode(map['after'] as String) as Map)
          : const {},
      isSaved: (map['save'] as int) == 1,
      executedAt: map['executed_at'] != null
          ? DateTime.parse(map['executed_at'] as String)
          : null,
      status: CourseStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CourseStatus.pending,
      ),
      progress: map['progress'] as int? ?? 0,
    );
  }

  CourseModel copyWith({
    int? courseId,
    String? name,
    int? totalTime,
    int? totalMove,
    String? summary,
    Map<String, int>? before,
    Map<String, int>? after,
    bool? isSaved,
    DateTime? executedAt,
    CourseStatus? status,
    int? progress,
  }) {
    return CourseModel(
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      totalTime: totalTime ?? this.totalTime,
      totalMove: totalMove ?? this.totalMove,
      summary: summary ?? this.summary,
      before: before ?? this.before,
      after: after ?? this.after,
      isSaved: isSaved ?? this.isSaved,
      executedAt: executedAt ?? this.executedAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}
