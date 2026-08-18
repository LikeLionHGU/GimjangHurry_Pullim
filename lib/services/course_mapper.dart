import '../assets/body_assets.dart';
import '../course_generator/models/course.dart';
import '../course_generator/models/course_step.dart';
import '../models/course_model.dart';
import '../models/step_model.dart';

/// AI 코스 생성 객체 → DB 모델 변환 유틸리티.
class CourseMapper {
  const CourseMapper._();

  /// [Course] → [CourseModel] 변환.
  /// DB 저장 전 사용한다. courseId는 null (INSERT 시 자동 생성).
  /// [source]로 코스 생성 소스(선택 기반/측정 기반)를 지정한다.
  static CourseModel toCourseModel(
    Course course, {
    CourseSource source = CourseSource.manual,
  }) {
    return CourseModel(
      name: course.name,
      totalTime: course.totalDuration,
      totalMove: course.steps.length,
      summary: course.summary,
      source: source,
    );
  }

  /// [Course]에서 before 피로도 맵을 추출한다.
  /// 첫 실행 시 ExecutionModel.before에 사용.
  static Map<String, int> extractBeforeFatigue(Course course) {
    final fatigueMap = <String, int>{};
    final request = course.request;
    if (request != null) {
      for (final entry in request.fatigueEntries) {
        final face = entry.face == BodyFace.front ? 'front' : 'back';
        final part = entry.part.name;
        final key = '${face}_$part';
        final current = fatigueMap[key] ?? 0;
        if (entry.level > current) {
          fatigueMap[key] = entry.level;
        }
      }
    }
    return fatigueMap;
  }

  /// [CourseStep] 리스트 → [StepModel] 리스트 변환.
  /// [courseId]는 CourseModel INSERT 후 반환된 ID를 전달한다.
  static List<StepModel> toStepModels(
    List<CourseStep> steps, {
    required int courseId,
  }) {
    return List.generate(steps.length, (i) {
      final step = steps[i];
      return StepModel(
        courseId: courseId,
        moveId: step.moveIndex,
        toolId: step.toolIndex,
        order: i + 1,
        reason: step.reason,
        time: step.duration,
      );
    });
  }
}
