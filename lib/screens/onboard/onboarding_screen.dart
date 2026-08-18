import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/service_intro_screen.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

/// 온보딩 첫 화면 - 이름 입력 후 서비스 소개로 진행
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요')),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    await provider.login(name, '');

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _OnboardingIntroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '환영합니다',
                  style: AppTypography.sb24.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '이름을 입력해주세요',
                  style: AppTypography.r14.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                style: AppTypography.r16.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '이름 입력',
                  hintStyle: AppTypography.r16.copyWith(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onNext(),
              ),

              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('다음', style: AppTypography.b16),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// 온보딩 2단계: 근막 이완 코스 소개 페이지
/// 배경 그라데이션 + 실루엣, 이용 흐름, 주의사항, 의료면책
class _OnboardingIntroScreen extends StatelessWidget {
  const _OnboardingIntroScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 히어로 영역 (그라데이션 + 타이틀)
              _buildHeroSection(),
              const SizedBox(height: 28),

              // 이용 흐름
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이용 흐름',
                        style: AppTypography.b18.copyWith(
                          color: AppColors.textPrimary,
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
              ),
              const SizedBox(height: 20),

              // 기본 주의사항
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '기본 주의사항',
                        style: AppTypography.b18.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _CautionText('과도한 통증이 느껴지면 즉시 중단하세요.'),
                      const SizedBox(height: 8),
                      const _CautionText('한 부위에 30초~2분 이상 압박하지 마세요.'),
                      const SizedBox(height: 8),
                      const _CautionText('급성 부상·염증 부위에는 사용하지 마세요.'),
                      const SizedBox(height: 8),
                      const _CautionText('준비 운동 후 사용 시 효과가 높아집니다.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 의료 면책
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '의료 진단·치료 아님',
                          style: AppTypography.b16.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Text(
                        '이 앱은 의료기기가 아니며, 제공되는 코스는 의료 진단이나 치료를 대체하지 않습니다. '
                        '통증이 지속될 경우 전문 의료인과 상담하세요.\n\n'
                        '본 서비스는 건강 증진을 목적으로 하는 참고용 콘텐츠이며, '
                        '개인별 금기사항 판단이나 의학적 처방을 제공하지 않습니다.',
                        style: AppTypography.r12.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 서비스 소개 보기 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ServiceIntroScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('서비스 소개 보기', style: AppTypography.b16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 주의 사항 자세히 보기
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CautionScreen()),
                    );
                  },
                  child: Text(
                    '주의 사항 자세히 보기',
                    style: AppTypography.r14.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textSecondary,
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

  /// 히어로 섹션: 상단 그라데이션 + 실루엣 배경 + 타이틀
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.background,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '근막 이완 코스',
            style: AppTypography.sb24.copyWith(
              color: AppColors.primary,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '짧은 시간 안에 뭉친 근육을 풀고\n몸의 변화를 직접 느껴보세요.',
            style: AppTypography.r14.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _flowItem(int number, String text) {
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
          Text(text,
              style: AppTypography.r14.copyWith(
                  color: AppColors.textPrimary, fontSize: 15)),
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
        Text('· ', style: AppTypography.r14.copyWith(color: AppColors.textSecondary)),
        Expanded(
          child: Text(text,
              style: AppTypography.r14.copyWith(
                  color: AppColors.textSecondary, height: 1.4)),
        ),
      ],
    );
  }
}
