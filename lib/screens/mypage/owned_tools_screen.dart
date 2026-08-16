import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/tool_model.dart';
import '../../providers/app_provider.dart';
import '../../services/database_helper.dart';
import '../../widgets/common_widgets.dart';

class OwnedToolsScreen extends StatefulWidget {
  const OwnedToolsScreen({super.key});

  @override
  State<OwnedToolsScreen> createState() => _OwnedToolsScreenState();
}

class _OwnedToolsScreenState extends State<OwnedToolsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<ToolModel> _ownedTools = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  Future<void> _loadTools() async {
    setState(() => _isLoading = true);
    final provider = context.read<AppProvider>();
    final userId = provider.currentUser?.userId ?? 1;
    final tools = await _db.getOwnedTools(userId);
    setState(() {
      _ownedTools = tools;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        ..._ownedTools.map((tool) => ToolCard(
                              name: tool.shapeName,
                              icon: tool.category == ToolCategory.foamRoller
                                  ? Icons.sports_gymnastics
                                  : Icons.circle,
                            )),
                        ToolCard(
                          name: '',
                          isAdd: true,
                          onTap: () {
                            Navigator.pop(context);
                            // 돌아가서 추가 다이얼로그를 열게 함
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
