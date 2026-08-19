import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../models/posture_result_model.dart';
import '../../services/database_helper.dart';
import '../posture/posture_result_screen.dart';

/// 자세 측정 결과 전체 이력 페이지
class PostureHistoryScreen extends StatefulWidget {
  const PostureHistoryScreen({super.key});

  @override
  State<PostureHistoryScreen> createState() => _PostureHistoryScreenState();
}

class _PostureHistoryScreenState extends State<PostureHistoryScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<PostureResultModel> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    final results = await _db.getAllPostureResults();
    setState(() {
      _results = results;
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
          '자세 측정 이력',
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
            : _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assessment_outlined,
                            color: AppColors.textTertiary, size: 48),
                        const SizedBox(height: 16),
                        Text('측정 결과가 없습니다',
                            style: AppTypography.r14.copyWith(
                                color: AppColors.textTertiary, fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildItem(_results[index]),
                  ),
      ),
    );
  }

  Widget _buildItem(PostureResultModel result) {
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
          if (k.startsWith('front_')) {
            frontAngles[k.replaceFirst('front_', '')] = v;
          } else if (k.startsWith('side_')) {
            sideAngles[k.replaceFirst('side_', '')] = v;
          }
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
                child: Text(
                  '${result.score}',
                  style: AppTypography.sb16.copyWith(color: scoreColor),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr,
                      style: AppTypography.r14
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    result.issues.isNotEmpty
                        ? '주의: ${result.issues.join(", ")}'
                        : '양호한 자세',
                    style: AppTypography.r12
                        .copyWith(color: AppColors.textTertiary),
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
