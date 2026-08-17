import 'package:flutter/material.dart';
import '../../course_generator/models/course.dart';
import '../../models/course_model.dart';
import '../../services/database_helper.dart';

/// 코스 완료 화면.
/// 코스 실행 후 부위별 피로도를 재입력받고, DB에 after 피로도/status/progress를 업데이트한다.
class CourseCompleteScreen extends StatefulWidget {
  const CourseCompleteScreen({
    super.key,
    required this.course,
    required this.courseId,
  });

  final Course course;
  final int courseId;

  @override
  State<CourseCompleteScreen> createState() => _CourseCompleteScreenState();
}

class _CourseCompleteScreenState extends State<CourseCompleteScreen> {
  /// 부위 키(face_part) → 현재 피로도. 초기값은 before 값.
  late Map<String, double> _fatigueLevels;

  @override
  void initState() {
    super.initState();
    // before 피로도를 초기값으로 설정
    final request = widget.course.request;
    _fatigueLevels = {};
    if (request != null) {
      for (final entry in request.fatigueEntries) {
        final face = entry.face.name; // 'front' or 'back'
        final part = entry.part.name;
        final key = '${face}_$part';
        // 겹치면 높은 쪽
        final current = _fatigueLevels[key] ?? 0.0;
        if (entry.level.toDouble() > current) {
          _fatigueLevels[key] = entry.level.toDouble();
        }
      }
    }
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

  Future<void> _onComplete() async {
    // after 피로도 맵 생성
    final afterMap = _fatigueLevels.map(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 뒤로가기 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // ── 본문 ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      '코스 완료!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '피곤한 부위의 피로도를 선택하세요.\n1(최소) - 10(최대)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 피로도 슬라이더 목록
                    ..._fatigueLevels.keys.map(_buildFatigueSlider),
                    const Spacer(),
                  ],
                ),
              ),
            ),

            // ── 하단 버튼 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
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
            ),
          ],
        ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFBBFF00)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFBBFF00),
                fontSize: 12,
                fontWeight: FontWeight.w500,
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

    final ringPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, _thumbRadius, ringPaint);

    final fillPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, _thumbRadius - 2, fillPaint);

    final textSpan = TextSpan(
      text: this.value.toString(),
      style: const TextStyle(
        color: accentColor,
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
