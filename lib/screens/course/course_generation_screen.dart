// 코스 생성 화면.
// 사용시간 선택 → 도구 선택 → 부위 선택 → 피로도 입력 → 코스 생성 호출.
// 생성 버튼을 누르면 로딩 화면으로 전환되어 AI 코스 생성을 수행한다.

import 'package:flutter/material.dart';
import '../../assets/body_assets.dart';
import '../../assets/tool_assets.dart';
import '../../course_generator/course_generator_library.dart';
import '../../services/tool_registration_service.dart';
import 'course_result_screen.dart';

/// face + part 조합 키.
typedef _FatigueKey = ({BodyFace face, BodyPart part});

/// 전면/후면에서 각 BodyPart의 대표 좌표를 반환한다.
Map<BodyPart, ({double x, double y})> _spotCoordinates(BodyFace face) {
  final map = <BodyPart, ({double x, double y})>{};
  for (final body in kBodies.values) {
    if (body.forb == face && !map.containsKey(body.part)) {
      map[body.part] = body.xy;
    }
  }
  return map;
}

/// 중앙에 위치하여 미러링이 필요 없는 부위.
const _centerParts = <BodyPart>{
  BodyPart.neck,
  BodyPart.chest,
  BodyPart.upperBack,
  BodyPart.abdomen,
  BodyPart.waist,
  BodyPart.hip,
};

class CourseGenerationScreen extends StatefulWidget {
  const CourseGenerationScreen({
    super.key,
    this.initialFatigueEntries,
  });

  /// 외부에서 전달받은 초기 피로도 부위 (예: 자세 점검 결과 기반 추천).
  /// null이면 빈 상태로 시작한다.
  final List<FatigueEntry>? initialFatigueEntries;

  @override
  State<CourseGenerationScreen> createState() => _CourseGenerationScreenState();
}

class _CourseGenerationScreenState extends State<CourseGenerationScreen> {
  bool _isFront = true;

  /// 사용시간 (초). 기본 3분.
  int _availableTime = 180;

  /// 사용시간 선택지 (초).
  static const _timeOptions = [180, 300, 600];

  /// 전면/후면 구분 없이 누적되는 피로도 맵.
  final Map<_FatigueKey, double> _fatigueLevels = {};

  // ── 도구 선택 ──────────────────────────────────────────────
  final _toolService = ToolRegistrationService();

  /// 온보딩에서 등록된 도구 인덱스 목록.
  List<int> _registeredToolIndexes = [];

  /// 현재 선택된 도구 인덱스 (초기: 전체 선택).
  Set<int> _selectedToolIndexes = {};

  /// 도구 로딩 상태.
  bool _isLoadingTools = true;

  /// 커스텀 시간 슬라이더 표시 여부.
  bool _showCustomTimeSlider = false;

  /// 커스텀 시간 슬라이더 값 (분 단위).
  double _customTimeMinutes = 15.0;

  @override
  void initState() {
    super.initState();
    _loadTools();
    _applyInitialFatigueEntries();
  }

  /// 외부에서 전달받은 초기 부위를 _fatigueLevels에 적용한다.
  void _applyInitialFatigueEntries() {
    final entries = widget.initialFatigueEntries;
    if (entries == null || entries.isEmpty) return;

    for (final entry in entries) {
      final key = (face: entry.face, part: entry.part);
      _fatigueLevels[key] = entry.level.toDouble();
    }
  }

  Future<void> _loadTools() async {
    final indexes = await _toolService.getRegisteredTools();
    setState(() {
      _registeredToolIndexes = indexes;
      _selectedToolIndexes = indexes.toSet(); // 전체 선택 상태로 시작
      _isLoadingTools = false;
    });
  }

  void _toggleToolSelection(int index) {
    setState(() {
      if (_selectedToolIndexes.contains(index)) {
        _selectedToolIndexes.remove(index);
      } else {
        _selectedToolIndexes.add(index);
      }
    });
  }

  BodyFace get _currentFace => _isFront ? BodyFace.front : BodyFace.back;

  /// 자세 측정 기반 모드인지 여부.
  bool get _isPostureBased =>
      widget.initialFatigueEntries != null &&
      widget.initialFatigueEntries!.isNotEmpty;

  _FatigueKey _key(BodyPart part) => (face: _currentFace, part: part);

  bool _isSelected(BodyPart part) => _fatigueLevels.containsKey(_key(part));

  void _togglePart(BodyPart part) {
    setState(() {
      final key = _key(part);
      if (_fatigueLevels.containsKey(key)) {
        _fatigueLevels.remove(key);
      } else {
        _fatigueLevels[key] = 5.0;
      }
    });
  }

  List<FatigueEntry> _buildFatigueEntries() {
    return _fatigueLevels.entries.map((e) {
      return FatigueEntry(
        face: e.key.face,
        part: e.key.part,
        level: e.value.round(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 뒤로가기
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: 24),
              // 코스 생성 타이틀
              const Text(
                '코스 생성',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '아래 항목을 확인하고 코스를 생성하세요.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 28),
              // 사용시간
              const Text(
                '사용시간',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildTimeSelector(),
              const SizedBox(height: 32),
              // 도구 선택
              _buildToolSelector(),
              const SizedBox(height: 32),
              // 부위 선택 (자세 측정 기반이면 읽기 전용 요약만 표시)
              if (_isPostureBased) ...[
                const Text(
                  '측정 기반 추천 부위',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '자세 점검 결과를 기반으로 선택된 부위입니다.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildToggleButtons(),
                const SizedBox(height: 16),
                _buildBodyImageWithSpots(),
                const SizedBox(height: 16),
                _buildPostureBasedPartsSummary(),
              ] else ...[
                const Text(
                  '불편한 부위 선택',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '전면/후면 선택 후 부위를 지정하세요.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildToggleButtons(),
                const SizedBox(height: 16),
                _buildBodyImageWithSpots(),
                const SizedBox(height: 24),
                const Text(
                  '피로도 입력',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_fatigueLevels.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        '전면/후면 선택 부위를 지정하세요.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      )
                    )
                  )
                else
                  ..._fatigueLevels.keys.map(_buildFatigueSlider),
              ],
              const SizedBox(height: 24),
              _buildGenerateButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ..._timeOptions.map((seconds) {
              final minutes = seconds ~/ 60;
              final isActive = _availableTime == seconds && !_showCustomTimeSlider;
              return GestureDetector(
                onTap: () => setState(() {
                  _availableTime = seconds;
                  _showCustomTimeSlider = false;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? const Color(0xFFBBFF00) : Colors.grey[700]!,
                    ),
                  ),
                  child: Text(
                    '$minutes분',
                    style: TextStyle(
                      color: isActive ? const Color(0xFFBBFF00) : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: () => setState(() {
                _showCustomTimeSlider = !_showCustomTimeSlider;
                if (_showCustomTimeSlider) {
                  _customTimeMinutes = (_availableTime ~/ 60).toDouble().clamp(10, 60);
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showCustomTimeSlider || !_timeOptions.contains(_availableTime)
                        ? const Color(0xFFBBFF00)
                        : Colors.grey[700]!,
                  ),
                ),
                child: Text(
                  _showCustomTimeSlider
                      ? '${_customTimeMinutes.round()}분'
                      : !_timeOptions.contains(_availableTime)
                          ? '${_availableTime ~/ 60}분'
                          : '+',
                  style: TextStyle(
                    color: _showCustomTimeSlider || !_timeOptions.contains(_availableTime)
                        ? const Color(0xFFBBFF00)
                        : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_showCustomTimeSlider) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('10', style: TextStyle(color: Color(0xFFBBFF00), fontSize: 12)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFFBBFF00),
                    inactiveTrackColor: Colors.grey[800],
                    thumbShape: _NumberedThumbShape(value: _customTimeMinutes.round()),
                    overlayColor: const Color(0xFFBBFF00).withValues(alpha: 0.2),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: _customTimeMinutes,
                    min: 10,
                    max: 60,
                    divisions: 50,
                    onChanged: (value) {
                      setState(() {
                        _customTimeMinutes = value;
                      });
                    },
                  ),
                ),
              ),
              const Text('60', style: TextStyle(color: Color(0xFFBBFF00), fontSize: 12)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() {
                  _availableTime = _customTimeMinutes.round() * 60;
                  _showCustomTimeSlider = false;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBFF00)),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      color: Color(0xFFBBFF00),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }


  Widget _buildToggleButtons() {
    final frontCount =
        _fatigueLevels.keys.where((k) => k.face == BodyFace.front).length;
    final backCount =
        _fatigueLevels.keys.where((k) => k.face == BodyFace.back).length;

    return Row(
      children: [
        _toggleButton(
          '전면${frontCount > 0 ? " ($frontCount)" : ""}',
          _isFront,
          () => setState(() => _isFront = true),
        ),
        const SizedBox(width: 8),
        _toggleButton(
          '후면${backCount > 0 ? " ($backCount)" : ""}',
          !_isFront,
          () => setState(() => _isFront = false),
        ),
      ],
    );
  }

  Widget _toggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFBBFF00) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFFBBFF00) : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBodyImageWithSpots() {
    final spots = _spotCoordinates(_currentFace);
    final imagePath =
        _isFront ? 'assets/images/front.png' : 'assets/images/back.png';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: const Color(0xFF1A1A1A),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Image.asset(
                  imagePath,
                  width: constraints.maxWidth,
                  fit: BoxFit.fitWidth,
                ),
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, innerConstraints) {
                      final width = innerConstraints.maxWidth;
                      final height = innerConstraints.maxHeight;
                      return Stack(
                        children: spots.entries.expand((entry) {
                          final part = entry.key;
                          final coord = entry.value;
                          final isCenter = _centerParts.contains(part);
                          final selected = _isSelected(part);
                          final onTap = _isPostureBased
                              ? null
                              : () => _togglePart(part);

                          if (isCenter) {
                            return [
                              _buildSpot(
                                left: coord.x * width - 18,
                                top: coord.y * height - 18,
                                isSelected: selected,
                                onTap: onTap,
                              ),
                            ];
                          } else {
                            return [
                              _buildSpot(
                                left: coord.x * width - 18,
                                top: coord.y * height - 18,
                                isSelected: selected,
                                onTap: onTap,
                              ),
                              _buildSpot(
                                left: (1 - coord.x) * width - 18,
                                top: coord.y * height - 18,
                                isSelected: selected,
                                onTap: onTap,
                              ),
                            ];
                          }
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpot({
    required double left,
    required double top,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? const Color(0xFFBBFF00).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.15),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFBBFF00)
                  : Colors.white.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFFBBFF00)
                    : Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFatigueSlider(_FatigueKey key) {
    final level = _fatigueLevels[key] ?? 5.0;
    final label = '${key.face.label} ${key.part.label}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBBFF00)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFBBFF00),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('1', style: TextStyle(color: Colors.grey, fontSize: 12)),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFFBBFF00),
                inactiveTrackColor: Colors.grey[800],
                thumbShape: _NumberedThumbShape(value: level.round()),
                overlayColor: const Color(0xFFBBFF00).withValues(alpha: 0.2),
                trackHeight: 3,
              ),
              child: Slider(
                value: level,
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) {
                  setState(() {
                    _fatigueLevels[key] = value;
                  });
                },
              ),
            ),
          ),
          const Text('10',
              style: TextStyle(color: Color(0xFFBBFF00), fontSize: 12)),
        ],
      ),
    );
  }

  /// 자세 측정 기반 모드에서 선택된 부위를 칩으로 표시하는 위젯.
  Widget _buildPostureBasedPartsSummary() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fatigueLevels.entries.map((entry) {
        final label = '${entry.key.face.label} ${entry.key.part.label}';
        final level = entry.value.round();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFBBFF00).withValues(alpha: 0.15),
            border: Border.all(color: const Color(0xFFBBFF00)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$label (Lv.$level)',
            style: const TextStyle(
              color: Color(0xFFBBFF00),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 도구 선택 섹션 ─────────────────────────────────────────

  Widget _buildToolSelector() {
    if (_isLoadingTools) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(color: Color(0xFFBBFF00)),
        ),
      );
    }

    if (_registeredToolIndexes.isEmpty) {
      return const Text(
        '등록된 도구가 없습니다.',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    final tools = _registeredToolIndexes
        .map((i) => kTools[i])
        .whereType<Tool>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘 사용할 도구',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tools.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final tool = tools[i];
              final isSelected = _selectedToolIndexes.contains(tool.index);
              return GestureDetector(
                onTap: () => _toggleToolSelection(tool.index),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFBBFF00)
                              : Colors.grey[700]!,
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
                    const SizedBox(height: 6),
                    Text(
                      tool.shape.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onGeneratePressed() {
    final request = CourseRequest(
      fatigueEntries: _buildFatigueEntries(),
      ownedTools: _selectedToolIndexes.toList(),
      availableTime: _availableTime,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CourseLoadingScreen(
          request: request,
          isPostureBased: _isPostureBased,
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    final isEnabled = _fatigueLevels.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isEnabled ? _onGeneratePressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? const Color(0xFFBBFF00) : Colors.grey[800],
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '코스 생성하기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isEnabled ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// 코스 생성 로딩 화면.
class _CourseLoadingScreen extends StatefulWidget {
  const _CourseLoadingScreen({
    required this.request,
    this.isPostureBased = false,
  });

  final CourseRequest request;
  final bool isPostureBased;

  @override
  State<_CourseLoadingScreen> createState() => _CourseLoadingScreenState();
}

class _CourseLoadingScreenState extends State<_CourseLoadingScreen> {
  @override
  void initState() {
    super.initState();
    // 빌드 완료 후 생성 시작 (빌드 중 네비게이션 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    try {
      final generator = CourseGenerator();
      final course = await generator.generateCourse(widget.request);

      debugPrint('=== 코스 생성 완료 ===');
      debugPrint('요약: ${course.summary}');
      debugPrint('총 소요시간: ${course.totalDuration ~/ 60}분 ${course.totalDuration % 60}초');
      debugPrint('스텝 수: ${course.steps.length}');
      for (var i = 0; i < course.steps.length; i++) {
        final step = course.steps[i];
        debugPrint('  [${i + 1}] 동작:${step.moveIndex}, 도구:${step.toolIndex}, '
            '${step.duration}초 - ${step.reason}');
      }
      debugPrint('=====================');

      generator.dispose();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CourseResultScreen(
              course: course,
              isPostureBased: widget.isPostureBased,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 코스 생성 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('코스 생성에 실패했습니다: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          '로딩중',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 슬라이더 thumb에 현재 값을 항상 표시하는 커스텀 Shape.
class _NumberedThumbShape extends SliderComponentShape {
  const _NumberedThumbShape({required this.value});

  final int value;

  static const double _thumbRadius = 18.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_thumbRadius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    const accentColor = Color(0xFFBBFF00);

    // 외부 링 (stroke)
    final ringPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, _thumbRadius, ringPaint);

    // 내부 배경 (검정)
    final fillPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, _thumbRadius - 2, fillPaint);

    // 숫자 텍스트
    final textSpan = TextSpan(
      text: this.value.toString(),
      style: const TextStyle(
        color: accentColor,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }
}
