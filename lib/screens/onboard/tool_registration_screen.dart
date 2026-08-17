// 온보딩 도구 등록 화면.
// 첫 실행 시 표시되며, 보유한 폼롤러/마사지볼/스틱을 선택해 로컬에 저장한다.
// 등록 완료 후 홈 화면으로 이동한다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../assets/tool_assets.dart';
import '../../services/tool_registration_service.dart';
import '../main_shell.dart';
import '../posture/posture_guide_screen.dart';

/// 온보딩용 도구 등록 화면.
/// 첫 실행 시에만 표시되며, 등록 완료 후 홈 화면으로 이동한다.
class ToolRegistrationScreen extends StatefulWidget {
  const ToolRegistrationScreen({super.key});

  @override
  State<ToolRegistrationScreen> createState() => _ToolRegistrationScreenState();
}

class _ToolRegistrationScreenState extends State<ToolRegistrationScreen> {
  static const _accentColor = Color(0xFFBBFF00);

  final _service = ToolRegistrationService();

  /// 현재 선택된 카테고리 탭.
  ToolCategory _selectedCategory = ToolCategory.foamRoller;

  /// 사용자가 선택한 도구 인덱스 Set.
  final Set<int> _selectedIndexes = {};

  bool _isSaving = false;

  // ----------------------------------------------------------
  // Build
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final categoryTools = toolsByCategory(_selectedCategory);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 뒤로가기 (온보딩이므로 실제로 뒤로 갈 곳은 없지만 시안 반영)
              const SizedBox(height: 8),

              // 타이틀
              const Text(
                '도구 등록',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '보유한 도구를 선택해 등록하세요.\n여러 개 추가할 수 있습니다.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // 카테고리 탭 영역
              const Text(
                '도구 종류 / 형태',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildCategoryTabs(),
              const SizedBox(height: 16),

              // 도구 그리드
              Expanded(
                child: _buildToolGrid(categoryTools),
              ),

              // 등록된 도구 영역
              if (_selectedIndexes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  '등록된 도구',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSelectedToolsRow(),
              ],

              const SizedBox(height: 16),

              // CTA 버튼
              _buildCtaButton(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 카테고리 탭
  // ----------------------------------------------------------

  Widget _buildCategoryTabs() {
    return Row(
      children: ToolCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.transparent : Colors.grey[850],
                border: Border.all(
                  color: isSelected ? _accentColor : Colors.grey[700]!,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category.label,
                style: TextStyle(
                  color: isSelected ? _accentColor : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ----------------------------------------------------------
  // 도구 그리드
  // ----------------------------------------------------------

  Widget _buildToolGrid(List<Tool> tools) {
    return GridView.builder(
      itemCount: tools.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, i) {
        final tool = tools[i];
        final isSelected = _selectedIndexes.contains(tool.index);
        return GestureDetector(
          onTap: () => _toggleTool(tool.index),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    border: Border.all(
                      color: isSelected ? _accentColor : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    tool.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tool.shape.label,
                style: const TextStyle(fontSize: 12, color: Colors.white),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // 등록된 도구 가로 스크롤
  // ----------------------------------------------------------

  Widget _buildSelectedToolsRow() {
    final selectedTools = _selectedIndexes
        .map((i) => kTools[i])
        .whereType<Tool>()
        .toList();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: selectedTools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final tool = selectedTools[i];
          return Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(tool.imagePath, fit: BoxFit.contain),
              ),
              const SizedBox(height: 4),
              Text(
                tool.shape.label,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // CTA 버튼
  // ----------------------------------------------------------

  Widget _buildCtaButton() {
    final isEnabled = _selectedIndexes.isNotEmpty && !_isSaving;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isEnabled ? _onRegister : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? _accentColor : Colors.grey[800],
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.grey[800],
          disabledForegroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isSaving ? '저장 중...' : '도구 등록하고 시작하기',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Actions
  // ----------------------------------------------------------

  void _toggleTool(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
    });
  }

  Future<void> _onRegister() async {
    setState(() => _isSaving = true);

    await _service.saveRegisteredTools(_selectedIndexes.toList());
    // 현재 사용자 이메일 기반으로 온보딩 완료 저장
    final email = context.read<AppProvider>().currentUser?.email;
    await _service.completeOnboardingForUser(email);

    if (!mounted) return;

    // 다음 단계: 자세 측정 화면으로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _OnboardingPostureScreen()),
    );
  }
}


/// 온보딩 단계의 자세 측정 화면.
/// 자세 측정 완료 또는 스킵 후 홈 화면으로 이동.
class _OnboardingPostureScreen extends StatelessWidget {
  const _OnboardingPostureScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 안내
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '자세 점검',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '정면과 측면 자세를 촬영하면\n맞춤 코스를 더 정확하게 만들 수 있습니다.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 자세 측정 아이콘
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBBFF00).withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.accessibility_new,
                color: Color(0xFFBBFF00),
                size: 56,
              ),
            ),

            const Spacer(),

            // 버튼들
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // 자세 측정 시작 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PostureGuideScreen(),
                          ),
                        );
                        // 자세 측정 완료 후 결과 화면의 "코스 시작하기"에서 홈으로 이동됨
                        // 뒤로가기 시에는 이 화면에 머무름
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBBFF00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '자세 측정 시작하기',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 나중에 하기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const MainShell(),
                          ),
                          (_) => false,
                        );
                      },
                      child: const Text(
                        '나중에 하기',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
