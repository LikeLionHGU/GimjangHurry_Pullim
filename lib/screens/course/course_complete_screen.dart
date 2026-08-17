import 'package:flutter/material.dart';
import '../../course_generator/models/course.dart';
import '../../models/course_model.dart';
import '../../services/database_helper.dart';
import '../posture/posture_guide_screen.dart';

/// 코스 완료 화면.
/// 코스 실행 후 부위별 피로도를 재입력받고, DB에 after 피로도/status/progress를 업데이트한다.
/// 추가로 코스를 저장(isSaved)할 수 있는 섹션을 제공한다.
class CourseCompleteScreen extends StatefulWidget {
  const CourseCompleteScreen({
    super.key,
    required this.course,
    required this.courseId,
    this.isPostureBased = false,
  });

  final Course course;
  final int courseId;
  final bool isPostureBased;

  @override
  State<CourseCompleteScreen> createState() => _CourseCompleteScreenState();
}

class _CourseCompleteScreenState extends State<CourseCompleteScreen> {
  /// 부위 키(face_part) → 현재 피로도. 초기값은 before 값.
  late Map<String, double> _fatigueLevels;

  /// 코스 저장 완료 여부.
  bool _isSaved = false;

  /// 저장 진행 중 여부.
  bool _isSaving = false;

  /// 저장 실패 시 에러 메시지.
  String? _saveError;

  @override
  void initState() {
    super.initState();
    // before 피로도를 초기값으로 설정 (1~10 범위로 clamp, 없으면 5)
    final request = widget.course.request;
    _fatigueLevels = {};
    if (request != null) {
      for (final entry in request.fatigueEntries) {
        final face = entry.face.name; // 'front' or 'back'
        final part = entry.part.name;
        final key = '${face}_$part';
        final level = entry.level.toDouble().clamp(1.0, 10.0);
        // 겹치면 높은 쪽
        final current = _fatigueLevels[key] ?? 0.0;
        if (level > current) {
          _fatigueLevels[key] = level;
        }
      }
    }
    // 값이 0인 경우(초기 비교용 기본값)를 5로 교체
    for (final key in _fatigueLevels.keys.toList()) {
      if (_fatigueLevels[key]! < 1.0) {
        _fatigueLevels[key] = 5.0;
      }
    }

    // 기존 저장 상태 확인
    DatabaseHelper().getSavedCourseById(widget.courseId).then((course) {
      if (course != null && course.isSaved && mounted) {
        setState(() {
          _isSaved = true;
        });
      }
    });
  }

  /// 부위 키에서 한글 라벨을 생성한다.
  String _labelForKey(String key) {
    final parts = key.split('_');
    if (parts.length != 2) return key;
    final partName = parts[1];
    const partLabels = {
      'neck': '목',
      'shoulder': '어깨',
      'chest': '가슴',
      'arm': '팔',
      'abdomen': '복부',
      'pelvis': '골반',
      'thigh': '허벅지',
      'shin': '정강이',
      'sole': '발바닥',
      'upperBack': '등',
      'waist': '허리',
      'hip': '엉덩이',
      'calf': '종아리',
      'heel': '발뒤',
    };
    return partLabels[partName] ?? partName;
  }

  /// 코스 저장 로직.
  Future<void> _onSaveCourse() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final db = DatabaseHelper();
      final course = await db.getSavedCourseById(widget.courseId);
      if (course != null) {
        final updated = course.copyWith(isSaved: true);
        await db.updateCourse(updated);
      }
      if (!mounted) return;
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saveError = '저장에 실패했습니다. 다시 시도해주세요.';
        _isSaving = false;
      });
    }
  }

  /// 홈 이동 로직 — after 피로도 저장 후 네비게이션.
  Future<void> _onComplete() async {
    // after 피로도 맵 생성 (측정 기반이면 빈 맵)
    final afterMap = widget.isPostureBased
        ? <String, int>{}
        : _fatigueLevels.map(
            (key, value) => MapEntry(key, value.round()),
          );

    // DB 업데이트
    final db = DatabaseHelper();
    final courses = await db.getSavedCourseById(widget.courseId);
    if (courses != null) {
      final updated = courses.copyWith(
        after: afterMap,
        status: CourseStatus.completed,
        progress: 100,
        executedAt: DateTime.now(),
      );
      await db.updateCourse(updated);
    } else {
      // fallback: 직접 업데이트
      await db.updateCourseCompletion(
        courseId: widget.courseId,
        after: afterMap,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build methods
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false, // AppBar handles the top safe area
        child: Column(
          children: [
            // ── 스크롤 가능한 본문 ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    if (!widget.isPostureBased) ...[
                      _buildFatigueSection(),
                      const SizedBox(height: 40),
                    ],
                    _buildSaveCourseSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── 고정 하단 버튼 ──
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  /// 표준 AppBar — "코스 완료" 중앙 정렬, 뒤로가기 아이콘.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        '코스 완료',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  /// 피로도 확인 섹션 — 제목 + 설명 + 슬라이더 목록.
  Widget _buildFatigueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '운동 후 피로도 확인',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '운동 전과 비교해 피로도가 얼마나 달라졌는지\n각 부위의 현재 피로도를 1~10으로 선택해주세요.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        if (_fatigueLevels.isNotEmpty) ...[
          const SizedBox(height: 32),
          ..._fatigueLevels.keys.map(_buildFatigueSlider),
        ],
      ],
    );
  }

  /// 코스 저장 섹션 — 제목 + 설명 + 코스 카드(저장 버튼 포함).
  Widget _buildSaveCourseSection() {
    final stepsCount = widget.course.steps.length;
    final durationMinutes = widget.course.totalDuration ~/ 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘 코스 저장하기',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '지금 코스를 저장하고 다음 운동에도 사용해보세요.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        // Course Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '총 $stepsCount단계 · 예상시간 $durationMinutes분',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Save pill button
              GestureDetector(
                onTap: _isSaved || _isSaving ? null : _onSaveCourse,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A00),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF4A4A00),
                      width: 1,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFBBFF00),
                          ),
                        )
                      : Text(
                          _isSaved ? '저장 완료' : '저장',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBBFF00),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        // Error message
        if (_saveError != null) ...[
          const SizedBox(height: 8),
          Text(
            _saveError!,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  /// 하단 "홈으로 이동" 버튼.
  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBBFF00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                '홈으로 이동',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          if (widget.isPostureBased) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const PostureGuideScreen()),
                  (_) => false,
                );
              },
              child: const Text(
                '자세 다시 점검하러 가기',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.grey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFatigueSlider(String key) {
    final level = _fatigueLevels[key] ?? 5.0;
    final label = _labelForKey(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
          const Text('1', style: TextStyle(color: Colors.grey, fontSize: 14)),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFFBBFF00).withValues(alpha: 0.5),
                inactiveTrackColor: const Color(0xFFBBFF00).withValues(alpha: 0.5),
                thumbShape: _NumberedThumbShape(value: level.round()),
                overlayColor: const Color(0xFFBBFF00).withValues(alpha: 0.2),
                trackHeight: 2,
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
              style: TextStyle(color: Color(0xFFBBFF00), fontSize: 14)),
        ],
      ),
    );
  }
}

/// 슬라이더 thumb에 현재 값을 표시하는 커스텀 Shape.
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

    // Filled circle
    final fillPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, _thumbRadius, fillPaint);

    // Number text
    final textSpan = TextSpan(
      text: this.value.toString(),
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    final textOffset = Offset(
      center.dx - tp.width / 2,
      center.dy - tp.height / 2,
    );
    tp.paint(canvas, textOffset);
  }
}
