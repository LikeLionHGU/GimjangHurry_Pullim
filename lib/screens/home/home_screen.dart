import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/course_model.dart';
import '../../providers/app_provider.dart';
import '../../services/database_helper.dart';
import '../../services/course_loader.dart';
import '../../services/posture_to_release_service.dart';
import '../course/course_generation_screen.dart';
import '../course/course_execution_screen.dart';
import '../posture/posture_guide_screen.dart';
import 'recent_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<CourseModel> _recentCourses = [];
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
    final recent = await _db.getRecentCourses(limit: 3);
    final completed = await _db.getCompletedCourses();

    // 운동한 날짜 Set 구성
    final dates = <DateTime>{};
    for (final course in completed) {
      if (course.executedAt != null) {
        final d = course.executedAt!;
        dates.add(DateTime(d.year, d.month, d.day));
      }
    }

    if (mounted) {
      setState(() {
        _recentCourses = recent;
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
        // 측정 기록이 없으면 자세 점검 가이드로 이동
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostureGuideScreen()),
        );
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

      // 실패 시에도 자세 점검 가이드로 fallback
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostureGuideScreen()),
      );
    }
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
              const Text(
                'PULLIM',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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
                  style: TextStyle(
                    color: isToday ? AppColors.primary : AppColors.textTertiary,
                    fontSize: 12,
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
                      style: TextStyle(
                        color: isToday
                            ? AppColors.background
                            : hasExercise
                                ? AppColors.primary
                                : AppColors.textPrimary,
                        fontSize: 14,
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
          const Text('연속 운동',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          Text('$_streakDays',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          const Text('일차',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
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
            const Text('최근 운동',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecentHistoryScreen()),
                ).then((_) => _loadData());
              },
              child: const Text('더보기 >',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentCourses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('아직 운동 기록이 없습니다',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
            ),
          )
        else
          ..._recentCourses.map((course) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildRecentItem(course),
              )),
      ],
    );
  }

  Widget _buildRecentItem(CourseModel course) {
    final dateStr = course.executedAt != null
        ? DateFormat('yyyy.MM.dd\na h:mm').format(course.executedAt!)
        : '';

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
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${course.totalMove}단계 · ${course.formattedTime}',
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 13)),
                ],
              ),
            ),
            if (dateStr.isNotEmpty)
              Text(dateStr,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12),
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
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(courseModel.name,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18)),
        content: Text(
          '${courseModel.totalMove}단계 · ${courseModel.formattedTime}\n\n이 코스를 실행하시겠습니까?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final course = await CourseLoader.loadFromDb(courseModel.courseId!);
              if (course != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseExecutionScreen(
                      course: course,
                      courseId: courseModel.courseId!,
                    ),
                  ),
                ).then((_) => _loadData());
              }
            },
            child: const Text('시작하기',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
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
                  const Text('코스 생성하기',
                      style: TextStyle(color: AppColors.background,
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('나에게 맞는 맞춤\n코스를 만들어보세요.',
                      style: TextStyle(
                          color: AppColors.background, fontSize: 12, height: 1.4)),
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
                  const Text('점검 기반 코스',
                      style: TextStyle(color: AppColors.textPrimary,
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('데이터 기반 맞춤\n코스를 만들어보세요.',
                      style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 12, height: 1.4)),
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
