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

    // 사용자 DB에 저장 + 로그인 상태 설정
    final provider = context.read<AppProvider>();
    await provider.login(name, '');

    if (!mounted) return;

    // 다음 페이지: 서비스 소개
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _OnboardingIntroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // 로고
              Text(
                'PULLIM',
                style: AppTypography.b35.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '근막 이완 코스',
                style: AppTypography.r14.copyWith(color: AppColors.textSecondary),
              ),

              const Spacer(flex: 1),

              // 이름 입력
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '이름을 입력해주세요',
                  style: AppTypography.sb18.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onNext(),
              ),

              const Spacer(flex: 2),

              // 다음 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onNext,
                  child: const Text('다음'),
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

/// 온보딩 2단계: 서비스 소개 + 이용 흐름 + 주의사항 → "서비스 소개 보기" → 도구 등록
class _OnboardingIntroScreen extends StatelessWidget {
  const _OnboardingIntroScreen();

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
              Text(
                '근막 이완 코스',
                style: AppTypography.sb24.copyWith(
                  color: AppColors.textPrimary,
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
              const SizedBox(height: 32),

              // 이용 흐름
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('이용 흐름',
                        style: AppTypography.b18.copyWith(
                            color: AppColors.textPrimary)),
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
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('기본 주의사항',
                        style: AppTypography.b18.copyWith(
                            color: AppColors.textPrimary)),
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
              const SizedBox(height: 20),

              // 의료 면책
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Text('의료 진단·치료 아님',
                          style: AppTypography.b16.copyWith(
                              color: AppColors.textPrimary)),
                    ]),
                    const SizedBox(height: 12),
                    Text(
                      '이 앱은 의료기기가 아니며, 제공되는 코스는 의료 진단이나 치료를 대체하지 않습니다. '
                      '통증이 지속될 경우 전문 의료인과 상담하세요.',
                      style: AppTypography.r12.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 서비스 소개 보기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ServiceIntroScreen()),
                    );
                  },
                  child: const Text('서비스 소개 보기'),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
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
