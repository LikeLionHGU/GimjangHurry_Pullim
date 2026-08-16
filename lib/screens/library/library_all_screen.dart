import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/course_model.dart';
import '../../services/database_helper.dart';
import '../../widgets/common_widgets.dart';

class LibraryAllScreen extends StatefulWidget {
  const LibraryAllScreen({super.key});

  @override
  State<LibraryAllScreen> createState() => _LibraryAllScreenState();
}

class _LibraryAllScreenState extends State<LibraryAllScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<CourseModel> _allCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllCourses();
  }

  Future<void> _loadAllCourses() async {
    setState(() => _isLoading = true);
    final courses = await _db.getCompletedCourses();
    setState(() {
      _allCourses = courses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('라이브러리'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_allCourses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: AppColors.textTertiary, size: 48),
            SizedBox(height: 16),
            Text(
              '실행 이력이 없습니다',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '저장된 코스 전체보기',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(_allCourses.length, (index) {
            final course = _allCourses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CourseItemCard(
                title: course.name,
                toolInfo: '폼롤러 + 마사지볼',
                duration: course.formattedTime,
                steps: '${course.totalMove}단계',
                onTap: () {
                  // TODO: 코스 상세 또는 재실행 (다른 팀원 구현)
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
