import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../assets/tool_assets.dart' as tool_assets;
import '../../services/tool_registration_service.dart';
import 'add_tool_screen.dart';

class OwnedToolsScreen extends StatefulWidget {
  const OwnedToolsScreen({super.key});

  @override
  State<OwnedToolsScreen> createState() => _OwnedToolsScreenState();
}

class _OwnedToolsScreenState extends State<OwnedToolsScreen> {
  final ToolRegistrationService _toolService = ToolRegistrationService();
  List<tool_assets.Tool> _ownedTools = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  Future<void> _loadTools() async {
    setState(() => _isLoading = true);
    final indexes = await _toolService.getRegisteredTools();
    final tools = tool_assets.toolsOf(indexes);
    setState(() {
      _ownedTools = tools;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '마이페이지',
          style: AppTypography.sb18.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '보유 도구',
                      style: AppTypography.b20.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildToolGrid(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildToolGrid() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        ..._ownedTools.map((tool) => _buildToolCard(tool)),
        // 추가 버튼
        _buildAddButton(),
      ],
    );
  }

  Widget _buildToolCard(tool_assets.Tool tool) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            tool.imagePath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              tool.category == tool_assets.ToolCategory.foamRoller
                  ? Icons.sports_gymnastics
                  : Icons.circle,
              color: AppColors.textSecondary,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tool.shape.label,
          style: AppTypography.r12.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showAddToolDialog(),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Icon(
                Icons.add_circle_outline,
                color: AppColors.textTertiary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '추가',
            style: AppTypography.r12.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToolDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AddToolDialog(
        alreadyOwned: _ownedTools.map((t) => t.index).toList(),
        onAdd: (selectedIndexes) async {
          await _toolService.saveRegisteredTools(selectedIndexes.toList());
          _loadTools();
        },
      ),
    );
  }
}
