/// 코스 상태
enum CourseStatus { pending, completed }

/// 코스 생성 소스 (선택 기반 / 측정 기반).
enum CourseSource {
  manual('선택 기반'),
  posture('측정 기반');

  const CourseSource(this.label);
  final String label;
}

/// 코스 모델 — 코스의 정체성(구조)만 담당.
/// 실행 기록(시간, 피로도)은 [ExecutionModel]이 담당한다.
class CourseModel {
  final int? courseId;
  final String name;
  final int totalTime; // 초 단위
  final int totalMove;
  final String? summary;
  final bool isSaved;
  final CourseStatus status;
  final CourseSource source;

  CourseModel({
    this.courseId,
    required this.name,
    required this.totalTime,
    required this.totalMove,
    this.summary,
    this.isSaved = false,
    this.status = CourseStatus.pending,
    this.source = CourseSource.manual,
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
      'save': isSaved ? 1 : 0,
      'status': status.name,
      'source': source.name,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      courseId: map['course_id'] as int?,
      name: map['name'] as String,
      totalTime: map['total_time'] as int,
      totalMove: map['total_move'] as int,
      summary: map['summary'] as String?,
      isSaved: (map['save'] as int) == 1,
      status: CourseStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CourseStatus.pending,
      ),
      source: CourseSource.values.firstWhere(
        (e) => e.name == (map['source'] as String?),
        orElse: () => CourseSource.manual,
      ),
    );
  }

  CourseModel copyWith({
    int? courseId,
    String? name,
    int? totalTime,
    int? totalMove,
    String? summary,
    bool? isSaved,
    CourseStatus? status,
    CourseSource? source,
  }) {
    return CourseModel(
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      totalTime: totalTime ?? this.totalTime,
      totalMove: totalMove ?? this.totalMove,
      summary: summary ?? this.summary,
      isSaved: isSaved ?? this.isSaved,
      status: status ?? this.status,
      source: source ?? this.source,
    );
  }
}
