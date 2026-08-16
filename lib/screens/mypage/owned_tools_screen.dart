import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../assets/tool_assets.dart' as tool_assets;
import '../../services/tool_registration_service.dart';

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
      appBar: AppBar(
        title: const Text('보유 도구'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '보유 도구',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_ownedTools.isEmpty)
                      const Center(
                        child: Text(
                          '등록된 도구가 없습니다',
                          style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: _ownedTools.map((tool) => Column(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              padding: const EdgeInsets.all(8),
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
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )).toList(),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
