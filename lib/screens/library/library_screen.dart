import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/course_model.dart';
import '../../services/database_helper.dart';
import '../../widgets/common_widgets.dart';
import 'library_all_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<CourseModel> _savedCourses = [];
  int? _selectedIndex;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    final courses = await _db.getSavedCourses();
    setState(() {
      _savedCourses = courses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('라이브러리'),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.savedCourses,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
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
                    ).then((_) => _loadCourses());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.history,
                            color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          AppStrings.historyAll,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 시작하기 버튼 (코스 선택 시 표시)
        if (_selectedIndex != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 코스 실행 화면으로 이동 (다른 팀원 구현)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('코스 실행 화면으로 이동합니다.')),
                  );
                },
                child: const Text(AppStrings.startCourse),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: const Column(
        children: [
          Icon(Icons.library_books_outlined,
              color: AppColors.textTertiary, size: 48),
          SizedBox(height: 16),
          Text(
            '저장된 코스가 없습니다',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '코스를 실행하고 저장해보세요',
            style: TextStyle(
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
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CourseItemCard(
          title: course.name,
          toolInfo: _getToolInfo(course),
          duration: course.formattedTime,
          steps: '${course.totalMove}단계',
          isSelected: _selectedIndex == index,
          onTap: () {
            setState(() {
              _selectedIndex = _selectedIndex == index ? null : index;
            });
          },
        ),
      );
    });
  }

  String _getToolInfo(CourseModel course) {
    // 간단히 코스 이름에서 도구 정보 추출하거나 기본값
    return '폼롤러 + 마사지볼';
  }
}
