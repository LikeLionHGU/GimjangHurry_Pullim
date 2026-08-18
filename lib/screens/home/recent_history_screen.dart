import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../models/course_model.dart';
import '../../models/execution_model.dart';
import '../../services/database_helper.dart';
import '../../services/course_loader.dart';
import '../course/course_summary_screen.dart';

/// 최근 운동 내역 전체 페이지
class RecentHistoryScreen extends StatefulWidget {
  const RecentHistoryScreen({super.key});

  @override
  State<RecentHistoryScreen> createState() => _RecentHistoryScreenState();
}

class _RecentHistoryScreenState extends State<RecentHistoryScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<(CourseModel, ExecutionModel)> _executions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    final executions = await _db.getAllExecutions();
    setState(() {
      _executions = executions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('최근 운동 내역'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _executions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fitness_center,
                            color: AppColors.textTertiary, size: 48),
                        const SizedBox(height: 16),
                        Text('운동 기록이 없습니다',
                            style: AppTypography.r14.copyWith(
                                color: AppColors.textTertiary, fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _executions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final (course, execution) = _executions[index];
                      return _buildItem(course, execution);
                    },
                  ),
      ),
    );
  }

  Widget _buildItem(CourseModel course, ExecutionModel execution) {
    final dateStr = DateFormat('yyyy.MM.dd  a h:mm').format(execution.executedAt);

    return GestureDetector(
      onTap: () => _showExecuteDialog(course),
      child: Container(
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
                  Text(course.name,
                      style: AppTypography.sb16.copyWith(
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('${course.totalMove}단계 · ${course.formattedTime}',
                      style: AppTypography.r12.copyWith(
                          color: AppColors.textTertiary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(dateStr,
                      style: AppTypography.r12.copyWith(
                          color: AppColors.textTertiary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
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
          '${courseModel.totalMove}단계 · ${courseModel.formattedTime}\n\n이 코스를 다시 실행하시겠습니까?',
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
