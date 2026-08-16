import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// 포즈 분석 서비스 - ML Kit에서 감지한 포즈 데이터를 분석
class PoseAnalyzer {
  PoseAnalyzer._();

  /// 두 점 사이 각도 계산
  static double _calculateAngle(
    PoseLandmark first,
    PoseLandmark mid,
    PoseLandmark end,
  ) {
    final radians = atan2(end.y - mid.y, end.x - mid.x) -
        atan2(first.y - mid.y, first.x - mid.x);
    var angle = radians * 180 / pi;
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  /// 포즈에서 주요 관절 각도 추출
  static Map<String, double> extractAngles(Pose pose) {
    final landmarks = pose.landmarks;
    final angles = <String, double>{};

    // 왼쪽 어깨 각도
    if (_has(landmarks, [PoseLandmarkType.leftElbow, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip])) {
      angles['left_shoulder'] = _calculateAngle(
        landmarks[PoseLandmarkType.leftElbow]!,
        landmarks[PoseLandmarkType.leftShoulder]!,
        landmarks[PoseLandmarkType.leftHip]!,
      );
    }

    // 오른쪽 어깨 각도
    if (_has(landmarks, [PoseLandmarkType.rightElbow, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip])) {
      angles['right_shoulder'] = _calculateAngle(
        landmarks[PoseLandmarkType.rightElbow]!,
        landmarks[PoseLandmarkType.rightShoulder]!,
        landmarks[PoseLandmarkType.rightHip]!,
      );
    }

    // 왼쪽 고관절
    if (_has(landmarks, [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee])) {
      angles['left_hip'] = _calculateAngle(
        landmarks[PoseLandmarkType.leftShoulder]!,
        landmarks[PoseLandmarkType.leftHip]!,
        landmarks[PoseLandmarkType.leftKnee]!,
      );
    }

    // 오른쪽 고관절
    if (_has(landmarks, [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee])) {
      angles['right_hip'] = _calculateAngle(
        landmarks[PoseLandmarkType.rightShoulder]!,
        landmarks[PoseLandmarkType.rightHip]!,
        landmarks[PoseLandmarkType.rightKnee]!,
      );
    }

    // 왼쪽 무릎
    if (_has(landmarks, [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle])) {
      angles['left_knee'] = _calculateAngle(
        landmarks[PoseLandmarkType.leftHip]!,
        landmarks[PoseLandmarkType.leftKnee]!,
        landmarks[PoseLandmarkType.leftAnkle]!,
      );
    }

    // 오른쪽 무릎
    if (_has(landmarks, [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle])) {
      angles['right_knee'] = _calculateAngle(
        landmarks[PoseLandmarkType.rightHip]!,
        landmarks[PoseLandmarkType.rightKnee]!,
        landmarks[PoseLandmarkType.rightAnkle]!,
      );
    }

    // 어깨 높이 차이
    if (_has(landmarks, [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder])) {
      final leftY = landmarks[PoseLandmarkType.leftShoulder]!.y;
      final rightY = landmarks[PoseLandmarkType.rightShoulder]!.y;
      angles['shoulder_height_diff'] = leftY - rightY;
    }

    // 골반 높이 차이
    if (_has(landmarks, [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip])) {
      final leftY = landmarks[PoseLandmarkType.leftHip]!.y;
      final rightY = landmarks[PoseLandmarkType.rightHip]!.y;
      angles['hip_height_diff'] = leftY - rightY;
    }

    // 어깨-골반 수평 정렬 (몸통 기울기)
    if (_has(landmarks, [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip])) {
      final shoulderMidX = (landmarks[PoseLandmarkType.leftShoulder]!.x + landmarks[PoseLandmarkType.rightShoulder]!.x) / 2;
      final hipMidX = (landmarks[PoseLandmarkType.leftHip]!.x + landmarks[PoseLandmarkType.rightHip]!.x) / 2;
      final shoulderMidY = (landmarks[PoseLandmarkType.leftShoulder]!.y + landmarks[PoseLandmarkType.rightShoulder]!.y) / 2;
      final hipMidY = (landmarks[PoseLandmarkType.leftHip]!.y + landmarks[PoseLandmarkType.rightHip]!.y) / 2;
      final bodyHeight = (hipMidY - shoulderMidY).abs();
      if (bodyHeight > 0) {
        angles['torso_tilt'] = (shoulderMidX - hipMidX) / bodyHeight;
      }
    }

    // 머리 좌우 편차 (정면 기준)
    if (_has(landmarks, [PoseLandmarkType.nose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder])) {
      final nosX = landmarks[PoseLandmarkType.nose]!.x;
      final shoulderMidX = (landmarks[PoseLandmarkType.leftShoulder]!.x + landmarks[PoseLandmarkType.rightShoulder]!.x) / 2;
      final shoulderWidth = (landmarks[PoseLandmarkType.leftShoulder]!.x - landmarks[PoseLandmarkType.rightShoulder]!.x).abs();
      if (shoulderWidth > 0) {
        angles['head_lateral_shift'] = (nosX - shoulderMidX) / shoulderWidth;
      }
    }

    return angles;
  }

  /// 측면 촬영 전용 각도 추출
  static Map<String, double> extractSideAngles(Pose pose) {
    final landmarks = pose.landmarks;
    final angles = <String, double>{};

    // 거북목 각도 (귀-어깨 수직선 대비 전방 이동)
    // 측면에서는 nose를 귀 대용으로 사용
    if (_has(landmarks, [PoseLandmarkType.nose, PoseLandmarkType.leftShoulder]) ||
        _has(landmarks, [PoseLandmarkType.nose, PoseLandmarkType.rightShoulder])) {
      final nose = landmarks[PoseLandmarkType.nose]!;
      final shoulder = landmarks[PoseLandmarkType.leftShoulder] ?? landmarks[PoseLandmarkType.rightShoulder]!;
      // 머리 전방 이동량 (어깨 대비 코가 얼마나 앞에 있는지)
      final forwardShift = nose.x - shoulder.x;
      final verticalDist = (shoulder.y - nose.y).abs();
      if (verticalDist > 0) {
        angles['forward_head'] = forwardShift / verticalDist;
      }

      // 거북목 각도 (도)
      final neckAngle = atan2((nose.x - shoulder.x).abs(), (shoulder.y - nose.y).abs()) * 180 / pi;
      angles['neck_angle'] = neckAngle;
    }

    // 어깨 전방 이동 (둥근 어깨)
    if (_has(landmarks, [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip]) ||
        _has(landmarks, [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip])) {
      final shoulder = landmarks[PoseLandmarkType.leftShoulder] ?? landmarks[PoseLandmarkType.rightShoulder]!;
      final hip = landmarks[PoseLandmarkType.leftHip] ?? landmarks[PoseLandmarkType.rightHip]!;
      final bodyHeight = (hip.y - shoulder.y).abs();
      if (bodyHeight > 0) {
        angles['shoulder_forward'] = (shoulder.x - hip.x) / bodyHeight;
      }
    }

    // 몸통 전후 기울기
    if (_has(landmarks, [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee]) ||
        _has(landmarks, [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee])) {
      final shoulder = landmarks[PoseLandmarkType.leftShoulder] ?? landmarks[PoseLandmarkType.rightShoulder]!;
      final hip = landmarks[PoseLandmarkType.leftHip] ?? landmarks[PoseLandmarkType.rightHip]!;
      final knee = landmarks[PoseLandmarkType.leftKnee] ?? landmarks[PoseLandmarkType.rightKnee]!;

      angles['torso_forward_tilt'] = _calculateAngle(shoulder, hip, knee);
    }

    // 무릎 정렬 (과신전 여부)
    if (_has(landmarks, [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle]) ||
        _has(landmarks, [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle])) {
      final hip = landmarks[PoseLandmarkType.leftHip] ?? landmarks[PoseLandmarkType.rightHip]!;
      final knee = landmarks[PoseLandmarkType.leftKnee] ?? landmarks[PoseLandmarkType.rightKnee]!;
      final ankle = landmarks[PoseLandmarkType.leftAnkle] ?? landmarks[PoseLandmarkType.rightAnkle]!;
      angles['knee_alignment'] = _calculateAngle(hip, knee, ankle);
    }

    return angles;
  }

  /// 정면+측면 종합 문제 감지
  static List<String> detectIssuesCombined({
    required Map<String, double> frontAngles,
    required Map<String, double> sideAngles,
  }) {
    final issues = <String>[];

    // --- 정면 분석 ---
    // 어깨 높이 차이
    final shoulderDiff = frontAngles['shoulder_height_diff']?.abs() ?? 0;
    if (shoulderDiff > 12) issues.add('어깨 높이 차이');

    // 골반 기울기
    final hipDiff = frontAngles['hip_height_diff']?.abs() ?? 0;
    if (hipDiff > 8) issues.add('골반 기울기');

    // 몸통 기울기
    final torsoTilt = frontAngles['torso_tilt']?.abs() ?? 0;
    if (torsoTilt > 0.05) issues.add('몸통 기울기');

    // 머리 좌우 편위
    final headShift = frontAngles['head_lateral_shift']?.abs() ?? 0;
    if (headShift > 0.08) issues.add('머리 좌우 편위');

    // 무릎 정렬 (좌우 차이)
    final leftKnee = frontAngles['left_knee'] ?? 180;
    final rightKnee = frontAngles['right_knee'] ?? 180;
    if ((leftKnee - rightKnee).abs() > 8) issues.add('무릎 비대칭');

    // --- 측면 분석 ---
    // 거북목
    final neckAngle = sideAngles['neck_angle'] ?? 0;
    if (neckAngle > 35) issues.add('거북목');

    // 머리 전방 이동
    final forwardHead = sideAngles['forward_head']?.abs() ?? 0;
    if (forwardHead > 0.2) {
      if (!issues.contains('거북목')) issues.add('머리 전방 이동');
    }

    // 어깨 전방 활주 (둥근 어깨)
    final shoulderForward = sideAngles['shoulder_forward'] ?? 0;
    if (shoulderForward.abs() > 0.1) issues.add('어깨 전방활주');

    // 무릎 과신전
    final kneeAlign = sideAngles['knee_alignment'] ?? 180;
    if (kneeAlign > 185) issues.add('무릎 과신전');

    return issues;
  }

  /// 자세 점수 계산 (100점 만점)
  static int calculatePostureScore({
    required Map<String, double> frontAngles,
    required Map<String, double> sideAngles,
  }) {
    double score = 100;

    // 정면 감점
    final shoulderDiff = frontAngles['shoulder_height_diff']?.abs() ?? 0;
    score -= (shoulderDiff / 5).clamp(0, 15);

    final hipDiff = frontAngles['hip_height_diff']?.abs() ?? 0;
    score -= (hipDiff / 4).clamp(0, 10);

    final torsoTilt = frontAngles['torso_tilt']?.abs() ?? 0;
    score -= (torsoTilt * 100).clamp(0, 10);

    final headShift = frontAngles['head_lateral_shift']?.abs() ?? 0;
    score -= (headShift * 50).clamp(0, 8);

    final leftKnee = frontAngles['left_knee'] ?? 180;
    final rightKnee = frontAngles['right_knee'] ?? 180;
    score -= ((leftKnee - rightKnee).abs() / 3).clamp(0, 8);

    // 측면 감점
    final neckAngle = sideAngles['neck_angle'] ?? 0;
    if (neckAngle > 25) score -= ((neckAngle - 25) * 0.8).clamp(0, 20);

    final shoulderForward = sideAngles['shoulder_forward']?.abs() ?? 0;
    score -= (shoulderForward * 60).clamp(0, 12);

    final kneeAlign = sideAngles['knee_alignment'] ?? 180;
    if (kneeAlign > 180) score -= ((kneeAlign - 180) * 2).clamp(0, 10);

    return score.round().clamp(0, 100);
  }

  /// 상세 요약 생성
  static String generateDetailedSummary(List<String> issues, int score) {
    if (issues.isEmpty) {
      return 'AI 기반 자세 점검 결과 매우 양호한 상태입니다. 의료적 진단을 대신하지 않습니다.';
    }
    final issueText = issues.join(', ');
    return 'AI 기반 자세 점검 결과 $issueText 항목에서 주의가 필요합니다. 의료적 진단을 대신하지 않습니다.';
  }

  // 이전 호환용
  static List<String> detectIssues(Map<String, double> angles) {
    return detectIssuesCombined(frontAngles: angles, sideAngles: {});
  }

  static String generateSummary(List<String> issues) {
    return generateDetailedSummary(issues, 100);
  }

  static bool _has(Map<PoseLandmarkType, PoseLandmark> landmarks, List<PoseLandmarkType> types) {
    return types.every((t) => landmarks.containsKey(t));
  }
}
