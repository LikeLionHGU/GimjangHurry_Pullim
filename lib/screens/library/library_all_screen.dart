import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../models/course_model.dart';
import '../../services/database_helper.dart';
import '../../services/course_loader.dart';
import '../../widgets/common_widgets.dart';
import '../course/course_execution_screen.dart';

/// 저장된 코스 전체 목록 페이지
class LibraryAllScreen extends StatefulWidget {
  const LibraryAllScreen({super.key});

  @override
  State<LibraryAllScreen> createState() => _LibraryAllScreenState();
}

class _LibraryAllScreenState extends State<LibraryAllScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<CourseModel> _savedCourses = [];
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
        title: const Text('저장된 코스'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _savedCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bookmark_border,
                            color: AppColors.textTertiary, size: 48),
                        const SizedBox(height: 16),
                        Text('저장된 코스가 없습니다',
                            style: AppTypography.r14.copyWith(
                                color: AppColors.textTertiary, fontSize: 15)),
                        const SizedBox(height: 8),
                        Text('코스 실행 중 저장 버튼을 눌러보세요',
                            style: AppTypography.r12.copyWith(
                                color: AppColors.textTertiary, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _savedCourses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final course = _savedCourses[index];
                      return CourseItemCard(
                        title: course.name,
                        toolInfo: course.summary ?? '',
                        duration: course.formattedTime,
                        steps: '${course.totalMove}단계',
                        onTap: () => _showExecuteDialog(course),
                      );
                    },
                  ),
      ),
    );
  }

  void _showExecuteDialog(CourseModel courseModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(courseModel.name,
            style: AppTypography.b18.copyWith(color: AppColors.textPrimary)),
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
              final newId = await CourseLoader.duplicateForReplay(courseModel.courseId!);
              final course = await CourseLoader.loadFromDb(newId);
              if (course != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseExecutionScreen(
                      course: course,
                      courseId: newId,
                    ),
                  ),
                ).then((_) => _loadCourses());
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
