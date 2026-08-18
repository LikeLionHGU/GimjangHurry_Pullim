import 'package:flutter/material.dart';
import '../../assets/move_assets.dart';
import '../../assets/tool_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../course_generator/models/course.dart';
import '../../course_generator/models/course_step.dart';
import 'course_execution_screen.dart';

/// 코스 요약 화면.
/// 기존 코스를 다시 실행할 때 코스 구성을 확인하고 시작할 수 있는 화면.
class CourseSummaryScreen extends StatelessWidget {
  const CourseSummaryScreen({
    super.key,
    required this.course,
    required this.courseId,
    this.isAlreadySaved = false,
  });

  final Course course;
  final int courseId;
  final bool isAlreadySaved;

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
                      '코스 요약',
                      textAlign: TextAlign.center,
                      style: AppTypography.sb18.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── 본문 스크롤 영역 ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // 헤딩
                    Text(
                      '코스가 준비되었습니다',
                      style: AppTypography.sb24.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 28),

                    // ── 총 소요시간 카드 ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.toolSelectBox),
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
                            style: AppTypography.b20.copyWith(color: AppColors.textPrimary),
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
                            color: AppColors.error, size: 20),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseExecutionScreen(
                          course: course,
                          courseId: courseId,
                          isReplay: true,
                          isAlreadySaved: isAlreadySaved,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
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
    final timeText = '$minutes분 ${seconds.toString().padLeft(2, '0')}초';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.secondary,
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
