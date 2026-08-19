import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_typography.dart';
import '../../models/course_model.dart';
import '../../models/posture_result_model.dart';
import '../../services/database_helper.dart';
import '../../services/course_loader.dart';
import '../course/course_summary_screen.dart';
import '../posture/posture_result_screen.dart';
import 'library_all_screen.dart';
import 'posture_history_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<CourseModel> _savedCourses = [];
  List<PostureResultModel> _postureResults = [];
  int? _selectedIndex;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final courses = await _db.getSavedCourses();
    final postureResults = await _db.getAllPostureResults();
    setState(() {
      _savedCourses = courses;
      _postureResults = postureResults;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          '라이브러리',
          style: AppTypography.sb18.copyWith(color: AppColors.textPrimary),
        ),
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 저장된 코스 타이틀
                Text(
                  AppStrings.savedCourses,
                  style: AppTypography.b20.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),

                if (_savedCourses.isEmpty)
                  _buildEmptyState()
                else
                  ..._buildCourseList(),

                const SizedBox(height: 24),

                // 이력 전체 보기
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LibraryAllScreen(),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppStrings.historyAll,
                          style: AppTypography.r14.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 자세 측정 결과 섹션
                _buildPostureSection(),
              ],
            ),
          ),
        ),

        // 시작하기 버튼 (코스 선택 시에만 표시)
        if (_selectedIndex != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onStartCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppStrings.startCourse,
                  style: AppTypography.b16.copyWith(color: AppColors.background),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _onStartCourse() async {
    if (_selectedIndex == null) return;
    final courseModel = _savedCourses[_selectedIndex!];
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
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.library_books_outlined,
              color: AppColors.textTertiary, size: 48),
          const SizedBox(height: 16),
          Text(
            '저장된 코스가 없습니다',
            style: AppTypography.r14.copyWith(
              color: AppColors.textTertiary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '코스를 실행하고 저장해보세요',
            style: AppTypography.r12.copyWith(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCourseList() {
    return List.generate(_savedCourses.length, (index) {
      final course = _savedCourses[index];
      final isSelected = _selectedIndex == index;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = _selectedIndex == index ? null : index;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // 왼쪽: 타이틀 + 도구 정보
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
                // 오른쪽: 시간 + 단계 뱃지
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
        ),
      );
    });
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

  Widget _buildPostureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '자세 측정 결과',
          style: AppTypography.b20.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        if (_postureResults.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                '측정 결과가 없습니다',
                style: AppTypography.r14.copyWith(color: AppColors.textTertiary),
              ),
            ),
          )
        else
          ..._postureResults.take(2).map(_buildPostureItem),
        if (_postureResults.isNotEmpty)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostureHistoryScreen()),
              ).then((_) => _loadData());
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.assessment, color: AppColors.textPrimary, size: 20),
                  const SizedBox(width: 10),
                  Text('자세 측정 전체 보기',
                      style: AppTypography.r14.copyWith(color: AppColors.textPrimary)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPostureItem(PostureResultModel result) {
    final dateStr = DateFormat('yyyy.MM.dd  HH:mm').format(result.measuredAt);
    final scoreColor = result.score >= 85
        ? AppColors.primary
        : result.score >= 60
            ? AppColors.warning
            : AppColors.error;

    return GestureDetector(
      onTap: () {
        final frontAngles = <String, double>{};
        final sideAngles = <String, double>{};
        result.angles.forEach((k, v) {
          if (k.startsWith('front_')) frontAngles[k.replaceFirst('front_', '')] = v;
          if (k.startsWith('side_')) sideAngles[k.replaceFirst('side_', '')] = v;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostureResultScreen(
              result: result,
              frontImagePath: result.frontImagePath,
              sideImagePath: result.sideImagePath,
              frontAngles: frontAngles,
              sideAngles: sideAngles,
              score: result.score,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor, width: 2),
              ),
              child: Center(
                child: Text('${result.score}',
                    style: AppTypography.sb16.copyWith(color: scoreColor)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr,
                      style: AppTypography.r14.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    result.issues.isNotEmpty
                        ? '주의: ${result.issues.join(", ")}'
                        : '양호한 자세',
                    style: AppTypography.r12.copyWith(color: AppColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

}
