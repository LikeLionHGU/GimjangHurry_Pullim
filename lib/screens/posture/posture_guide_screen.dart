import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../widgets/common_widgets.dart';
import 'posture_screen.dart';

/// 촬영 가이드 화면 - 자세 측정 전 안내
class PostureGuideScreen extends StatelessWidget {
  const PostureGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '전신 촬영',
          style: AppTypography.sb18.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              Text(
                '내 몸을 먼저 확인할게요',
                style: AppTypography.sb24.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '현재 자세를 분석해 나에게 맞는 운동을 추천해 드려요. '
                '정면과 측면을 차례로 촬영해 주세요.',
                style: AppTypography.r14.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              // 촬영 가이드
              Text(
                '촬영 가이드',
                style: AppTypography.sb16.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              _buildGuideItem(1, '밝은 곳에서 촬영', '조명이 밝은 곳에서 촬영해 주세요.'),
              const SizedBox(height: 12),
              _buildGuideItem(2, '정면을 바라보고', '카메라를 정면으로 바라봐 주세요.'),
              const SizedBox(height: 12),
              _buildGuideItem(3, '편한 복장으로', '몸의 라인이 보이는 복장이 좋아요.'),

              const Spacer(),

              // 촬영 시작하기 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PostureScreen()),
                    );
                  },
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: Text('촬영 시작하기', style: AppTypography.b16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideItem(int number, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          NumberBadge(number: number, isActive: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.r14.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTypography.r12.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
