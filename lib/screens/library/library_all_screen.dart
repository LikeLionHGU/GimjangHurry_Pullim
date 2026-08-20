import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../models/course_model.dart';
import '../../services/database_helper.dart';
import '../../services/course_loader.dart';
import '../course/course_summary_screen.dart';

/// 저장된 코스 전체 보기 페이지
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '저장된 코스',
          style: AppTypography.sb18.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '저장된 코스 전체보기',
                          style: AppTypography.b20.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ..._savedCourses.map((course) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildItem(course),
                            )),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildItem(CourseModel course) {
    return GestureDetector(
      onTap: () => _showExecuteDialog(course),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
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
                          ).then((_) => _loadCourses());
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
