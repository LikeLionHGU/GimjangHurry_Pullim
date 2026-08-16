import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/posture_result_model.dart';

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

class _PostureResultScreenState extends State<PostureResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자세 분석 결과'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '처음으로',
              style: TextStyle(color: AppColors.primary, fontSize: 14),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 정면/측면 탭
            _buildTabBar(),
            // 탭 내용
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFrontTab(),
                  _buildSideTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: AppColors.background,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        dividerHeight: 0,
        tabs: const [
          Tab(text: '정면'),
          Tab(text: '측면'),
        ],
      ),
    );
  }

  Widget _buildFrontTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // 촬영 사진 + 실루엣 오버레이
          _buildPhotoWithOverlay(widget.frontImagePath, isFront: true),
          const SizedBox(height: 24),

          // 분석 항목들
          const Text(
            '자세 분석 · 정면',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          _buildAnalysisItem(
            icon: Icons.straighten,
            title: '어깨 높이 차이',
            value: '${_formatValue(widget.frontAngles['shoulder_height_diff'])}°',
            description: _getShoulderHeightDesc(),
            status: _getStatus(widget.frontAngles['shoulder_height_diff']?.abs() ?? 0, 12),
          ),
          _buildAnalysisItem(
            icon: Icons.swap_vert,
            title: '골반 기울기',
            value: '${_formatValue(widget.frontAngles['hip_height_diff'])}°',
            description: _getHipTiltDesc(),
            status: _getStatus(widget.frontAngles['hip_height_diff']?.abs() ?? 0, 8),
          ),
          _buildAnalysisItem(
            icon: Icons.vertical_align_center,
            title: '몸통 기울기',
            value: _formatValue(widget.frontAngles['torso_tilt']),
            description: _getTorsoTiltDesc(),
            status: _getStatus((widget.frontAngles['torso_tilt']?.abs() ?? 0) * 100, 5),
          ),
          _buildAnalysisItem(
            icon: Icons.face,
            title: '머리 좌우 편위',
            value: _formatValue(widget.frontAngles['head_lateral_shift']),
            description: _getHeadShiftDesc(),
            status: _getStatus((widget.frontAngles['head_lateral_shift']?.abs() ?? 0) * 100, 8),
          ),
          _buildAnalysisItem(
            icon: Icons.accessibility_new,
            title: '왼쪽 무릎 정렬',
            value: '${_formatValue(widget.frontAngles['left_knee'])}°',
            description: _getKneeDesc(widget.frontAngles['left_knee']),
            status: _getKneeStatus(widget.frontAngles['left_knee']),
          ),
          _buildAnalysisItem(
            icon: Icons.accessibility_new,
            title: '오른쪽 무릎 정렬',
            value: '${_formatValue(widget.frontAngles['right_knee'])}°',
            description: _getKneeDesc(widget.frontAngles['right_knee']),
            status: _getKneeStatus(widget.frontAngles['right_knee']),
          ),

          const SizedBox(height: 24),
          _buildScoreSection(),
          const SizedBox(height: 16),
          _buildDisclaimer(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSideTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildPhotoWithOverlay(widget.sideImagePath, isFront: false),
          const SizedBox(height: 24),

          const Text(
            '자세 분석 · 측면',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          _buildAnalysisItem(
            icon: Icons.emoji_people,
            title: '거북목 (두개부추각)',
            value: '${_formatValue(widget.sideAngles['neck_angle'])}°',
            description: _getNeckDesc(),
            status: _getNeckStatus(),
          ),
          _buildAnalysisItem(
            icon: Icons.person,
            title: '머리 전방 이동량',
            value: _formatValue(widget.sideAngles['forward_head']),
            description: _getForwardHeadDesc(),
            status: _getStatus((widget.sideAngles['forward_head']?.abs() ?? 0) * 100, 20),
          ),
          _buildAnalysisItem(
            icon: Icons.arrow_forward,
            title: '어깨 전방활주',
            value: _formatValue(widget.sideAngles['shoulder_forward']),
            description: _getShoulderForwardDesc(),
            status: _getStatus((widget.sideAngles['shoulder_forward']?.abs() ?? 0) * 100, 10),
          ),
          _buildAnalysisItem(
            icon: Icons.height,
            title: '몸통 전후 기울기',
            value: '${_formatValue(widget.sideAngles['torso_forward_tilt'])}°',
            description: _getTorsoForwardDesc(),
            status: _getTorsoForwardStatus(),
          ),

          const SizedBox(height: 24),
          _buildScoreSection(),
          const SizedBox(height: 16),
          _buildDisclaimer(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 사진 + 체형 실루엣 오버레이
  Widget _buildPhotoWithOverlay(String? imagePath, {required bool isFront}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 사진
            if (imagePath != null && File(imagePath).existsSync())
              Image.file(
                File(imagePath),
                fit: BoxFit.cover,
              )
            else
              Container(
                color: AppColors.surface,
                child: const Center(
                  child: Icon(Icons.person_outline, color: AppColors.textTertiary, size: 64),
                ),
              ),

            // 사람 체형 실루엣 오버레이
            CustomPaint(
              painter: _BodySilhouettePainter(
                isFront: isFront,
                angles: isFront ? widget.frontAngles : widget.sideAngles,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 분석 항목 위젯
  Widget _buildAnalysisItem({
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required _AnalysisStatus status,
  }) {
    final statusColor = status == _AnalysisStatus.normal
        ? AppColors.primary
        : status == _AnalysisStatus.warning
            ? AppColors.warning
            : AppColors.error;
    final statusText = status == _AnalysisStatus.normal ? '정상' : '비정상';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // 상태 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$value  측정 기준',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 전체 자세 점수
  Widget _buildScoreSection() {
    return Center(
      child: Column(
        children: [
          const Text(
            '전체 자세 점수',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getScoreColor(widget.score),
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                '${widget.score}',
                style: TextStyle(
                  color: _getScoreColor(widget.score),
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'AI 기반 자세 점검 결과입니다. 의료적 진단을 대신하지 않습니다.\n'
        '수치는 사진에서의 추정 값이며, 촬영 각도나 자세에 따라 달라질 수 있습니다. 정확한 진단은 전문의를 방문하세요.',
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          height: 1.5,
        ),
      ),
    );
  }

  // --- Helper methods ---

  Color _getScoreColor(int score) {
    if (score >= 85) return AppColors.primary;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String _formatValue(double? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(2);
  }

  _AnalysisStatus _getStatus(double absValue, double threshold) {
    return absValue <= threshold ? _AnalysisStatus.normal : _AnalysisStatus.warning;
  }

  _AnalysisStatus _getKneeStatus(double? angle) {
    if (angle == null) return _AnalysisStatus.normal;
    return (angle >= 165 && angle <= 185) ? _AnalysisStatus.normal : _AnalysisStatus.warning;
  }

  _AnalysisStatus _getNeckStatus() {
    final angle = widget.sideAngles['neck_angle'] ?? 0;
    return angle <= 35 ? _AnalysisStatus.normal : _AnalysisStatus.warning;
  }

  _AnalysisStatus _getTorsoForwardStatus() {
    final angle = widget.sideAngles['torso_forward_tilt'] ?? 180;
    return (angle >= 165 && angle <= 195) ? _AnalysisStatus.normal : _AnalysisStatus.warning;
  }

  String _getShoulderHeightDesc() {
    final diff = widget.frontAngles['shoulder_height_diff'] ?? 0;
    if (diff.abs() <= 12) return '좌우 어깨 높이가 거의 동일합니다.';
    return diff > 0 ? '왼쪽 어깨가 더 낮습니다.' : '오른쪽 어깨가 더 낮습니다.';
  }

  String _getHipTiltDesc() {
    final diff = widget.frontAngles['hip_height_diff'] ?? 0;
    if (diff.abs() <= 8) return '좌우 골반 높이가 균형을 이루고 있습니다.';
    return '골반이 한쪽으로 기울어져 있습니다.';
  }

  String _getTorsoTiltDesc() {
    final tilt = widget.frontAngles['torso_tilt']?.abs() ?? 0;
    if (tilt <= 0.05) return '몸통이 좌우로 치우치지 않았습니다.';
    return '몸통이 한쪽으로 기울어져 있습니다.';
  }

  String _getHeadShiftDesc() {
    final shift = widget.frontAngles['head_lateral_shift'] ?? 0;
    if (shift.abs() <= 0.08) return '머리가 몸통 중심선 위에 있습니다.';
    return shift > 0 ? '머리가 오른쪽으로 기울어져 있습니다.' : '머리가 왼쪽으로 기울어져 있습니다.';
  }

  String _getKneeDesc(double? angle) {
    if (angle == null) return '측정되지 않았습니다.';
    if (angle >= 165 && angle <= 185) return '골반→무릎→발목이 거의 일직선입니다.';
    if (angle < 165) return '무릎이 바깥쪽으로 벌어지는 경향이 있습니다.';
    return '무릎이 과신전되어 있습니다.';
  }

  String _getNeckDesc() {
    final angle = widget.sideAngles['neck_angle'] ?? 0;
    if (angle <= 35) return '머리가 어깨 위에 잘 정렬되어 있습니다.';
    return '머리가 어깨보다 앞으로 나와 있습니다.';
  }

  String _getForwardHeadDesc() {
    final val = widget.sideAngles['forward_head']?.abs() ?? 0;
    if (val <= 0.2) return '귀가 어깨 중에서 크게 벗어나지 않았습니다.';
    return '머리가 앞으로 돌출되어 있습니다.';
  }

  String _getShoulderForwardDesc() {
    final val = widget.sideAngles['shoulder_forward']?.abs() ?? 0;
    if (val <= 0.1) return '어깨가 골반 직 위에 놓여 있습니다.';
    return '어깨가 앞으로 말리는 경향이 있습니다.';
  }

  String _getTorsoForwardDesc() {
    final angle = widget.sideAngles['torso_forward_tilt'] ?? 180;
    if (angle >= 165 && angle <= 195) return '상체가 바르게 서 있습니다.';
    return '상체가 앞 또는 뒤로 기울어져 있습니다.';
  }
}

enum _AnalysisStatus { normal, warning }

/// 체형 실루엣 페인터 - 스켈레톤이 아닌 사람 모양의 두꺼운 실루엣으로 표현
class _BodySilhouettePainter extends CustomPainter {
  final bool isFront;
  final Map<String, double> angles;

  _BodySilhouettePainter({required this.isFront, required this.angles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    // 신체 비율 기반 좌표 생성
    final cx = size.width / 2;
    final headY = size.height * 0.08;
    final shoulderY = size.height * 0.22;
    final hipY = size.height * 0.52;
    final kneeY = size.height * 0.72;
    final ankleY = size.height * 0.92;
    final elbowY = size.height * 0.37;
    final wristY = size.height * 0.48;

    final shoulderW = size.width * 0.22;
    final hipW = size.width * 0.15;
    final limbWidth = size.width * 0.045; // 팔다리 두께

    // 자세 왜곡 적용
    double headOffsetX = 0;
    double shoulderOffsetY = 0;
    double hipOffset = 0;

    if (isFront) {
      headOffsetX = (angles['head_lateral_shift'] ?? 0) * size.width * 0.15;
      shoulderOffsetY = (angles['shoulder_height_diff'] ?? 0) * 0.3;
      hipOffset = (angles['hip_height_diff'] ?? 0) * 0.3;
    }

    // 머리
    canvas.drawCircle(
      Offset(cx + headOffsetX, headY),
      size.width * 0.055,
      paint,
    );
    canvas.drawCircle(
      Offset(cx + headOffsetX, headY),
      size.width * 0.055,
      linePaint,
    );

    // 목
    _drawLimb(canvas, Offset(cx + headOffsetX, headY + size.width * 0.055),
        Offset(cx, shoulderY), limbWidth * 0.7, paint, linePaint);

    // 몸통 (사다리꼴)
    final torsoPath = Path()
      ..moveTo(cx - shoulderW, shoulderY - shoulderOffsetY)
      ..lineTo(cx + shoulderW, shoulderY + shoulderOffsetY)
      ..lineTo(cx + hipW, hipY + hipOffset)
      ..lineTo(cx - hipW, hipY - hipOffset)
      ..close();
    canvas.drawPath(torsoPath, paint);
    canvas.drawPath(torsoPath, linePaint);

    // 왼팔
    final lShoulderPos = Offset(cx - shoulderW, shoulderY - shoulderOffsetY);
    final lElbowPos = Offset(cx - shoulderW - size.width * 0.08, elbowY);
    final lWristPos = Offset(cx - shoulderW - size.width * 0.06, wristY);
    _drawLimb(canvas, lShoulderPos, lElbowPos, limbWidth, paint, linePaint);
    _drawLimb(canvas, lElbowPos, lWristPos, limbWidth * 0.85, paint, linePaint);

    // 오른팔
    final rShoulderPos = Offset(cx + shoulderW, shoulderY + shoulderOffsetY);
    final rElbowPos = Offset(cx + shoulderW + size.width * 0.08, elbowY);
    final rWristPos = Offset(cx + shoulderW + size.width * 0.06, wristY);
    _drawLimb(canvas, rShoulderPos, rElbowPos, limbWidth, paint, linePaint);
    _drawLimb(canvas, rElbowPos, rWristPos, limbWidth * 0.85, paint, linePaint);

    // 왼쪽 다리
    final lHipPos = Offset(cx - hipW, hipY - hipOffset);
    final lKneePos = Offset(cx - hipW * 0.8, kneeY);
    final lAnklePos = Offset(cx - hipW * 0.7, ankleY);
    _drawLimb(canvas, lHipPos, lKneePos, limbWidth * 1.2, paint, linePaint);
    _drawLimb(canvas, lKneePos, lAnklePos, limbWidth, paint, linePaint);

    // 오른쪽 다리
    final rHipPos = Offset(cx + hipW, hipY + hipOffset);
    final rKneePos = Offset(cx + hipW * 0.8, kneeY);
    final rAnklePos = Offset(cx + hipW * 0.7, ankleY);
    _drawLimb(canvas, rHipPos, rKneePos, limbWidth * 1.2, paint, linePaint);
    _drawLimb(canvas, rKneePos, rAnklePos, limbWidth, paint, linePaint);

    // 관절 포인트
    final joints = [lShoulderPos, rShoulderPos, lElbowPos, rElbowPos,
        lHipPos, rHipPos, lKneePos, rKneePos, lAnklePos, rAnklePos];
    for (final j in joints) {
      canvas.drawCircle(j, 4, jointPaint);
    }
  }

  void _drawLimb(Canvas canvas, Offset start, Offset end, double width,
      Paint fillPaint, Paint strokePaint) {
    // 팔다리를 둥근 캡슐 형태의 두꺼운 선으로 표현
    final thickLinePaint = Paint()
      ..color = fillPaint.color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, thickLinePaint);
    canvas.drawLine(start, end, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
