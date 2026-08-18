import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_typography.dart';
import '../../models/course_model.dart';
import '../../models/execution_model.dart';
import '../../assets/tool_assets.dart' as tool_assets;
import '../../providers/app_provider.dart';
import '../../services/database_helper.dart';
import '../../services/course_loader.dart';
import '../../services/tool_registration_service.dart';
import '../../widgets/common_widgets.dart';
import '../course/course_summary_screen.dart';
import '../posture/posture_guide_screen.dart';
import '../home/recent_history_screen.dart';
import 'add_tool_screen.dart';
import 'owned_tools_screen.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final ToolRegistrationService _toolService = ToolRegistrationService();

  int _totalExec = 0;
  int _savedCoursesCount = 0;
  double _avgFatigueReduction = 0;
  List<tool_assets.Tool> _ownedTools = [];
  List<(CourseModel, ExecutionModel)> _recentExecutions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final totalExec = await _db.getTotalExecutions();
    final avgReduction = await _db.getAverageFatigueReduction();
    final recentExecutions = await _db.getRecentExecutions(limit: 3);
    final savedCourses = await _db.getSavedCourses();

    // 보유 도구: SharedPreferences에서 인덱스 가져와서 tool_assets로 매핑
    final toolIndexes = await _toolService.getRegisteredTools();
    final ownedTools = tool_assets.toolsOf(toolIndexes);

    setState(() {
      _totalExec = totalExec;
      _savedCoursesCount = savedCourses.length;
      _avgFatigueReduction = avgReduction;
      _ownedTools = ownedTools;
      _recentExecutions = recentExecutions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final userName = provider.currentUser?.name ?? '풀림';

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 사용자 이름
                      Text(
                        '$userName님',
                        style: AppTypography.sb24.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 자세 점검하기 버튼
                      _buildPostureCheckButton(),
                      const SizedBox(height: 20),

                      // 통계 카드 3개
                      _buildStatCards(),
                      const SizedBox(height: 28),

                      // 보유 도구 섹션
                      _buildOwnedToolsSection(),
                      const SizedBox(height: 28),

                      // 최근 기록 섹션
                      _buildRecentRecordsSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPostureCheckButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostureGuideScreen()),
        ).then((_) => _loadData());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              AppStrings.postureCheck,
              style: AppTypography.r14.copyWith(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        StatCard(
          label: AppStrings.totalExec,
          value: '$_totalExec회',
        ),
        const SizedBox(width: 10),
        StatCard(
          label: '저장 코스',
          value: '$_savedCoursesCount개',
        ),
        const SizedBox(width: 10),
        StatCard(
          label: AppStrings.avgFatigueReduction,
          value: _avgFatigueReduction == 0
              ? '-'
              : '-${_avgFatigueReduction.toStringAsFixed(1)}',
        ),
      ],
    );
  }

  Widget _buildOwnedToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.ownedTools,
              style: AppTypography.b18.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OwnedToolsScreen()),
                ).then((_) => _loadData());
              },
              child: Text(
                AppStrings.seeMore,
                style: AppTypography.r12.copyWith(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_ownedTools.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                '등록된 도구가 없습니다',
                style: AppTypography.r14.copyWith(color: AppColors.textTertiary),
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._ownedTools.map((tool) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _ToolImageCard(tool: tool),
                    )),
                // 도구 추가 버튼
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddToolScreen()),
                      ).then((_) => _loadData());
                    },
                    child: Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline,
                              color: AppColors.textTertiary, size: 32),
                          const SizedBox(height: 6),
                          Text('추가',
                              style: AppTypography.r12.copyWith(
                                  color: AppColors.textTertiary, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRecentRecordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.recentRecords,
              style: AppTypography.b18.copyWith(
                color: AppColors.textPrimary,
              ),
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
                AppStrings.seeMore,
                style: AppTypography.r12.copyWith(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentExecutions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '최근 기록이 없습니다',
                style: AppTypography.r14.copyWith(color: AppColors.textTertiary),
              ),
            ),
          )
        else
          ..._recentExecutions.map((record) {
                final course = record.$1;
                final execution = record.$2;
                final timeStr =
                    '${execution.executedAt.month}/${execution.executedAt.day} ${execution.executedAt.hour}:${execution.executedAt.minute.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CourseItemCard(
                    title: course.name,
                    toolInfo: timeStr,
                    duration: course.formattedTime,
                    steps: '${course.totalMove}단계',
                    onTap: () => _showExecuteDialog(course),
                  ),
                );
              }),
      ],
    );
  }

  void _showExecuteDialog(CourseModel courseModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(courseModel.name,
            style: AppTypography.sb18.copyWith(color: AppColors.textPrimary)),
        content: Text(
          '${courseModel.totalMove}단계 · ${courseModel.formattedTime}\n\n이 코스를 실행하시겠습니까?',
          style: AppTypography.r14.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소',
                style: AppTypography.r14.copyWith(color: AppColors.textTertiary)),
          ),
          TextButton(
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
            child: Text('시작하기',
                style: AppTypography.r14.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}


/// 도구 이미지 카드 (실제 이미지 사용)
class _ToolImageCard extends StatelessWidget {
  final tool_assets.Tool tool;

  const _ToolImageCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            tool.imagePath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              tool.category == tool_assets.ToolCategory.foamRoller
                  ? Icons.sports_gymnastics
                  : Icons.circle,
              color: AppColors.textSecondary,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tool.shape.label,
          style: AppTypography.r12.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
