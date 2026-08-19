import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../course_generator/models/course.dart';
import '../../models/execution_model.dart';
import '../../services/course_mapper.dart';
import '../../services/database_helper.dart';
import '../main_shell.dart';
import '../posture/posture_guide_screen.dart';

/// 코스 완료 화면.
/// 코스 실행 후 부위별 피로도를 재입력받고, course_executions에 실행 기록을 저장한다.
/// 추가로 코스를 저장(isSaved)할 수 있는 섹션을 제공한다.
class CourseCompleteScreen extends StatefulWidget {
  const CourseCompleteScreen({
    super.key,
    required this.course,
    required this.courseId,
    this.isPostureBased = false,
    this.isReplay = false,
    this.isAlreadySaved = false,
  });

  final Course course;
  final int courseId;
  final bool isPostureBased;
  final bool isReplay;
  final bool isAlreadySaved;

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
    _fatigueLevels = {};
    if (!widget.isReplay) {
      final beforeMap = CourseMapper.extractBeforeFatigue(widget.course);
      for (final entry in beforeMap.entries) {
        _fatigueLevels[entry.key] = entry.value.toDouble().clamp(1.0, 10.0);
      }
      // 값이 0인 경우(초기 비교용 기본값)를 5로 교체
      for (final key in _fatigueLevels.keys.toList()) {
        if (_fatigueLevels[key]! < 1.0) {
          _fatigueLevels[key] = 5.0;
        }
      }
    }

    // 기존 저장 상태 확인
    if (widget.isAlreadySaved) {
      _isSaved = true;
    } else {
      DatabaseHelper().getCourseById(widget.courseId).then((course) {
        if (course != null && course.isSaved && mounted) {
          setState(() {
            _isSaved = true;
          });
        }
      });
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

  /// 코스 저장 로직.
  Future<void> _onSaveCourse() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final db = DatabaseHelper();
      final course = await db.getCourseById(widget.courseId);
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

  /// 홈 이동 로직 — 실행 기록 저장 후 네비게이션.
  Future<void> _onComplete() async {
    final db = DatabaseHelper();

    // before 피로도 맵 생성
    final beforeMap = widget.isReplay
        ? <String, int>{}
        : CourseMapper.extractBeforeFatigue(widget.course);

    // after 피로도 맵 생성 (측정 기반이거나 재실행이면 빈 맵)
    final afterMap = (widget.isPostureBased || widget.isReplay)
        ? <String, int>{}
        : _fatigueLevels.map(
            (key, value) => MapEntry(key, value.round()),
          );

    // 실행 기록 삽입
    final execution = ExecutionModel(
      courseId: widget.courseId,
      executedAt: DateTime.now(),
      before: beforeMap,
      after: afterMap,
    );
    await db.insertExecution(execution);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build methods
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    if (!widget.isPostureBased && !widget.isReplay) ...[
                      _buildFatigueSection(),
                      const SizedBox(height: 40),
                    ],
                    _buildSaveCourseSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      title: Text(
        '코스 완료',
        style: AppTypography.b18.copyWith(color: AppColors.textPrimary),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildFatigueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '운동 후 피로도 확인',
          style: AppTypography.sb24.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          '운동 전과 비교해 피로도가 얼마나 달라졌는지\n각 부위의 현재 피로도를 1~10으로 선택해주세요.',
          style: AppTypography.r14.copyWith(
            color: AppColors.textSecondary,
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

  Widget _buildSaveCourseSection() {
    final stepsCount = widget.course.steps.length;
    final durationMinutes = widget.course.totalDuration ~/ 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘 코스 저장하기',
          style: AppTypography.b20.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          '지금 코스를 저장하고 다음 운동에도 사용해보세요.',
          style: AppTypography.r14.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
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
                      style: AppTypography.b16.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '총 $stepsCount단계 · 예상시간 $durationMinutes분',
                      style: AppTypography.r12.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _isSaved || _isSaving ? null : _onSaveCourse,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary15,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary40,
                      width: 1,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Text(
                          _isSaved ? '저장 완료' : '저장',
                          style: AppTypography.r14.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        if (_saveError != null) ...[
          const SizedBox(height: 8),
          Text(
            _saveError!,
            style: AppTypography.r12.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }

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
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '홈으로 이동',
                style: AppTypography.b16.copyWith(color: AppColors.background),
              ),
            ),
          ),
          if (widget.isPostureBased) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                // 실행 기록 저장 (홈으로 이동과 동일하게)
                final db = DatabaseHelper();
                final beforeMap = widget.isReplay
                    ? <String, int>{}
                    : CourseMapper.extractBeforeFatigue(widget.course);
                final afterMap = <String, int>{};
                final execution = ExecutionModel(
                  courseId: widget.courseId,
                  executedAt: DateTime.now(),
                  before: beforeMap,
                  after: afterMap,
                );
                await db.insertExecution(execution);

                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                  (_) => false,
                );
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PostureGuideScreen()),
                );
              },
              child: Text(
                '자세 다시 점검하러 가기',
                style: AppTypography.r14.copyWith(
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textSecondary,
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
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.r12.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('1', style: AppTypography.r14.copyWith(color: AppColors.textSecondary)),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.toolSelectBox,
                thumbShape: _NumberedThumbShape(value: level.round()),
                overlayColor: AppColors.primary.withValues(alpha: 0.2),
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
          Text('10', style: AppTypography.r14.copyWith(color: AppColors.primary)),
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

    // 녹색으로 꽉 채운 원
    final fillPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, _thumbRadius, fillPaint);

    // 숫자 텍스트 (검정)
    final textSpan = TextSpan(
      text: this.value.toString(),
      style: const TextStyle(
        color: AppColors.background,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        fontFamily: 'NotoSansKR',
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
