import 'package:flutter/material.dart';
import '../home/service_intro_screen.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

/// 온보딩 첫 화면 - 서비스 소개 + 이용 흐름 + 주의사항 + 면책
/// PDF 1페이지: "서비스 소개 보기" 버튼 + "주의 사항 자세히 보기" 링크
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              const Text(
                '근막 이완 코스',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '짧은 시간 안에 뭉친 근육을 풀고\n몸의 변화를 직접 느껴보세요.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // 이용 흐름
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '이용 흐름',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _flowItem(1, '도구 등록'),
                    const SizedBox(height: 10),
                    _flowItem(2, '몸 상태 점검'),
                    const SizedBox(height: 10),
                    _flowItem(3, '코스 생성'),
                    const SizedBox(height: 10),
                    _flowItem(4, '코스 실행'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 기본 주의사항
              const SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '기본 주의사항',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 16),
                    _CautionText('과도한 통증이 느껴지면 즉시 중단하세요.'),
                    SizedBox(height: 8),
                    _CautionText('한 부위에 30초~2분 이상 압박하지 마세요.'),
                    SizedBox(height: 8),
                    _CautionText('급성 부상·염증 부위에는 사용하지 마세요.'),
                    SizedBox(height: 8),
                    _CautionText('준비 운동 후 사용 시 효과가 높아집니다.'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 의료 면책
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '의료 진단·치료 아님',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '이 앱은 의료기기가 아니며, 제공되는 코스는 의료 진단이나 치료를 대체하지 않습니다. '
                      '통증이 지속될 경우 전문 의료인과 상담하세요.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '본 서비스는 건강 증진을 목적으로 하는 참고용 콘텐츠이며, '
                      '개인별 금기사항 판단이나 의학적 처방을 제공하지 않습니다.',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // "서비스 소개 보기" 버튼 → 서비스 소개 상세 (거기서 도구 등록으로 이동)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ServiceIntroScreen(),
                      ),
                    );
                  },
                  child: const Text('서비스 소개 보기'),
                ),
              ),
              const SizedBox(height: 12),

              // "주의 사항 자세히 보기" 링크
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CautionScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    '주의 사항 자세히 보기',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _flowItem(int number, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          NumberBadge(number: number, isActive: true),
          const SizedBox(width: 14),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _CautionText extends StatelessWidget {
  final String text;
  const _CautionText(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('· ', style: TextStyle(color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
