import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../assets/tool_assets.dart';
import '../../services/tool_registration_service.dart';

/// 도구 추가 전용 화면 (온보딩 흐름과 분리)
/// 뒤로가기 가능, 도구 선택 후 추가하면 저장하고 pop
class AddToolScreen extends StatefulWidget {
  const AddToolScreen({super.key});

  @override
  State<AddToolScreen> createState() => _AddToolScreenState();
}

class _AddToolScreenState extends State<AddToolScreen> {
  static const _accentColor = Color(0xFFBBFF00);
  final _service = ToolRegistrationService();

  ToolCategory _selectedCategory = ToolCategory.foamRoller;
  final Set<int> _selectedIndexes = {};
  List<int> _alreadyOwned = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOwned();
  }

  Future<void> _loadOwned() async {
    final owned = await _service.getRegisteredTools();
    setState(() => _alreadyOwned = owned);
  }

  @override
  Widget build(BuildContext context) {
    final categoryTools = toolsByCategory(_selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: const Text('도구 추가'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '추가할 도구를 선택하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),

              // 카테고리 탭
              Row(
                children: ToolCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.transparent
                              : AppColors.surface,
                          border: Border.all(
                            color: isSelected
                                ? _accentColor
                                : AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category.label,
                          style: TextStyle(
                            color: isSelected
                                ? _accentColor
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 도구 그리드
              Expanded(
                child: GridView.builder(
                  itemCount: categoryTools.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, i) {
                    final tool = categoryTools[i];
                    final isSelected = _selectedIndexes.contains(tool.index);
                    final isOwned = _alreadyOwned.contains(tool.index);

                    return GestureDetector(
                      onTap: isOwned
                          ? null
                          : () {
                              setState(() {
                                if (isSelected) {
                                  _selectedIndexes.remove(tool.index);
                                } else {
                                  _selectedIndexes.add(tool.index);
                                }
                              });
                            },
                      child: Opacity(
                        opacity: isOwned ? 0.4 : 1.0,
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  border: Border.all(
                                    color: isSelected
                                        ? _accentColor
                                        : isOwned
                                            ? Colors.grey
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(
                                  tool.imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.fitness_center,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOwned
                                  ? '${tool.shape.label} ✓'
                                  : tool.shape.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: isOwned
                                    ? Colors.grey
                                    : Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 추가 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_selectedIndexes.isNotEmpty && !_isSaving)
                      ? _onAdd
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedIndexes.isNotEmpty
                        ? _accentColor
                        : AppColors.surface,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppColors.surface,
                    disabledForegroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isSaving
                        ? '저장 중...'
                        : '${_selectedIndexes.length}개 도구 추가하기',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAdd() async {
    setState(() => _isSaving = true);

    // 기존 보유 도구 + 새로 선택한 도구 합쳐서 저장
    final allTools = {..._alreadyOwned, ..._selectedIndexes}.toList();
    await _service.saveRegisteredTools(allTools);

    if (mounted) Navigator.pop(context);
  }
}
