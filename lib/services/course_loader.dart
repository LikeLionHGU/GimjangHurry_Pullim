import '../course_generator/models/course.dart';
import '../course_generator/models/course_step.dart';
import '../models/course_model.dart';
import '../models/step_model.dart';
import 'database_helper.dart';

/// DB에 저장된 코스를 Course 객체로 복원하는 유틸리티.
class CourseLoader {
  CourseLoader._();

  /// courseId로 DB에서 코스를 로드하여 Course 객체로 변환.
  static Future<Course?> loadFromDb(int courseId) async {
    final db = DatabaseHelper();
    final courseModel = await db.getSavedCourseById(courseId);
    if (courseModel == null) return null;

    final stepModels = await db.getStepsByCourse(courseId);
    final steps = stepModels.map((s) => _toStep(s)).toList();

    return Course(
      name: courseModel.name,
      steps: steps,
      totalDuration: courseModel.totalTime,
      summary: courseModel.summary ?? '',
    );
  }

  /// 기존 코스를 복제해서 새 row를 INSERT하고, 새 courseId를 반환.
  /// 코스를 다시 실행할 때 사용 (실행 횟수를 늘리기 위해).
  static Future<int> duplicateForReplay(int originalCourseId) async {
    final db = DatabaseHelper();
    final original = await db.getSavedCourseById(originalCourseId);
    if (original == null) return originalCourseId;

    // 새 코스 row 생성 (pending 상태)
    final newCourse = CourseModel(
      name: original.name,
      totalTime: original.totalTime,
      totalMove: original.totalMove,
      summary: original.summary,
      before: original.before,
      after: const {},
      isSaved: false,
      status: CourseStatus.pending,
      progress: 0,
    );

    final newCourseId = await db.insertCourse(newCourse);

    // 스텝도 복제
    final steps = await db.getStepsByCourse(originalCourseId);
    for (final step in steps) {
      final newStep = StepModel(
        courseId: newCourseId,
        moveId: step.moveId,
        toolId: step.toolId,
        order: step.order,
        reason: step.reason,
        time: step.time,
      );
      await db.insertStep(newStep);
    }

    return newCourseId;
  }

  static CourseStep _toStep(StepModel s) {
    return CourseStep(
      moveIndex: s.moveId,
      toolIndex: s.toolId,
      duration: s.time,
      reason: s.reason ?? '',
    );
  }
}
