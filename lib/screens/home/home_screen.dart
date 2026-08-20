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

  int _calculateStreak(Set<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final today = DateTime.now();
    var current = DateTime(today.year, today.month, today.day);
    int streak = 0;

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
    final recent = await _db.getRecentExecutions(limit: 1);
    final dates = await _db.getExerciseDates();

    if (mounted) {
      setState(() {
        _recentExecutions = recent;
        _streakDays = _calculateStreak(dates);
        _exerciseDates = dates;
      });
    }
  }

  Future<void> _onPostureBasedCourse() async {
    final userId = context.read<AppProvider>().currentUser?.userId ?? 1;
    final db = DatabaseHelper();
    final latestResult = await db.getLatestPostureResult(userId);

    if (!mounted) return;

    if (latestResult == null || latestResult.issues.isEmpty) {
      _showPostureCheckRequiredDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _PostureRecommendLoadingScreen(),
      ),
    );
  }

  void _showPostureCheckRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close, color: AppColors.textPrimary, size: 24),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '자세 점검이 필요해요',
                style: AppTypography.sb24.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                '맞춤 코스를 생성하려면 먼저 자세 점검 테스트를 완료해 주세요.',
                style: AppTypography.r14.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textPrimary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('취소', style: AppTypography.r14.copyWith(color: AppColors.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PostureGuideScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('점검하기', style: AppTypography.r14.copyWith(color: AppColors.background, fontWeight: FontWeight.w600)),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  kBottomNavigationBarHeight - 56,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PULLIM 로고 타이틀
                  Image.asset(
                    'assets/images/logo2.png',
                    height: 34,
                  ),
                  const SizedBox(height: 26),

                  // 주간 캘린더
                  _buildWeekCalendar(),
                  const SizedBox(height: 28),

                  // 연속 운동 카드
                  _buildStreakCard(),
                  const SizedBox(height: 26),

                  // 최근 운동 섹션 (1개만)
                  _buildRecentSectionFixed(_recentExecutions.take(1).toList()),

                  const SizedBox(height: 24),

                  // 액션 카드 (코스 생성 + 점검 기반 코스)
                  _buildActionCards(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // 주간 캘린더
  // ──────────────────────────────────────────────────────────────

  Widget _buildWeekCalendar() {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM  yyyy').format(_currentWeekStart);

    return Column(
      children: [
        // 월 이름 + 좌우 화살표
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
                });
              },
              child: const Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 24),
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
                  _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
                });
              },
              child: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 요일 라벨 + 날짜 원형
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

            // 색상 로직:
            // 운동 완료한 날 (오늘 포함) → 꽉 찬 녹색
            // 오늘인데 운동 안 함 → 투명한 녹색
            // 나머지 → 기본 surface
            final Color circleColor;
            final Color textColor;
            if (hasExercise) {
              circleColor = AppColors.primary;
              textColor = AppColors.background;
            } else if (isToday) {
              circleColor = AppColors.primary.withValues(alpha: 0.2);
              textColor = AppColors.primary;
            } else {
              circleColor = AppColors.surface;
              textColor = AppColors.textPrimary;
            }

            final Color labelColor = (isToday || hasExercise)
                ? AppColors.primary
                : AppColors.textTertiary;

            return SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    dayLabel,
                    style: AppTypography.r12.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleColor,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: AppTypography.r14.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // 연속 운동 카드
  // ──────────────────────────────────────────────────────────────

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 불꽃 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '연속 운동',
            style: AppTypography.r14.copyWith(color: AppColors.primary),
          ),
          const Spacer(),
          Text(
            '$_streakDays',
            style: AppTypography.b32.copyWith(
              color: AppColors.primary,
              fontSize: 30,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '일차',
            style: AppTypography.r14.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // 최근 운동 섹션
  // ──────────────────────────────────────────────────────────────

  Widget _buildRecentSectionFixed(List<(CourseModel, ExecutionModel)> recentToShow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '최근 운동',
              style: AppTypography.b18.copyWith(color: AppColors.textPrimary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecentHistoryScreen()),
                ).then((_) => _loadData());
              },
              child: Text(
                '더보기 >',
                style: AppTypography.r12.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
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
              child: Text(
                '아직 운동 기록이 없습니다',
                style: AppTypography.r14.copyWith(color: AppColors.textTertiary),
              ),
            ),
          )
        else
          ...recentToShow.map((record) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildRecentItem(record.$1, record.$2),
              )),
      ],
    );
  }

  Widget _buildRecentItem(CourseModel course, ExecutionModel execution) {
    final dateStr = DateFormat('yyyy.MM.dd').format(execution.executedAt);
    final hour = execution.executedAt.hour;
    final minute = execution.executedAt.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeStr = '$period $displayHour:$minute';

    return GestureDetector(
      onTap: () => _showCourseExecuteDialog(course),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 왼쪽: 코스 이름 + 단계/시간
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: AppTypography.sb16.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${course.totalMove}단계 · ${course.formattedTime}',
                    style: AppTypography.r12.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // 세로 구분선
            Container(
              width: 1,
              height: 36,
              color: AppColors.toolSelectBox,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),

            // 오른쪽: 날짜 + 시간
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: AppTypography.r12.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: AppTypography.r12.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // 액션 카드
  // ──────────────────────────────────────────────────────────────

  Widget _buildActionCards() {
    return Row(
      children: [
        // 코스 생성하기 (라임 그린 카드)
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CourseGenerationScreen()),
              );
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: AppColors.primary, size: 25),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '코스 생성하기',
                    style: AppTypography.b16.copyWith(color: AppColors.background),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '나에게 맞는 맞춤\n코스를 만들어보세요.',
                    style: AppTypography.r12.copyWith(
                      color: AppColors.background.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.arrow_forward,
                      color: AppColors.background.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 점검 기반 코스 (다크 카드)
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '점검 기반 코스',
                    style: AppTypography.b16.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '데이터 기반 맞춤\n코스를 만들어보세요.',
                    style: AppTypography.r12.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.arrow_forward,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // 코스 실행 확인 다이얼로그
  // ──────────────────────────────────────────────────────────────

  void _showCourseExecuteDialog(CourseModel courseModel) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close, color: AppColors.textPrimary, size: 24),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '이 코스로 다시 시작할까요?',
                style: AppTypography.sb24.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                "'${courseModel.name}' (${courseModel.totalMove}단계 · ${courseModel.formattedTime}) 코스를 바로 시작합니다.",
                style: AppTypography.r14.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textPrimary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('취소', style: AppTypography.r14.copyWith(color: AppColors.textPrimary)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('시작하기', style: AppTypography.r14.copyWith(color: AppColors.background, fontWeight: FontWeight.w600)),
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
}

/// 점검 기반 코스 추천 부위를 불러오는 로딩 화면.
class _PostureRecommendLoadingScreen extends StatefulWidget {
  const _PostureRecommendLoadingScreen();

  @override
  State<_PostureRecommendLoadingScreen> createState() =>
      _PostureRecommendLoadingScreenState();
}

class _PostureRecommendLoadingScreenState
    extends State<_PostureRecommendLoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AppProvider>().currentUser?.userId ?? 1;
    final service = PostureToReleaseService();

    try {
      final entries = await service.recommendFromLatest(userId);
      service.dispose();

      if (!mounted) return;

      if (entries.isEmpty) {
        Navigator.pop(context);
        _showPostureCheckRequiredDialog();
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CourseGenerationScreen(initialFatigueEntries: entries),
        ),
      );
    } catch (e) {
      service.dispose();
      if (!mounted) return;
      Navigator.pop(context);
      _showPostureCheckRequiredDialog();
    }
  }

  void _showPostureCheckRequiredDialog() {
    final navContext = context;
    showDialog(
      context: navContext,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close, color: AppColors.textPrimary, size: 24),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '자세 점검이 필요해요',
                style: AppTypography.sb24.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                '맞춤 코스를 생성하려면 먼저 자세 점검 테스트를 완료해 주세요.',
                style: AppTypography.r14.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textPrimary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('취소', style: AppTypography.r14.copyWith(color: AppColors.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(navContext, MaterialPageRoute(builder: (_) => const PostureGuideScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('점검하기', style: AppTypography.r14.copyWith(color: AppColors.background, fontWeight: FontWeight.w600)),
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
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF0C1500),
              Color(0xFF010101),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                ),
                Text(
                  'LOADING · · ·',
                  style: AppTypography.b20.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
