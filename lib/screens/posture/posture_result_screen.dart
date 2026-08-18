import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../models/posture_result_model.dart';
import '../main_shell.dart';

class PostureResultScreen extends StatefulWidget {
  final PostureResultModel result;
  final String? frontImagePath;
  final String? sideImagePath;
  final Map<String, double> frontAngles;
  final Map<String, double> sideAngles;
  final int score;

  const PostureResultScreen({
    super.key,
    required this.result,
    this.frontImagePath,
    this.sideImagePath,
    required this.frontAngles,
    required this.sideAngles,
    required this.score,
  });

  @override
  State<PostureResultScreen> createState() => _PostureResultScreenState();
}

class _PostureResultScreenState extends State<PostureResultScreen> {
  bool _showFront = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자세 분석 결과'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 사진 + 스켈레톤 오버레이
                    _buildPhotoSection(),

                    // 정면/측면 탭
                    _buildTabSwitch(),
                    const SizedBox(height: 20),

                    // 전체 자세 점수
                    _buildScoreSection(),
                    const SizedBox(height: 24),

                    // 분석 항목 리스트
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _showFront ? '자세 분석 · 정면' : '자세 분석 · 측면',
                            style: AppTypography.b16.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_showFront) ..._buildFrontItems() else ..._buildSideItems(),
                        ],
                      ),
                    ),

                    // 면책
                    _buildDisclaimer(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 모든 이전 화면을 지우고 홈으로 이동
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainShell()),
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('코스 시작하기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 사진 + 스켈레톤 오버레이
  Widget _buildPhotoSection() {
    final imagePath = _showFront ? widget.frontImagePath : widget.sideImagePath;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 배경 사진
              if (imagePath != null && File(imagePath).existsSync())
                Image.file(File(imagePath), fit: BoxFit.cover)
              else
                Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(Icons.person_outline, color: AppColors.textTertiary, size: 64),
                  ),
                ),

              // 스켈레톤 오버레이 (점+선 형태 - GUI처럼)
              if (imagePath != null)
                CustomPaint(
                  painter: _SkeletonPainter(isFront: _showFront),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 정면/측면 탭 전환
  Widget _buildTabSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTab('정면', _showFront),
        const SizedBox(width: 8),
        _buildTab('측면', !_showFront),
      ],
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() => _showFront = label == '정면');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.r12.copyWith(
            color: isActive ? AppColors.background : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 전체 자세 점수 (원형)
  Widget _buildScoreSection() {
    return Column(
      children: [
        Text(
          '전체 자세 점수',
          style: AppTypography.r14.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _scoreColor, width: 4),
          ),
          child: Center(
            child: Text(
              '${widget.score}',
              style: AppTypography.b35.copyWith(
                color: _scoreColor,
                fontSize: 38,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '평가 가능한 항목만 합산해 100점으로 환산합니다. (전체 축: 5개)',
          style: AppTypography.r12.copyWith(color: AppColors.textTertiary, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color get _scoreColor {
    if (widget.score >= 85) return AppColors.primary;
    if (widget.score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  /// 정면 분석 항목들
  List<Widget> _buildFrontItems() {
    return [
      _AnalysisCard(
        title: '어깨 높이 차이',
        value: _fmt(widget.frontAngles['shoulder_height_diff']),
        unit: '°',
        description: _shoulderHeightDesc(),
        isNormal: (widget.frontAngles['shoulder_height_diff']?.abs() ?? 0) <= 12,
      ),
      _AnalysisCard(
        title: '골반 기울기',
        value: _fmt(widget.frontAngles['hip_height_diff']),
        unit: '°',
        description: _hipTiltDesc(),
        isNormal: (widget.frontAngles['hip_height_diff']?.abs() ?? 0) <= 8,
      ),
      _AnalysisCard(
        title: '몸통 기울기',
        value: _fmt(widget.frontAngles['torso_tilt']),
        unit: '°',
        description: _torsoTiltDesc(),
        isNormal: (widget.frontAngles['torso_tilt']?.abs() ?? 0) <= 0.05,
      ),
      _AnalysisCard(
        title: '머리 기울기',
        value: _fmt(widget.frontAngles['head_lateral_shift']),
        unit: '',
        description: _headShiftDesc(),
        isNormal: (widget.frontAngles['head_lateral_shift']?.abs() ?? 0) <= 0.08,
      ),
      _AnalysisCard(
        title: '머리 좌우 편위',
        value: _fmt(widget.frontAngles['head_lateral_shift']),
        unit: '',
        description: '머리가 몸통 중심선 위에 있습니다.',
        isNormal: (widget.frontAngles['head_lateral_shift']?.abs() ?? 0) <= 0.08,
      ),
      _AnalysisCard(
        title: '왼쪽 무릎 정렬',
        value: _fmt(widget.frontAngles['left_knee']),
        unit: '°',
        description: _kneeDesc(widget.frontAngles['left_knee']),
        isNormal: _kneeNormal(widget.frontAngles['left_knee']),
      ),
      _AnalysisCard(
        title: '오른쪽 무릎 정렬',
        value: _fmt(widget.frontAngles['right_knee']),
        unit: '°',
        description: _kneeDesc(widget.frontAngles['right_knee']),
        isNormal: _kneeNormal(widget.frontAngles['right_knee']),
      ),
    ];
  }

  /// 측면 분석 항목들
  List<Widget> _buildSideItems() {
    return [
      _AnalysisCard(
        title: '거북목(두개척추각)',
        value: _fmt(widget.sideAngles['neck_angle']),
        unit: '°',
        description: _neckDesc(),
        isNormal: (widget.sideAngles['neck_angle'] ?? 0) <= 35,
      ),
      _AnalysisCard(
        title: '머리 전방 이동량',
        value: _fmt(widget.sideAngles['forward_head']),
        unit: '',
        description: _forwardHeadDesc(),
        isNormal: (widget.sideAngles['forward_head']?.abs() ?? 0) <= 0.2,
      ),
      _AnalysisCard(
        title: '어깨 전방활주',
        value: _fmt(widget.sideAngles['shoulder_forward']),
        unit: '',
        description: _shoulderForwardDesc(),
        isNormal: (widget.sideAngles['shoulder_forward']?.abs() ?? 0) <= 0.1,
      ),
      _AnalysisCard(
        title: '몸통 전후 기울기',
        value: _fmt(widget.sideAngles['torso_forward_tilt']),
        unit: '°',
        description: _torsoForwardDesc(),
        isNormal: _torsoForwardNormal(),
      ),
    ];
  }

  /// 면책 안내
  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI 기반 자세 참고 분석 결과입니다. 의료적 진단을 대신하지 않습니다.',
              style: AppTypography.r12.copyWith(
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
  String _fmt(double? v) => v == null ? '-' : v.toStringAsFixed(2);

  String _shoulderHeightDesc() {
    final d = widget.frontAngles['shoulder_height_diff'] ?? 0;
    if (d.abs() <= 12) return '좌우 어깨 높이가 거의 동일합니다.';
    return d > 0 ? '왼쪽 어깨가 더 낮습니다.' : '오른쪽 어깨가 더 낮습니다.';
  }

  String _hipTiltDesc() {
    final d = widget.frontAngles['hip_height_diff']?.abs() ?? 0;
    if (d <= 8) return '좌우 골반 높이가 균형을 이루고 있습니다.';
    return '골반이 한쪽으로 기울어져 있습니다.';
  }

  String _torsoTiltDesc() {
    final d = widget.frontAngles['torso_tilt']?.abs() ?? 0;
    if (d <= 0.05) return '몸통이 좌우로 치우치지 않았습니다.';
    return '몸통이 한쪽으로 기울어져 있습니다.';
  }

  String _headShiftDesc() {
    final d = widget.frontAngles['head_lateral_shift'] ?? 0;
    if (d.abs() <= 0.08) return '머리가 몸통 중심선 위에 있습니다.';
    return d > 0 ? '머리가 오른쪽으로 기울어 있습니다.' : '머리가 왼쪽으로 기울어 있습니다.';
  }

  String _kneeDesc(double? angle) {
    if (angle == null) return '측정되지 않았습니다.';
    if (angle >= 165 && angle <= 185) return '골반→무릎→발목이 거의 일직선입니다.';
    if (angle < 165) return '무릎이 바깥쪽으로 벌어지는 경향이 있습니다.';
    return '무릎이 과신전되어 있습니다.';
  }

  bool _kneeNormal(double? angle) => angle != null && angle >= 165 && angle <= 185;

  String _neckDesc() {
    final a = widget.sideAngles['neck_angle'] ?? 0;
    if (a <= 35) return '머리가 어깨 위에 잘 정렬되어 있습니다.';
    return '머리가 어깨보다 앞으로 나와 있습니다.';
  }

  String _forwardHeadDesc() {
    final v = widget.sideAngles['forward_head']?.abs() ?? 0;
    if (v <= 0.2) return '귀가 어깨 축에서 크게 벗어나지 않았습니다.';
    return '머리가 앞으로 돌출되어 있습니다.';
  }

  String _shoulderForwardDesc() {
    final v = widget.sideAngles['shoulder_forward']?.abs() ?? 0;
    if (v <= 0.1) return '어깨가 골반 축 위에 놓여 있습니다.';
    return '어깨가 앞으로 말리는 경향이 있습니다.';
  }

  String _torsoForwardDesc() {
    final a = widget.sideAngles['torso_forward_tilt'] ?? 180;
    if (a >= 165 && a <= 195) return '상체가 바르게 서 있습니다.';
    return '상체가 뒤로 젖혀져 있습니다.';
  }

  bool _torsoForwardNormal() {
    final a = widget.sideAngles['torso_forward_tilt'] ?? 180;
    return a >= 165 && a <= 195;
  }
}

/// 분석 항목 카드 위젯
class _AnalysisCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String description;
  final bool isNormal;

  const _AnalysisCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.description,
    required this.isNormal,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isNormal ? AppColors.primary : AppColors.warning;
    final statusText = isNormal ? '정상' : '주의';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNormal ? AppColors.border : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 상태 뱃지
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.r14.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusText,
                  style: AppTypography.r12.copyWith(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 수치
          Text(
            '$value$unit',
            style: AppTypography.sb24.copyWith(
              color: statusColor,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),

          // 설명
          Text(
            description,
            style: AppTypography.r12.copyWith(
              color: AppColors.textTertiary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// 스켈레톤 페인터 (점+선 형태 - GUI처럼 흰/초록 점과 연결선)
class _SkeletonPainter extends CustomPainter {
  final bool isFront;
  _SkeletonPainter({required this.isFront});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 가상의 표준 스켈레톤 좌표 (비율 기반)
    final points = _getSkeletonPoints(size, isFront);

    // 연결선
    for (final conn in _getConnections()) {
      if (conn[0] < points.length && conn[1] < points.length) {
        canvas.drawLine(points[conn[0]], points[conn[1]], linePaint);
      }
    }

    // 점
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
    }
  }

  List<Offset> _getSkeletonPoints(Size size, bool front) {
    final cx = size.width * 0.5;
    // 0:코, 1:왼어깨, 2:오른어깨, 3:왼팔꿈치, 4:오른팔꿈치,
    // 5:왼손목, 6:오른손목, 7:왼골반, 8:오른골반,
    // 9:왼무릎, 10:오른무릎, 11:왼발목, 12:오른발목
    if (front) {
      return [
        Offset(cx, size.height * 0.08),         // 코
        Offset(cx - size.width * 0.15, size.height * 0.18), // 왼어깨
        Offset(cx + size.width * 0.15, size.height * 0.18), // 오른어깨
        Offset(cx - size.width * 0.22, size.height * 0.32), // 왼팔꿈치
        Offset(cx + size.width * 0.22, size.height * 0.32), // 오른팔꿈치
        Offset(cx - size.width * 0.20, size.height * 0.44), // 왼손목
        Offset(cx + size.width * 0.20, size.height * 0.44), // 오른손목
        Offset(cx - size.width * 0.08, size.height * 0.48), // 왼골반
        Offset(cx + size.width * 0.08, size.height * 0.48), // 오른골반
        Offset(cx - size.width * 0.09, size.height * 0.68), // 왼무릎
        Offset(cx + size.width * 0.09, size.height * 0.68), // 오른무릎
        Offset(cx - size.width * 0.09, size.height * 0.90), // 왼발목
        Offset(cx + size.width * 0.09, size.height * 0.90), // 오른발목
      ];
    } else {
      // 측면
      return [
        Offset(cx + size.width * 0.02, size.height * 0.08),  // 코
        Offset(cx - size.width * 0.02, size.height * 0.18),  // 어깨
        Offset(cx - size.width * 0.02, size.height * 0.18),  // (동일)
        Offset(cx - size.width * 0.10, size.height * 0.32),  // 팔꿈치
        Offset(cx - size.width * 0.10, size.height * 0.32),  // (동일)
        Offset(cx - size.width * 0.05, size.height * 0.44),  // 손목
        Offset(cx - size.width * 0.05, size.height * 0.44),  // (동일)
        Offset(cx, size.height * 0.48),                       // 골반
        Offset(cx, size.height * 0.48),                       // (동일)
        Offset(cx + size.width * 0.02, size.height * 0.68),   // 무릎
        Offset(cx + size.width * 0.02, size.height * 0.68),   // (동일)
        Offset(cx + size.width * 0.01, size.height * 0.90),   // 발목
        Offset(cx + size.width * 0.01, size.height * 0.90),   // (동일)
      ];
    }
  }

  List<List<int>> _getConnections() {
    return [
      [0, 1], [0, 2],       // 코 → 어깨
      [1, 2],               // 어깨 연결
      [1, 3], [3, 5],       // 왼팔
      [2, 4], [4, 6],       // 오른팔
      [1, 7], [2, 8],       // 어깨 → 골반
      [7, 8],               // 골반 연결
      [7, 9], [9, 11],      // 왼다리
      [8, 10], [10, 12],    // 오른다리
    ];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
