import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/course_model.dart';
import '../../services/database_helper.dart';
import '../course/course_generation_screen.dart';
import '../posture/posture_guide_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<CourseModel> _recentCourses = [];
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final recent = await _db.getRecentCourses(limit: 1);
    final total = await _db.getTotalExecutions();
    if (mounted) {
      setState(() {
        _recentCourses = recent;
        _streakDays = total;
      });
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
              // 로고
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

              // 주간 캘린더
              _buildWeekCalendar(),
              const SizedBox(height: 16),

              // 연속 운동
              _buildStreakCard(),
              const SizedBox(height: 28),

              // 최근 운동
              _buildRecentSection(),
              const SizedBox(height: 28),

              // 코스 생성 카드 2개
              _buildActionCards(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 주간 캘린더
  Widget _buildWeekCalendar() {
    final now = DateTime.now();
    // 일요일 시작 주간 (Dart weekday: 월=1 ~ 일=7)
    final daysFromSunday = now.weekday == 7 ? 0 : now.weekday;
    final weekStart = now.subtract(Duration(days: daysFromSunday));
    final monthName = DateFormat('MMMM  yyyy').format(now);

    return Column(
      children: [
        // 월 표시
        Row(
          children: [
            GestureDetector(
              onTap: () {},
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
              onTap: () {},
              child: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 요일 + 날짜
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = weekStart.add(Duration(days: i));
            final isToday = day.day == now.day &&
                day.month == now.month &&
                day.year == now.year;
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
                    color: isToday ? AppColors.primary : AppColors.surface,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isToday ? AppColors.background : AppColors.textPrimary,
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

  /// 연속 운동 카드
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
          const Text(
            '연속 운동',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            '$_streakDays',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '일차',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 최근 운동 섹션
  Widget _buildRecentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '최근 운동',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                // 라이브러리로 이동 등
              },
              child: const Text(
                '더보기 >',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
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
              child: Text(
                '아직 운동 기록이 없습니다',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
              ),
            ),
          )
        else
          ..._recentCourses.map((course) => _buildRecentItem(course)),
      ],
    );
  }

  Widget _buildRecentItem(CourseModel course) {
    final dateStr = course.executedAt != null
        ? DateFormat('yyyy.MM.dd\na h:mm').format(course.executedAt!)
        : '';

    return Container(
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
                Text(
                  course.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${course.totalMove}단계 · ${course.formattedTime}',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (dateStr.isNotEmpty)
            Text(
              dateStr,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  /// 코스 생성 / 점검 기반 코스 카드 2개
  Widget _buildActionCards() {
    return Row(
      children: [
        // 코스 생성하기
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
                      color: AppColors.background.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: AppColors.background),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '코스 생성하기',
                    style: TextStyle(
                      color: AppColors.background,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '나에게 맞는 맞춤\n코스를 만들어보세요.',
                    style: TextStyle(
                      color: AppColors.background,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.arrow_forward,
                        color: AppColors.background, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 점검 기반 코스
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostureGuideScreen()),
              );
            },
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
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '점검 기반 코스',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '데이터 기반 맞춤\n코스를 만들어보세요.',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.arrow_forward,
                        color: AppColors.textTertiary, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
