import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../models/course_model.dart';
import '../../models/execution_model.dart';
import '../../providers/app_provider.dart';
import '../../services/database_helper.dart';
import '../../services/course_loader.dart';
import '../../services/posture_to_release_service.dart';
import '../course/course_generation_screen.dart';
import '../course/course_summary_screen.dart';
import '../posture/posture_guide_screen.dart';
import 'recent_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<(CourseModel, ExecutionModel)> _recentExecutions = [];
  int _streakDays = 0;
  Set<DateTime> _exerciseDates = {};

  // 캘린더 주간 이동
  DateTime _currentWeekStart = _getWeekStart(DateTime.now());

  static DateTime _getWeekStart(DateTime date) {
    final daysFromSunday = date.weekday == 7 ? 0 : date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysFromSunday));
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 오늘부터 과거로 연속으로 운동한 일수 계산
  int _calculateStreak(Set<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final today = DateTime.now();
    var current = DateTime(today.year, today.month, today.day);
    int streak = 0;

    // 오늘 운동 안 했으면 어제부터 체크
    if (!dates.contains(current)) {
      current = current.subtract(const Duration(days: 1));
    }

    while (dates.contains(current)) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _loadData() async {
    final recent = await _db.getRecentExecutions(limit: 3);
    final dates = await _db.getExerciseDates();

    if (mounted) {
      setState(() {
        _recentExecutions = recent;
        _streakDays = _calculateStreak(dates);
        _exerciseDates = dates;
      });
    }
  }

  /// 점검 기반 코스: 최신 측정 결과를 분석하여 코스 생성 화면으로 이동.
  Future<void> _onPostureBasedCourse() async {
    final userId = context.read<AppProvider>().currentUser?.userId ?? 1;
    final service = PostureToReleaseService();

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final entries = await service.recommendFromLatest(userId);
      service.dispose();

      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기

      if (entries.isEmpty) {
        // 측정 기록이 없으면 모달 표시
        _showPostureCheckRequiredDialog();
        return;
      }

      // 추천 부위가 선택된 채로 코스 생성 화면 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseGenerationScreen(initialFatigueEntries: entries),
        ),
      );
    } catch (e) {
      service.dispose();
      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기

      // 실패 시에도 모달 표시
      _showPostureCheckRequiredDialog();
    }
  }

  /// 자세 점검 데이터가 없을 때 표시하는 모달
  void _showPostureCheckRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 닫기 버튼
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 타이틀
              Text(
                '자세 점검이 필요해요',
                style: AppTypography.sb24.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // 설명
              Text(
                '맞춤 코스를 생성하려면 먼저 자세 점검 테스트를 완료해 주세요.',
                style: AppTypography.r14.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // 버튼 영역
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        '취소',
                        style: AppTypography.r14.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PostureGuideScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        '점검하기',
                        style: AppTypography.r14.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PULLIM',
                style: AppTypography.sb24.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              _buildWeekCalendar(),
              const SizedBox(height: 16),
              _buildStreakCard(),
              const SizedBox(height: 28),
              _buildRecentSection(),
              const SizedBox(height: 28),
              _buildActionCards(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 주간 캘린더 (좌우 이동 가능 + 운동 날짜 색상 표시)
  Widget _buildWeekCalendar() {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM  yyyy').format(_currentWeekStart);

    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentWeekStart =
                      _currentWeekStart.subtract(const Duration(days: 7));
                });
              },
              child: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            ),
            const Spacer(),
            Text(
              monthName,
              style: AppTypography.sb16.copyWith(color: AppColors.textPrimary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentWeekStart =
                      _currentWeekStart.add(const Duration(days: 7));
                });
              },
              child: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = _currentWeekStart.add(Duration(days: i));
            final isToday = day.year == now.year &&
                day.month == now.month &&
                day.day == now.day;
            final hasExercise = _exerciseDates.contains(
              DateTime(day.year, day.month, day.day),
            );
            final dayLabel = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][i];

            return Column(
              children: [
                Text(
                  dayLabel,
                  style: AppTypography.r12.copyWith(
                    color: isToday ? AppColors.primary : AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday
                        ? AppColors.primary
                        : hasExercise
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AppColors.surface,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: AppTypography.r14.copyWith(
                        color: isToday
                            ? AppColors.background
                            : hasExercise
                                ? AppColors.primary
                                : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Text('연속 운동',
              style: AppTypography.r14.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text('$_streakDays',
              style: AppTypography.sb24.copyWith(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text('일차',
              style: AppTypography.r14.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  /// 최근 운동 섹션 (더보기 → 최근 운동 전체 페이지)
  Widget _buildRecentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('최근 운동',
                style: AppTypography.b18.copyWith(color: AppColors.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecentHistoryScreen()),
                ).then((_) => _loadData());
              },
              child: Text('더보기 >',
                  style: AppTypography.r12.copyWith(color: AppColors.textTertiary, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentExecutions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('아직 운동 기록이 없습니다',
                  style: AppTypography.r14.copyWith(color: AppColors.textTertiary)),
            ),
          )
        else
          ..._recentExecutions.map((record) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildRecentItem(record.$1, record.$2),
              )),
      ],
    );
  }

  Widget _buildRecentItem(CourseModel course, ExecutionModel execution) {
    final dateStr = DateFormat('yyyy.MM.dd\na h:mm').format(execution.executedAt);

    return GestureDetector(
      onTap: () => _showCourseExecuteDialog(course),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.name,
                      style: AppTypography.sb16.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('${course.totalMove}단계 · ${course.formattedTime}',
                      style: AppTypography.r12.copyWith(color: AppColors.textTertiary, fontSize: 13)),
                ],
              ),
            ),
            if (dateStr.isNotEmpty)
              Text(dateStr,
                  style: AppTypography.r12.copyWith(color: AppColors.textTertiary),
                  textAlign: TextAlign.right),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  /// 코스 실행 확인 다이얼로그
  void _showCourseExecuteDialog(CourseModel courseModel) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 닫기 버튼
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 타이틀
              Text(
                '이 코스로 다시 시작할까요?',
                style: AppTypography.sb24.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // 설명
              Text(
                "'${courseModel.name}' (${courseModel.totalMove}단계 · ${courseModel.formattedTime}) 코스를 바로 시작합니다.",
                style: AppTypography.r14.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // 버튼 영역
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        '취소',
                        style: AppTypography.r14.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final course = await CourseLoader.loadFromDb(courseModel.courseId!);
                        if (course != null && mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseSummaryScreen(
                                course: course,
                                courseId: courseModel.courseId!,
                                isAlreadySaved: courseModel.isSaved,
                              ),
                            ),
                          ).then((_) => _loadData());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        '시작하기',
                        style: AppTypography.r14.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CourseGenerationScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: AppColors.background),
                  ),
                  const SizedBox(height: 16),
                  Text('코스 생성하기',
                      style: AppTypography.b16.copyWith(color: AppColors.background)),
                  const SizedBox(height: 4),
                  Text('나에게 맞는 맞춤\n코스를 만들어보세요.',
                      style: AppTypography.r12.copyWith(
                          color: AppColors.background, height: 1.4)),
                  const SizedBox(height: 12),
                  const Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.arrow_forward,
                          color: AppColors.background, size: 20)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _onPostureBasedCourse(),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.assignment,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(height: 16),
                  Text('점검 기반 코스',
                      style: AppTypography.b16.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('데이터 기반 맞춤\n코스를 만들어보세요.',
                      style: AppTypography.r12.copyWith(
                          color: AppColors.textTertiary, height: 1.4)),
                  const SizedBox(height: 12),
                  const Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.arrow_forward,
                          color: AppColors.textTertiary, size: 20)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
