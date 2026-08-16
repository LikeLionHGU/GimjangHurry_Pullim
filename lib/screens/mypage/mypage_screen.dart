import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/course_model.dart';
import '../../models/tool_model.dart';
import '../../providers/app_provider.dart';
import '../../services/database_helper.dart';
import '../../widgets/common_widgets.dart';
import '../posture/posture_screen.dart';
import 'owned_tools_screen.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  int _totalExec = 0;
  double _completionRate = 0;
  double _avgFatigueReduction = 0;
  List<ToolModel> _ownedTools = [];
  List<CourseModel> _recentCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final provider = context.read<AppProvider>();
    final userId = provider.currentUser?.userId ?? 1;

    final totalExec = await _db.getTotalExecutions();
    final completionRate = await _db.getCompletionRate();
    final avgReduction = await _db.getAverageFatigueReduction();
    final ownedTools = await _db.getOwnedTools(userId);
    final recentCourses = await _db.getRecentCourses(limit: 3);

    setState(() {
      _totalExec = totalExec;
      _completionRate = completionRate;
      _avgFatigueReduction = avgReduction;
      _ownedTools = ownedTools;
      _recentCourses = recentCourses;
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 사용자 이름
                      Text(
                        '$userName님,',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
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
          MaterialPageRoute(builder: (_) => const PostureScreen()),
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
              style: const TextStyle(
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
          label: AppStrings.completionRate,
          value: '${_completionRate.toStringAsFixed(0)}%',
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
            const Text(
              AppStrings.ownedTools,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const OwnedToolsScreen()),
                ).then((_) => _loadData());
              },
              child: const Text(
                AppStrings.seeMore,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._ownedTools.map((tool) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ToolCard(
                      name: tool.shapeName,
                      icon: tool.category == ToolCategory.foamRoller
                          ? Icons.sports_gymnastics
                          : Icons.circle,
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ToolCard(
                  name: '',
                  isAdd: true,
                  onTap: () => _showAddToolDialog(),
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
            const Text(
              AppStrings.recentRecords,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                // 라이브러리 탭으로 이동
                context.read<AppProvider>().setNavIndex(1);
              },
              child: const Text(
                AppStrings.seeMore,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentCourses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '최근 기록이 없습니다',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
              ),
            ),
          )
        else
          ..._recentCourses.map((course) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CourseItemCard(
                  title: course.name,
                  toolInfo: '폼롤러 + 마사지볼',
                  duration: course.formattedTime,
                  steps: '${course.totalMove}단계',
                ),
              )),
      ],
    );
  }

  void _showAddToolDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddToolSheet(),
    ).then((_) => _loadData());
  }
}

/// 도구 추가 바텀시트
class _AddToolSheet extends StatefulWidget {
  const _AddToolSheet();

  @override
  State<_AddToolSheet> createState() => _AddToolSheetState();
}

class _AddToolSheetState extends State<_AddToolSheet> {
  final DatabaseHelper _db = DatabaseHelper();
  ToolCategory _selectedCategory = ToolCategory.foamRoller;
  List<ToolModel> _availableTools = [];
  int? _selectedToolId;

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  Future<void> _loadTools() async {
    final tools = await _db.getToolsByCategory(_selectedCategory);
    setState(() {
      _availableTools = tools;
      _selectedToolId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '도구 추가',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 카테고리 선택
          Row(
            children: [
              _CategoryChip(
                label: '폼롤러',
                isSelected: _selectedCategory == ToolCategory.foamRoller,
                onTap: () {
                  setState(() => _selectedCategory = ToolCategory.foamRoller);
                  _loadTools();
                },
              ),
              const SizedBox(width: 10),
              _CategoryChip(
                label: '마사지볼',
                isSelected: _selectedCategory == ToolCategory.massageBall,
                onTap: () {
                  setState(() => _selectedCategory = ToolCategory.massageBall);
                  _loadTools();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 도구 그리드
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableTools.map((tool) {
              final isSelected = _selectedToolId == tool.toolId;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedToolId = tool.toolId);
                },
                child: Container(
                  width: 90,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedCategory == ToolCategory.foamRoller
                            ? Icons.sports_gymnastics
                            : Icons.circle,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tool.shapeName,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedToolId == null
                      ? null
                      : () async {
                          final provider = context.read<AppProvider>();
                          final userId =
                              provider.currentUser?.userId ?? 1;
                          final nav = Navigator.of(context);
                          await _db.addOwnedTool(userId, _selectedToolId!);
                          if (mounted) nav.pop();
                        },
                  child: const Text('추가'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.transparent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
