import 'package:flutter/material.dart';
import '../../assets/move_assets.dart';
import '../../assets/tool_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../course_generator/models/course.dart';
import '../../course_generator/models/course_step.dart';
import '../../models/course_model.dart';
import '../../services/course_mapper.dart';
import '../../services/database_helper.dart';
import 'course_execution_screen.dart';

/// 코스 생성 결과 화면.
/// 생성된 [Course] 객체의 정보를 표시하고, "코스 시작하기" 버튼을 제공한다.
class CourseResultScreen extends StatelessWidget {
  const CourseResultScreen({
    super.key,
    required this.course,
    this.isPostureBased = false,
  });

  final Course course;
  final bool isPostureBased;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = course.totalDuration ~/ 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 AppBar 영역 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      '코스 생성 결과',
                      textAlign: TextAlign.center,
                      style: AppTypography.sb18.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 48), // 뒤로가기 버튼과 대칭
                ],
              ),
            ),

            // ── 본문 스크롤 영역 ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // 헤딩
                    Text(
                      '코스가 준비되었습니다',
                      style: AppTypography.sb24.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    // 코스 요약
                    Text(
                      course.summary,
                      style: AppTypography.r14.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 총 소요시간 카드 ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '총 소요시간',
                            style: AppTypography.r14.copyWith(color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          Text(
                            '$totalMinutes분',
                            style: AppTypography.b20.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 단계구성 섹션 ──
                    Text(
                      '단계구성',
                      style: AppTypography.b18.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(course.steps.length, (index) {
                      return _buildStepCard(course.steps[index], index + 1);
                    }),
                    const SizedBox(height: 24),

                    // ── 경고 문구 ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '과도한 통증이 느껴지면 즉시 중단하세요.\n이 코스는 의료 진단·치료가 아닙니다.',
                            style: AppTypography.r12.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── 하단 고정 버튼 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 코스 정보를 DB에 저장
                    final db = DatabaseHelper();
                    final courseModel = CourseMapper.toCourseModel(
                      course,
                      source: isPostureBased
                          ? CourseSource.posture
                          : CourseSource.manual,
                    );
                    final courseId = await db.insertCourse(courseModel);
                    final stepModels = CourseMapper.toStepModels(
                      course.steps,
                      courseId: courseId,
                    );
                    for (final step in stepModels) {
                      await db.insertStep(step);
                    }

                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseExecutionScreen(
                          course: course,
                          courseId: courseId,
                          isPostureBased: isPostureBased,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, color: AppColors.background),
                  label: Text(
                    '코스 시작하기',
                    style: AppTypography.b16.copyWith(color: AppColors.background),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 개별 단계 카드 위젯.
  Widget _buildStepCard(CourseStep step, int order) {
    final move = kMoves[step.moveIndex];
    final tool = kTools[step.toolIndex];

    final moveName = move?.name ?? '동작 ${step.moveIndex}';
    final toolCategoryName = tool?.category.label ?? '도구 ${step.toolIndex}';

    final minutes = step.duration ~/ 60;
    final seconds = step.duration % 60;
    final timeText = '${minutes}분 ${seconds.toString().padLeft(2, '0')}초';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 순서 번호 원형 뱃지
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$order',
                  style: AppTypography.r14.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // 도구 카테고리 + 동작 이름
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toolCategoryName,
                    style: AppTypography.sb16.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    moveName,
                    style: AppTypography.r12.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // 소요시간
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 4),
                Text(
                  timeText,
                  style: AppTypography.r12.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
