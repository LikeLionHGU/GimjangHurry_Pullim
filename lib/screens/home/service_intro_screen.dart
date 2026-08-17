import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../onboard/tool_registration_screen.dart';

class ServiceIntroScreen extends StatelessWidget {
  const ServiceIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('서비스 소개'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타이틀
              const Text(
                '내 몸 상태에 맞는\n근막 이완 루틴',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '보유한 도구와 피곤한 부위를 입력하면\n맞춤 코스를 바로 시작할 수 있습니다.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // 이용 순서
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '이용 순서',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StepDescription(
                      number: 1,
                      title: '도구 등록',
                      description: '보유한 폼롤러·마사지볼을 선택합니다.',
                    ),
                    const SizedBox(height: 12),
                    _StepDescription(
                      number: 2,
                      title: '몸 상태 점검',
                      description: '피곤한 부위와 피로도를 입력합니다.',
                    ),
                    const SizedBox(height: 12),
                    _StepDescription(
                      number: 3,
                      title: '코스 생성',
                      description: '도구·부위·시간을 바탕으로 코스가 만들어집니다.',
                    ),
                    const SizedBox(height: 12),
                    _StepDescription(
                      number: 4,
                      title: '코스 실행',
                      description: '가이드와 타이머에 따라 단계별로 수행합니다.',
                    ),
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
                    _CautionText('운동 전 충분히 수분을 섭취하세요.'),
                    SizedBox(height: 8),
                    _CautionText('과도한 통증이 느껴지면 즉시 중단하세요.'),
                    SizedBox(height: 8),
                    _CautionText('식사 직후 30분 이내에는 실행을 피하세요.'),
                    SizedBox(height: 8),
                    _CautionText('급성 염증, 골절 부위에는 사용하지 마세요.'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 의료 면책
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '이 서비스는 의료 진단 또는 치료를 제공하지 않습니다.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '건강 이상이 의심될 경우 전문 의료기관을 방문하세요.',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 도구 등록하고 시작하기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ToolRegistrationScreen(),
                      ),
                    );
                  },
                  child: const Text('도구 등록하고 시작하기'),
                ),
              ),

              const SizedBox(height: 12),

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
            ],
          ),
        ),
      ),
    );
  }
}

class _StepDescription extends StatelessWidget {
  final int number;
  final String title;
  final String description;

  const _StepDescription({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          NumberBadge(number: number, isActive: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title — $description',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.4,
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

// CautionScreen import placeholder
class CautionScreen extends StatelessWidget {
  const CautionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CautionScreenFull();
  }
}

class _CautionScreenFull extends StatelessWidget {
  const _CautionScreenFull();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주의사항/ 면책 안내'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '안전하게 시작해요',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              const SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '근막 이완 코스란?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '폼롤러·마사지볼로 근막의 긴장을 풀어 피로를 회복하는 셀프 케어 루틴입니다. '
                      '피곤한 부위를 선택하면 맞춤 코스를 바로 시작할 수 있습니다.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                    _DetailCaution('운동 전 가볍게 몸을 풀고 시작하세요.'),
                    SizedBox(height: 10),
                    _DetailCaution('한 부위에 30초~60초 이상 과도하게 압박하지 마세요.'),
                    SizedBox(height: 10),
                    _DetailCaution('날카롭거나 심한 통증이 느껴지면 즉시 중단하세요.'),
                    SizedBox(height: 10),
                    _DetailCaution('임산부, 골다공증, 혈전증 등 기저질환이 있는 경우 전문가와 상담 후 이용하세요.'),
                    SizedBox(height: 10),
                    _DetailCaution('식사 직후에는 이용을 삼가세요.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '의료 서비스가 아닙니다',
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
                      '이 앱은 일반적인 셀프 케어 가이드를 제공하며, 의료 진단·치료·처방을 목적으로 하지 않습니다. '
                      '증상이 지속되거나 악화되면 반드시 의료 전문가의 진료를 받으시기 바랍니다.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCaution extends StatelessWidget {
  final String text;

  const _DetailCaution(this.text);

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
