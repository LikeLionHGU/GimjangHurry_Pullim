import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../assets/body_assets.dart';
import '../../assets/move_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../course_generator/models/course.dart';
import '../../course_generator/models/course_step.dart';
import 'course_complete_screen.dart';

/// 코스 실행 화면.
/// 각 스텝을 순서대로 동작 정보 → 타이머 → 다음 스텝 흐름으로 진행한다.
class CourseExecutionScreen extends StatefulWidget {
  const CourseExecutionScreen({
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
  State<CourseExecutionScreen> createState() => _CourseExecutionScreenState();
}

class _CourseExecutionScreenState extends State<CourseExecutionScreen> {
  int _currentStepIndex = 0;
  bool _isTimerMode = false;

  // 타이머 관련
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isPaused = false;

  // 이미지 페이지 컨트롤러
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  CourseStep get _currentStep => widget.course.steps[_currentStepIndex];
  int get _totalSteps => widget.course.steps.length;

  Move? get _currentMove => kMoves[_currentStep.moveIndex];

  /// 현재 동작의 첫 번째 body 인덱스로 부위 이미지 경로를 생성한다.
  String? get _bodyImagePath {
    final move = _currentMove;
    if (move == null || move.body.isEmpty) return null;
    final body = kBodies[move.body.first];
    if (body == null) return null;
    final face = body.forb == BodyFace.front ? 'front' : 'back';
    final part = body.part.name;
    return 'assets/images/body/${face}_$part.png';
  }

  void _startTimer() {
    setState(() {
      _isTimerMode = true;
      _remainingSeconds = _currentStep.duration;
      _isPaused = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeTimer() {
    setState(() => _isPaused = false);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  void _restartTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _currentStep.duration;
      _isPaused = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  void _onBackPressed() {
    if (_isTimerMode) {
      // 타이머 → 현재 동작 정보로 돌아감
      _timer?.cancel();
      setState(() {
        _isTimerMode = false;
        _isPaused = false;
        _remainingSeconds = 0;
      });
    } else if (_currentStepIndex > 0) {
      // 동작 정보 → 이전 동작의 타이머로 돌아감
      setState(() {
        _currentStepIndex--;
        _isTimerMode = true;
        _remainingSeconds = 0; // 타이머는 이미 완료된 상태로 표시
        _isPaused = false;
        _pageController = PageController();
      });
    } else {
      // 첫 동작 정보에서 뒤로가기 → 코스 결과 화면으로 pop
      Navigator.pop(context);
    }
  }

  void _goToNextStep() {
    _timer?.cancel();
    if (_currentStepIndex >= _totalSteps - 1) {
      // 마지막 스텝 완료 → 완료 화면
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseCompleteScreen(
            course: widget.course,
            courseId: widget.courseId,
            isPostureBased: widget.isPostureBased,
            isReplay: widget.isReplay,
            isAlreadySaved: widget.isAlreadySaved,
          ),
        ),
      );
      return;
    }
    setState(() {
      _currentStepIndex++;
      _isTimerMode = false;
      _isPaused = false;
      _remainingSeconds = 0;
      _pageController = PageController();
    });
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                    onPressed: _onBackPressed,
                  ),
                  Expanded(
                    child: Text(
                      '코스 실행',
                      textAlign: TextAlign.center,
                      style: AppTypography.sb18.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // 코스 요약 카드
                    _buildCourseInfoCard(),
                    const SizedBox(height: 16),
                    // Progress bar
                    _buildProgressBar(),
                    const SizedBox(height: 24),
                    // 동작 정보 또는 타이머
                    if (_isTimerMode)
                      _buildTimerView()
                    else
                      _buildStepInfoView(),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isTimerMode ? _goToNextStep : _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '다음 단계',
                    style: AppTypography.b16.copyWith(color: AppColors.background),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 코스 요약 카드.
  Widget _buildCourseInfoCard() {
    final totalMinutes = widget.course.totalDuration ~/ 60;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.course.name,
            style: AppTypography.b16.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '총 $_totalSteps단계 · 예상시간 $totalMinutes분',
            style: AppTypography.r12.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Progress bar.
  Widget _buildProgressBar() {
    final progress = (_currentStepIndex + 1) / _totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_currentStepIndex + 1}단계/ $_totalSteps단계',
          style: AppTypography.r12.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.toolSelectBox,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  /// 동작 정보 뷰 (이미지 스와이프 + 이완 방법).
  Widget _buildStepInfoView() {
    final move = _currentMove;
    final moveName = move?.name ?? '동작 ${_currentStep.moveIndex}';
    final timeText = _formatTime(_currentStep.duration);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 동작 이름
        Text(
          moveName,
          style: AppTypography.b20.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        // 시간
        Text(
          timeText,
          style: AppTypography.b32.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        // 이미지 스와이프 영역
        _buildImageSwiper(),
        const SizedBox(height: 24),
        // 이완 방법
        Text(
          '이완 방법',
          style: AppTypography.b16.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        _buildDescription(),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 이미지 스와이프 (PageView + dots indicator).
  Widget _buildImageSwiper() {
    final bodyImage = _bodyImagePath;

    return Column(
      children: [
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView(
              controller: _pageController,
              children: [
                // 페이지 1: 동작 이미지
                Container(
                  color: AppColors.cardBackground,
                  padding: const EdgeInsets.all(16),
                  child: _currentMove != null
                      ? Image.asset(
                          _currentMove!.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image_outlined,
                                    color: AppColors.textSecondary, size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  '이미지 없음',
                                  style: AppTypography.r14.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            '동작 이미지 없음',
                            style: AppTypography.r14.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                ),
                // 페이지 2: 부위 이미지
                Container(
                  color: AppColors.cardBackground,
                  padding: const EdgeInsets.all(16),
                  child: bodyImage != null
                      ? Image.asset(
                          bodyImage,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              '이미지 없음',
                              style: AppTypography.r14.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            '부위 이미지 없음',
                            style: AppTypography.r14.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Dots indicator
        _PageDotsIndicator(controller: _pageController, pageCount: 2),
      ],
    );
  }

  /// 이완 방법 텍스트 (bullet points).
  Widget _buildDescription() {
    final move = _currentMove;
    if (move == null) {
      return Text(
        '설명 없음',
        style: AppTypography.r14.copyWith(color: AppColors.textSecondary),
      );
    }

    final lines = move.descriptionLines;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.toolSelectBox),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: AppTypography.r14.copyWith(color: AppColors.textPrimary)),
                Expanded(
                  child: Text(
                    line,
                    style: AppTypography.r14.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 타이머 뷰.
  Widget _buildTimerView() {
    final totalSeconds = _currentStep.duration;
    final progress = totalSeconds > 0
        ? (_remainingSeconds / totalSeconds)
        : 0.0;

    return Column(
      children: [
        const SizedBox(height: 40),
        // 원형 타이머
        SizedBox(
          width: 220,
          height: 220,
          child: CustomPaint(
            painter: _CircularTimerPainter(progress: progress),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '남은 시간',
                    style: AppTypography.r14.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: AppTypography.b35.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        // 일시정지 / 다시 시작 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 일시정지 / 재개 버튼
            _buildControlButton(
              icon: _isPaused ? Icons.play_arrow : Icons.pause,
              label: _isPaused ? '재개' : '일시정지',
              onTap: _remainingSeconds <= 0
                  ? null
                  : (_isPaused ? _resumeTimer : _pauseTimer),
            ),
            const SizedBox(width: 48),
            // 다시 시작 버튼
            _buildControlButton(
              icon: Icons.refresh,
              label: '다시 시작',
              onTap: _restartTimer,
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDisabled ? AppColors.secondary : AppColors.secondary,
              border: Border.all(
                color: isDisabled ? AppColors.toolSelectBox : AppColors.textSecondary,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isDisabled ? AppColors.toolSelectBox : AppColors.textPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.r12.copyWith(
              color: isDisabled ? AppColors.toolSelectBox : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 페이지 dots indicator.
class _PageDotsIndicator extends StatefulWidget {
  const _PageDotsIndicator({
    required this.controller,
    required this.pageCount,
  });

  final PageController controller;
  final int pageCount;

  @override
  State<_PageDotsIndicator> createState() => _PageDotsIndicatorState();
}

class _PageDotsIndicatorState extends State<_PageDotsIndicator> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onPageChanged() {
    final page = widget.controller.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() => _currentPage = page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.pageCount, (index) {
        final isActive = index == _currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.textPrimary : AppColors.toolSelectBox,
          ),
        );
      }),
    );
  }
}

/// 원형 타이머 페인터.
class _CircularTimerPainter extends CustomPainter {
  const _CircularTimerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // 배경 원
    final bgPaint = Paint()
      ..color = AppColors.toolSelectBox
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    // 진행 아크
    final progressPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
