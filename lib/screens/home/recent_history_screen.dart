import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/course_model.dart';
import '../../services/database_helper.dart';
import '../../services/course_loader.dart';
import '../course/course_execution_screen.dart';

/// 최근 운동 내역 전체 페이지
class RecentHistoryScreen extends StatefulWidget {
  const RecentHistoryScreen({super.key});

  @override
  State<RecentHistoryScreen> createState() => _RecentHistoryScreenState();
}

class _RecentHistoryScreenState extends State<RecentHistoryScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<CourseModel> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    final courses = await _db.getCompletedCourses();
    setState(() {
      _courses = courses;
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
            : _courses.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center,
                            color: AppColors.textTertiary, size: 48),
                        SizedBox(height: 16),
                        Text('운동 기록이 없습니다',
                            style: TextStyle(
                                color: AppColors.textTertiary, fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      return _buildItem(course);
                    },
                  ),
      ),
    );
  }

  Widget _buildItem(CourseModel course) {
    final dateStr = course.executedAt != null
        ? DateFormat('yyyy.MM.dd  a h:mm').format(course.executedAt!)
        : '';

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
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${course.totalMove}단계 · ${course.formattedTime}',
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 13)),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(dateStr,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12)),
                  ],
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
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18)),
        content: Text(
          '${courseModel.totalMove}단계 · ${courseModel.formattedTime}\n\n이 코스를 다시 실행하시겠습니까?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final course = await CourseLoader.loadFromDb(courseModel.courseId!);
              if (course != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseExecutionScreen(
                      course: course,
                      courseId: courseModel.courseId!,
                    ),
                  ),
                ).then((_) => _loadCourses());
              }
            },
            child: const Text('시작하기',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
