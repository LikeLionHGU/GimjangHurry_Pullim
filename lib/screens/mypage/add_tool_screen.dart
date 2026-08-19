import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../assets/tool_assets.dart';
import '../../services/tool_registration_service.dart';

/// 도구 추가 다이얼로그 (모달 형태)
/// 마이페이지 > 보유 도구에서 (+) 버튼을 누르면 표시된다.
class AddToolDialog extends StatefulWidget {
  const AddToolDialog({
    super.key,
    required this.alreadyOwned,
    required this.onAdd,
  });

  final List<int> alreadyOwned;
  final Future<void> Function(Set<int> newIndexes) onAdd;

  @override
  State<AddToolDialog> createState() => _AddToolDialogState();
}

class _AddToolDialogState extends State<AddToolDialog> {
  ToolCategory _selectedCategory = ToolCategory.foamRoller;
  final Set<int> _selectedIndexes = {};

  @override
  void initState() {
    super.initState();
    // 이미 등록된 도구를 선택된 상태로 초기화
    _selectedIndexes.addAll(widget.alreadyOwned);
  }

  @override
  Widget build(BuildContext context) {
    final categoryTools = toolsByCategory(_selectedCategory);

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 도구 추가 + X 닫기
            Row(
              children: [
                Text(
                  '도구 추가',
                  style: AppTypography.b20.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 카테고리 탭
            _buildCategoryTabs(),
            const SizedBox(height: 16),

            // 도구 그리드 (3열)
            _buildToolGrid(categoryTools),
            const SizedBox(height: 20),

            // 취소 / 추가 버튼
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

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
                color: Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.toolSelectBox,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category.label,
                style: AppTypography.sb16.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToolGrid(List<Tool> tools) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tools.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, i) {
        final tool = tools[i];
        final isSelected = _selectedIndexes.contains(tool.index);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedIndexes.remove(tool.index);
              } else {
                _selectedIndexes.add(tool.index);
              }
            });
          },
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    tool.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.fitness_center,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tool.shape.label,
                style: AppTypography.r12.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // 취소 버튼 (회색 테두리 + 회색 텍스트)
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.toolSelectBox),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '취소',
                style: AppTypography.sb16.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 저장 버튼 (녹색 테두리 + 녹색 텍스트 + 어두운 녹색 배경)
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () async {
                await widget.onAdd(_selectedIndexes);
                if (mounted) Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '저장',
                style: AppTypography.sb16.copyWith(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 도구 추가 전용 화면 (독립 페이지 - 온보딩 외 직접 접근용)
/// 뒤로가기 가능, 도구 선택 후 추가하면 저장하고 pop
class AddToolScreen extends StatefulWidget {
  const AddToolScreen({super.key});

  @override
  State<AddToolScreen> createState() => _AddToolScreenState();
}

class _AddToolScreenState extends State<AddToolScreen> {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '도구 추가',
          style: AppTypography.sb18.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '추가할 도구를 선택하세요',
                style: AppTypography.r14.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // 카테고리 탭
              _buildCategoryTabs(),
              const SizedBox(height: 16),

              // 도구 그리드
              Expanded(
                child: GridView.builder(
                  itemCount: categoryTools.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
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
                                  color: AppColors.secondary,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  tool.imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.fitness_center,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOwned
                                  ? '${tool.shape.label} \u2713'
                                  : tool.shape.label,
                              style: AppTypography.r12.copyWith(
                                color: isOwned
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                fontSize: 11,
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
                height: 56,
                child: ElevatedButton(
                  onPressed: (_selectedIndexes.isNotEmpty && !_isSaving)
                      ? _onAdd
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor: AppColors.toolSelectBox,
                    disabledForegroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isSaving
                        ? '저장 중...'
                        : '${_selectedIndexes.length}개 도구 추가하기',
                    style: AppTypography.b16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                color: Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.toolSelectBox,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category.label,
                style: AppTypography.sb16.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _onAdd() async {
    setState(() => _isSaving = true);

    final allTools = {..._alreadyOwned, ..._selectedIndexes}.toList();
    await _service.saveRegisteredTools(allTools);

    if (mounted) Navigator.pop(context);
  }
}
