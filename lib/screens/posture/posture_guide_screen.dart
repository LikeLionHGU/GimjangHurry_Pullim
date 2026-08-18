import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../widgets/common_widgets.dart';
import 'posture_screen.dart';

/// 촬영 가이드 화면 - 자세 측정 전 안내
/// GUI 1페이지: "내 몸을 먼저 확인할게요" + 촬영 가이드 + 촬영 시작하기
class PostureGuideScreen extends StatelessWidget {
  const PostureGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전신 촬영'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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

              const SizedBox(height: 24),

              // 자동 촬영 안내
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '가이드 위치에 맞게 서면 자동으로 촬영됩니다.\n음성으로 자세를 안내해 드려요.',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('촬영 시작하기'),
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
