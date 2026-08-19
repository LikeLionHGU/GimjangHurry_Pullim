import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
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
  int _allCourseCount = 0;
  int _completedCount = 0;
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

    // 완료율 계산용: 전체 코스 수 + 완료 코스 수
    final db = await _db.database;
    final allCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) as cnt FROM courses')) ?? 0;
    final doneCount = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) as cnt FROM courses WHERE status = 'completed'")) ?? 0;

    final toolIndexes = await _toolService.getRegisteredTools();
    final ownedTools = tool_assets.toolsOf(toolIndexes);

    setState(() {
      _totalExec = totalExec;
      _allCourseCount = allCount;
      _completedCount = doneCount;
      _savedCoursesCount = savedCourses.length;
      _avgFatigueReduction = avgReduction;
      _ownedTools = ownedTools;
      _recentExecutions = recentExecutions;
      _isLoading = false;
    });
  }

  /// 완료율 계산
  /// 완료율: 각 코스의 progress 평균
  /// completed 코스 = 100%, pending 코스 = 0%
  int get _completionRate {
    if (_allCourseCount == 0) return 0;
    // completed 코스는 100%, 나머지는 0%
    return (_completedCount * 100 / _allCourseCount).round();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final userName = provider.currentUser?.name ?? '풀림';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          '마이페이지',
          style: AppTypography.sb18.copyWith(color: AppColors.textPrimary),
        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 사용자 이름 (풀림님,)
                      Text(
                        '$userName님,',
                        style: AppTypography.sb24.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 자세 점검하기 버튼
                      _buildPostureCheckButton(),
                      const SizedBox(height: 20),

                      // 통계 카드 3개
                      _buildStatCards(),
                      const SizedBox(height: 32),

                      // 보유 도구 섹션
                      _buildOwnedToolsSection(),
                      const SizedBox(height: 32),

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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: AppStrings.totalExec,
            value: '$_totalExec회',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: '완료율',
            value: '$_completionRate%',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: '평균 피로도 감소',
            value: _avgFatigueReduction == 0
                ? '-'
                : '-${_avgFatigueReduction.toStringAsFixed(1)}',
          ),
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
              style: AppTypography.b18.copyWith(color: AppColors.textPrimary),
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
                style: AppTypography.r12.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
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
            height: 110,
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
                    onTap: () => _showAddToolDialog(),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add_circle_outline,
                              color: AppColors.textTertiary,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '추가',
                          style: AppTypography.r12.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
                AppStrings.seeMore,
                style: AppTypography.r12.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCourseCard(course),
            );
          }),
      ],
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return GestureDetector(
      onTap: () => _showExecuteDialog(course),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: AppTypography.sb16.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getToolInfo(course),
                    style: AppTypography.r12.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildInfoChip(course.formattedTime, isHighlight: true),
                const SizedBox(height: 6),
                _buildInfoChip('${course.totalMove}단계'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, {bool isHighlight = false}) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppColors.toolSelectBox,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.r12.copyWith(
          color: isHighlight ? AppColors.primary : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getToolInfo(CourseModel course) {
    return '폼롤러 + 마사지볼';
  }

  void _showAddToolDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AddToolDialog(
        alreadyOwned: _ownedTools.map((t) => t.index).toList(),
        onAdd: (selectedIndexes) async {
          await _toolService.saveRegisteredTools(selectedIndexes.toList());
          _loadData();
        },
      ),
    );
  }

  void _showExecuteDialog(CourseModel courseModel) {
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
              const SizedBox(height: 24),
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

/// 통계 카드 위젯
class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.r12.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.b20.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 도구 이미지 카드
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
          padding: const EdgeInsets.all(10),
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
