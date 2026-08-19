import '../course_generator/models/course.dart';
import '../course_generator/models/course_step.dart';
import '../models/step_model.dart';
import 'database_helper.dart';

/// DB에 저장된 코스를 Course 객체로 복원하는 유틸리티.
class CourseLoader {
  CourseLoader._();

  /// courseId로 DB에서 코스를 로드하여 Course 객체로 변환.
  static Future<Course?> loadFromDb(int courseId) async {
    final db = DatabaseHelper();
    final courseModel = await db.getCourseById(courseId);
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

  static CourseStep _toStep(StepModel s) {
    return CourseStep(
      moveIndex: s.moveId,
      toolIndex: s.toolId,
      duration: s.time,
      reason: s.reason ?? '',
    );
  }
}
