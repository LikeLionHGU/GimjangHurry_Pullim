import 'package:flutter/material.dart';
import '../../assets/move_assets.dart';
import '../../assets/tool_assets.dart';
import '../../course_generator/models/course.dart';
import '../../course_generator/models/course_step.dart';
import '../../services/course_mapper.dart';
import '../../services/database_helper.dart';
import 'course_execution_screen.dart';

/// 코스 생성 결과 화면.
/// 생성된 [Course] 객체의 정보를 표시하고, "코스 시작하기" 버튼을 제공한다.
class CourseResultScreen extends StatelessWidget {
  const CourseResultScreen({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = course.totalDuration ~/ 60;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 AppBar 영역 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '코스 생성 결과',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 뒤로가기 버튼과 대칭
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
                    const Text(
                      '코스가 준비되었습니다',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 코스 요약
                    Text(
                      course.summary,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 총 소요시간 카드 ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            '총 소요시간',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const Spacer(),
                          Text(
                            '$totalMinutes분',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 단계구성 섹션 ──
                    const Text(
                      '단계구성',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '과도한 통증이 느껴지면 즉시 중단하세요.\n이 코스는 의료 진단·치료가 아닙니다.',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                              height: 1.5,
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
                    final courseModel = CourseMapper.toCourseModel(course);
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
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.black),
                  label: const Text(
                    '코스 시작하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBBFF00),
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
    final timeText = '${minutes}분 ${seconds.toString().padLeft(2, '0')}초';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
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
                  color: const Color(0xFFBBFF00),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$order',
                  style: const TextStyle(
                    color: Color(0xFFBBFF00),
                    fontSize: 14,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    moveName,
                    style: TextStyle(
                      color: Colors.grey[400],
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
                Icon(Icons.access_time, color: Colors.grey[500], size: 16),
                const SizedBox(width: 4),
                Text(
                  timeText,
                  style: TextStyle(
                    color: Colors.grey[400],
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
