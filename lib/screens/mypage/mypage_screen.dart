import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/course_model.dart';
import '../../assets/tool_assets.dart' as tool_assets;
import '../../providers/app_provider.dart';
import '../../services/database_helper.dart';
import '../../services/tool_registration_service.dart';
import '../../widgets/common_widgets.dart';
import '../posture/posture_guide_screen.dart';
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
  double _completionRate = 0;
  double _avgFatigueReduction = 0;
  List<tool_assets.Tool> _ownedTools = [];
  List<CourseModel> _recentCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final totalExec = await _db.getTotalExecutions();
    final completionRate = await _db.getCompletionRate();
    final avgReduction = await _db.getAverageFatigueReduction();
    final recentCourses = await _db.getRecentCourses(limit: 3);

    // 보유 도구: SharedPreferences에서 인덱스 가져와서 tool_assets로 매핑
    final toolIndexes = await _toolService.getRegisteredTools();
    final ownedTools = tool_assets.toolsOf(toolIndexes);

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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  MaterialPageRoute(builder: (_) => const OwnedToolsScreen()),
                ).then((_) => _loadData());
              },
              child: const Text(
                AppStrings.seeMore,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_ownedTools.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: const Center(
              child: Text(
                '등록된 도구가 없습니다',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
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
                context.read<AppProvider>().setNavIndex(1);
              },
              child: const Text(
                AppStrings.seeMore,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                  toolInfo: '${course.totalMove}단계',
                  duration: course.formattedTime,
                  steps: '${course.totalMove}단계',
                ),
              )),
      ],
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
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
