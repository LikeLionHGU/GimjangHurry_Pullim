import 'package:flutter/material.dart';
import '../assets/tool_assets.dart';
import '../services/tool_registration_service.dart';

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
    await _service.completeOnboarding();

    if (!mounted) return;

    // 홈 화면으로 교체 (뒤로가기 불가)
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }
}
