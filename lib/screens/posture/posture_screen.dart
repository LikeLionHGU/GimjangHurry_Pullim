import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_typography.dart';
import '../../models/posture_result_model.dart';
import '../../providers/app_provider.dart';
import '../../services/database_helper.dart';
import '../../services/pose_analyzer.dart';
import 'posture_result_screen.dart';

/// 촬영 단계
enum CapturePhase { front, side }

class PostureScreen extends StatefulWidget {
  const PostureScreen({super.key});

  @override
  State<PostureScreen> createState() => _PostureScreenState();
}

class _PostureScreenState extends State<PostureScreen> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  FlutterTts? _tts;

  bool _isCameraReady = false;
  bool _isDetecting = false;
  Pose? _detectedPose;
  bool _isPersonInFrame = false; // 사람이 중앙 프레임 안에 있는지

  // 촬영 단계
  CapturePhase _currentPhase = CapturePhase.front;
  String? _frontImagePath;
  String? _sideImagePath;
  Map<String, double>? _frontAngles;
  Map<String, double>? _sideAngles;

  // 촬영 완료 플래그
  bool _frontCaptured = false;
  bool _sideCaptured = false;

  // 전환 대기 (정면→측면 전환 후 안정화 대기)
  bool _waitingForPhaseTransition = false;

  // 자동 촬영 관련
  int _stableFrameCount = 0;
  static const int _requiredStableFrames = 15;
  bool _isCapturing = false;
  bool _countingDown = false;
  int _countdown = 3;

  // 프레임 영역 (화면 비율 기준 - build에서 계산)
  Rect _guideFrameRect = Rect.zero;

  // 음성 안내 상태
  String _lastSpokenMessage = '';
  DateTime _lastSpeakTime = DateTime.now();
  static const Duration _speakCooldown = Duration(seconds: 4);

  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeCamera();
  }

  Future<void> _initializeTts() async {
    _tts = FlutterTts();
    await _tts!.setLanguage('ko-KR');
    await _tts!.setSpeechRate(0.5);
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);

    // TTS 완료 콜백
    _tts!.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _tts!.setCancelHandler(() {
      _isSpeaking = false;
    });
    _tts!.setErrorHandler((msg) {
      _isSpeaking = false;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    _speak('정면 촬영을 시작합니다. 화면 중앙의 프레임 안에 전신이 들어오도록 서 주세요.');
  }

  bool _isSpeaking = false;
  DateTime _speakEndTime = DateTime.now(); // TTS 예상 종료 시간

  Future<void> _speak(String message) async {
    // 현재 말하는 중이면 무시 (타임아웃 기반 안전장치 포함)
    final now = DateTime.now();
    if (_isSpeaking && now.isBefore(_speakEndTime)) return;

    // 같은 메시지 쿨다운
    if (message == _lastSpokenMessage &&
        now.difference(_lastSpeakTime) < _speakCooldown) {
      return;
    }

    _lastSpokenMessage = message;
    _lastSpeakTime = now;
    _isSpeaking = true;
    // 대략 글자수 기반으로 음성 종료 시간 예측 (안전장치)
    final estimatedDuration = Duration(milliseconds: 600 + message.length * 120);
    _speakEndTime = now.add(estimatedDuration);

    await _tts?.speak(message);
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() => _statusMessage = '카메라 권한이 필요합니다.');
        _speak('카메라 권한을 허용해주세요.');
      }
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) setState(() => _statusMessage = '카메라를 찾을 수 없습니다.');
      return;
    }

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );

    if (mounted) {
      setState(() {
        _isCameraReady = true;
        _statusMessage = '프레임 안에 전신이 보이도록 서 주세요';
      });
      _cameraController!.startImageStream(_processFrame);
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isDetecting || _isCapturing || _waitingForPhaseTransition) return;
    // 이미 촬영 완료된 단계면 무시
    if (_currentPhase == CapturePhase.front && _frontCaptured) return;
    if (_currentPhase == CapturePhase.side && _sideCaptured) return;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);

      if (!mounted) {
        _isDetecting = false;
        return;
      }

      if (poses.isNotEmpty) {
        final pose = poses.first;
        final hasFullBody = _checkFullBodyVisible(pose);
        final inFrame = hasFullBody && _checkPersonInGuideFrame(pose);

        setState(() {
          _detectedPose = pose;
          _isPersonInFrame = inFrame;
        });

        if (inFrame) {
          _stableFrameCount++;

          if (_stableFrameCount == 1) {
            setState(() => _statusMessage = '좋습니다! 자세를 유지해주세요');
          }

          if (_stableFrameCount >= _requiredStableFrames && !_countingDown) {
            _startAutoCapture();
          }
        } else {
          _stableFrameCount = 0;
          if (!_countingDown) {
            final guidance = _getFrameGuidance(pose, hasFullBody);
            setState(() => _statusMessage = guidance);
            _speak(guidance);
          }
        }
      } else {
        setState(() {
          _detectedPose = null;
          _isPersonInFrame = false;
          _statusMessage = '사람이 감지되지 않습니다. 프레임 안으로 들어와 주세요';
        });
        _stableFrameCount = 0;
        if (!_countingDown) {
          _speak('화면 중앙 프레임 안으로 들어와 주세요.');
        }
      }
    } catch (_) {}

    _isDetecting = false;
  }

  /// 사람이 중앙 가이드 프레임 안에 있는지 확인
  bool _checkPersonInGuideFrame(Pose pose) {
    if (_guideFrameRect == Rect.zero) return false;

    final cameraSize = _cameraController?.value.previewSize;
    if (cameraSize == null) return false;

    // 카메라 이미지 → 화면 좌표 변환을 위한 비율
    // previewSize는 (height, width) 형태일 수 있으므로 보정
    final imgW = cameraSize.height; // 회전 고려
    final imgH = cameraSize.width;

    // 주요 랜드마크들의 화면 좌표를 프레임 영역과 비교
    final checkPoints = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    int insideCount = 0;
    int totalCount = 0;

    for (final type in checkPoints) {
      final lm = pose.landmarks[type];
      if (lm == null) continue;
      totalCount++;

      // 카메라 좌표 → 프레임 영역의 부모(카메라 프리뷰) 좌표로 변환
      // _guideFrameRect는 카메라 프리뷰 영역 내의 상대 좌표
      final screenX = lm.x / imgW;
      final screenY = lm.y / imgH;

      // 프레임 영역도 0~1 비율로 변환해서 비교
      if (screenX >= _guideFrameRect.left &&
          screenX <= _guideFrameRect.right &&
          screenY >= _guideFrameRect.top &&
          screenY <= _guideFrameRect.bottom) {
        insideCount++;
      }
    }

    // 70% 이상의 포인트가 프레임 안에 있으면 OK
    return totalCount > 0 && (insideCount / totalCount) >= 0.7;
  }

  /// 프레임 기준 구체적 가이드 메시지
  String _getFrameGuidance(Pose pose, bool hasFullBody) {
    if (!hasFullBody) {
      // 어느 부분이 안 보이는지 판단
      final landmarks = pose.landmarks;
      if (!landmarks.containsKey(PoseLandmarkType.nose)) {
        return '머리가 보이지 않습니다. 프레임 안에 머리부터 발까지 보이게 해주세요';
      }
      if (!landmarks.containsKey(PoseLandmarkType.leftAnkle) &&
          !landmarks.containsKey(PoseLandmarkType.rightAnkle)) {
        return '발이 보이지 않습니다. 뒤로 물러나 주세요';
      }
      return '전신이 보이도록 프레임 안에 서 주세요';
    }

    // 전신은 보이지만 프레임 밖에 있는 경우 - 방향 안내
    final cameraSize = _cameraController?.value.previewSize;
    if (cameraSize == null) return '프레임 중앙으로 이동해주세요';

    final imgW = cameraSize.height;
    final imgH = cameraSize.width;

    // 몸 중심점 계산
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];

    if (ls == null || rs == null || lh == null || rh == null) {
      return '프레임 중앙으로 이동해주세요';
    }

    final bodyCenterX = (ls.x + rs.x + lh.x + rh.x) / 4 / imgW;
    final bodyCenterY = (ls.y + rs.y + lh.y + rh.y) / 4 / imgH;

    final frameCenterX = (_guideFrameRect.left + _guideFrameRect.right) / 2;
    final frameCenterY = (_guideFrameRect.top + _guideFrameRect.bottom) / 2;

    final diffX = bodyCenterX - frameCenterX;
    final diffY = bodyCenterY - frameCenterY;

    // 좌우 안내
    if (diffX.abs() > 0.1) {
      if (diffX > 0) return '조금 왼쪽으로 이동해주세요';
      return '조금 오른쪽으로 이동해주세요';
    }

    // 상하 안내
    if (diffY.abs() > 0.1) {
      if (diffY > 0) return '카메라를 조금 위로 올려주세요';
      return '카메라를 조금 아래로 내려주세요';
    }

    // 너무 크거나 작은 경우
    final bodyWidth = ((rs.x - ls.x).abs()) / imgW;
    final frameWidth = _guideFrameRect.width;

    if (bodyWidth > frameWidth * 1.3) {
      return '조금 뒤로 물러나 주세요';
    }
    if (bodyWidth < frameWidth * 0.4) {
      return '조금 앞으로 다가와 주세요';
    }

    return '프레임 중앙으로 이동해주세요';
  }

  /// 자동 촬영 카운트다운
  Future<void> _startAutoCapture() async {
    if (_countingDown || _isCapturing) return;
    _countingDown = true; // 즉시 설정 (중복 진입 방지)

    setState(() => _statusMessage = '자세가 좋습니다. 촬영 준비 중...');
    _speak('자세가 좋습니다. 3초 후 촬영합니다.');

    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() {
        _countdown = i;
        _statusMessage = '$i초 후 촬영합니다';
      });
      await Future.delayed(const Duration(seconds: 1));

      // 카운트다운 중 프레임 벗어나면 취소
      if (!_isPersonInFrame) {
        _countingDown = false;
        _stableFrameCount = 0;
        setState(() => _statusMessage = '프레임에서 벗어났습니다. 다시 프레임 안에 서 주세요');
        _speak('프레임에서 벗어났습니다. 다시 프레임 안에 서 주세요.');
        return;
      }
    }

    // 촬영 실행
    if (mounted && !_isCapturing) {
      setState(() {
        _statusMessage = '촬영!';
        _countingDown = false; // 카운트다운 UI 즉시 제거
      });
      _speak('촬영합니다.');
      await _capturePhoto();
    } else {
      _countingDown = false;
    }
  }

  /// 사진 촬영
  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      // 이미지 스트림 중지 후 충분히 대기
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {
        // 이미 멈춰있을 수 있음
      }
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted || _cameraController == null) {
        _isCapturing = false;
        return;
      }

      final xFile = await _cameraController!.takePicture();
      final angles = _detectedPose != null
          ? (_currentPhase == CapturePhase.front
              ? PoseAnalyzer.extractAngles(_detectedPose!)
              : PoseAnalyzer.extractSideAngles(_detectedPose!))
          : <String, double>{};

      if (_currentPhase == CapturePhase.front) {
        _frontCaptured = true;
        setState(() {
          _frontImagePath = xFile.path;
          _frontAngles = angles;
          _currentPhase = CapturePhase.side;
          _stableFrameCount = 0;
          _isPersonInFrame = false;
          _detectedPose = null;
          _statusMessage = '정면 촬영 완료! 측면으로 돌아서 주세요';
        });

        _isCapturing = false;
        _speak('정면 촬영 완료. 이제 옆으로 돌아서 프레임 안에 서 주세요.');

        // 전환 대기
        _waitingForPhaseTransition = true;
        await Future.delayed(const Duration(seconds: 4));
        _waitingForPhaseTransition = false;
        _stableFrameCount = 0;

        if (mounted && _cameraController != null) {
          await _cameraController!.startImageStream(_processFrame);
        }
      } else {
        _sideCaptured = true;
        setState(() {
          _sideImagePath = xFile.path;
          _sideAngles = angles;
          _statusMessage = '측면 촬영 완료! 분석 중...';
        });

        _speak('촬영 완료. 자세를 분석합니다.');
        await Future.delayed(const Duration(seconds: 1));
        // _isCapturing은 _goToResult 안에서 화면 전환 후 해제 불필요 (화면 자체가 사라짐)
        await _goToResult();
        return; // 여기서 끝 (화면 전환됨)
      }
    } catch (e) {
      debugPrint('촬영 실패: $e');
      _isCapturing = false;

      // 재시도: 스트림 다시 시작
      await Future.delayed(const Duration(milliseconds: 500));
      _stableFrameCount = 0;
      _countingDown = false;
      if (mounted && _cameraController != null) {
        try {
          await _cameraController!.startImageStream(_processFrame);
        } catch (_) {}
      }
      _speak('다시 자세를 잡아주세요.');
    }
  }

  Future<void> _goToResult() async {
    try {
      final provider = context.read<AppProvider>();
      final userId = provider.currentUser?.userId ?? 1;
      final nav = Navigator.of(context);

      final combinedAngles = <String, double>{};
      if (_frontAngles != null) {
        _frontAngles!.forEach((k, v) => combinedAngles['front_$k'] = v);
      }
      if (_sideAngles != null) {
        _sideAngles!.forEach((k, v) => combinedAngles['side_$k'] = v);
      }

      final issues = PoseAnalyzer.detectIssuesCombined(
        frontAngles: _frontAngles ?? {},
        sideAngles: _sideAngles ?? {},
      );
      final score = PoseAnalyzer.calculatePostureScore(
        frontAngles: _frontAngles ?? {},
        sideAngles: _sideAngles ?? {},
      );
      final summary = PoseAnalyzer.generateDetailedSummary(issues, score);

      final result = PostureResultModel(
        userId: userId,
        angles: combinedAngles,
        issues: issues,
        summary: summary,
        score: score,
      );

      final db = DatabaseHelper();
      final resultId = await db.insertPostureResult(result);
      debugPrint('자세 측정 결과 저장 완료: id=$resultId, score=$score');

      if (mounted) {
        nav.pushReplacement(
          MaterialPageRoute(
            builder: (_) => PostureResultScreen(
              result: result,
              frontImagePath: _frontImagePath,
              sideImagePath: _sideImagePath,
              frontAngles: _frontAngles ?? {},
              sideAngles: _sideAngles ?? {},
              score: score,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('결과 화면 이동 실패: $e');
      _isCapturing = false;
      if (mounted) {
        setState(() => _statusMessage = '분석에 실패했습니다. 다시 시도해주세요.');
      }
    }
  }

  bool _checkFullBodyVisible(Pose pose) {
    if (_currentPhase == CapturePhase.front) {
      // 정면: 양쪽 다 보여야 함
      final required = [
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.rightKnee,
        PoseLandmarkType.leftAnkle,
        PoseLandmarkType.rightAnkle,
      ];
      return required.every((type) => pose.landmarks.containsKey(type));
    } else {
      // 측면: 한쪽만 보여도 됨 (어깨, 골반, 무릎, 발목 중 한쪽씩)
      final hasNose = pose.landmarks.containsKey(PoseLandmarkType.nose);
      final hasShoulder = pose.landmarks.containsKey(PoseLandmarkType.leftShoulder) ||
          pose.landmarks.containsKey(PoseLandmarkType.rightShoulder);
      final hasHip = pose.landmarks.containsKey(PoseLandmarkType.leftHip) ||
          pose.landmarks.containsKey(PoseLandmarkType.rightHip);
      final hasKnee = pose.landmarks.containsKey(PoseLandmarkType.leftKnee) ||
          pose.landmarks.containsKey(PoseLandmarkType.rightKnee);
      final hasAnkle = pose.landmarks.containsKey(PoseLandmarkType.leftAnkle) ||
          pose.landmarks.containsKey(PoseLandmarkType.rightAnkle);

      return hasNose && hasShoulder && hasHip && hasKnee && hasAnkle;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      final sensorOrientation = camera.sensorOrientation;

      InputImageRotation? rotation;
      if (sensorOrientation == 0) {
        rotation = InputImageRotation.rotation0deg;
      } else if (sensorOrientation == 90) {
        rotation = InputImageRotation.rotation90deg;
      } else if (sensorOrientation == 180) {
        rotation = InputImageRotation.rotation180deg;
      } else if (sensorOrientation == 270) {
        rotation = InputImageRotation.rotation270deg;
      }
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _tts?.stop();
    _cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.postureMeasure),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildPhaseIndicator(),
            Expanded(child: _buildCameraPreview()),
            _buildBottomStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PhaseChip(
            label: '정면',
            isActive: _currentPhase == CapturePhase.front,
            isDone: _frontImagePath != null,
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_ios,
              color: AppColors.textTertiary, size: 14),
          const SizedBox(width: 12),
          _PhaseChip(
            label: '측면',
            isActive: _currentPhase == CapturePhase.side,
            isDone: _sideImagePath != null,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraReady || _cameraController == null) {
      return Container(
        color: AppColors.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text('카메라를 준비하고 있습니다...',
                  style: AppTypography.r14.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 중앙 가이드 프레임 영역 계산 (화면 대비 비율)
        final frameWidth = constraints.maxWidth * 0.55;
        final frameHeight = constraints.maxHeight * 0.85;
        final frameLeft = (constraints.maxWidth - frameWidth) / 2;
        final frameTop = (constraints.maxHeight - frameHeight) / 2;

        // 프레임의 정규화된 비율 (0~1 범위) 저장
        _guideFrameRect = Rect.fromLTWH(
          frameLeft / constraints.maxWidth,
          frameTop / constraints.maxHeight,
          frameWidth / constraints.maxWidth,
          frameHeight / constraints.maxHeight,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // 카메라 프리뷰
            CameraPreview(_cameraController!),

            // 어두운 오버레이 + 중앙 프레임 구멍
            _buildFrameOverlay(constraints, frameLeft, frameTop, frameWidth, frameHeight),

            // 프레임 테두리
            Positioned(
              left: frameLeft,
              top: frameTop,
              child: _buildFrameBorder(frameWidth, frameHeight),
            ),

            // 포즈 실루엣 오버레이
            if (_detectedPose != null)
              CustomPaint(
                painter: _BodyOutlinePainter(
                  pose: _detectedPose!,
                  imageSize: Size(
                    _cameraController!.value.previewSize!.height,
                    _cameraController!.value.previewSize!.width,
                  ),
                  isInFrame: _isPersonInFrame,
                ),
              ),

            // 카운트다운
            if (_countingDown)
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.85),
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: AppTypography.b40.copyWith(
                        color: AppColors.background,
                        fontSize: 48,
                      ),
                    ),
                  ),
                ),
              ),

            // 하단 상태 메시지
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPersonInFrame ? Icons.check_circle : Icons.info_outline,
                      color: _isPersonInFrame ? AppColors.primary : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: AppTypography.r12.copyWith(
                          color: _isPersonInFrame ? AppColors.primary : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 중앙 프레임 외부를 어둡게 (뷰파인더 효과)
  Widget _buildFrameOverlay(BoxConstraints constraints, double frameLeft,
      double frameTop, double frameWidth, double frameHeight) {
    return CustomPaint(
      size: Size(constraints.maxWidth, constraints.maxHeight),
      painter: _ViewfinderOverlayPainter(
        frameRect: Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight),
      ),
    );
  }

  /// 중앙 프레임 테두리 (코너 강조)
  Widget _buildFrameBorder(double width, double height) {
    final borderColor = _isPersonInFrame
        ? AppColors.primary
        : AppColors.textTertiary.withValues(alpha: 0.7);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CornerBorderPainter(color: borderColor),
      ),
    );
  }

  Widget _buildBottomStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // 진행 바
          LinearProgressIndicator(
            value: _getProgress(),
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(
            _currentPhase == CapturePhase.front
                ? '1/2 정면 촬영 · 프레임 안에 서면 자동 촬영됩니다'
                : '2/2 측면 촬영 · 프레임 안에 서면 자동 촬영됩니다',
            style: AppTypography.r12.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  double _getProgress() {
    if (_frontImagePath != null && _sideImagePath != null) return 1.0;
    if (_frontImagePath != null) return 0.5;
    if (_stableFrameCount > 0) {
      return (_stableFrameCount / _requiredStableFrames).clamp(0.0, 0.45);
    }
    return 0.0;
  }
}

// ============ 위젯 ============

class _PhaseChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDone;

  const _PhaseChip({
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    if (isDone) {
      bgColor = AppColors.primary;
      textColor = AppColors.background;
    } else if (isActive) {
      bgColor = AppColors.surface;
      textColor = AppColors.primary;
    } else {
      bgColor = AppColors.surface;
      textColor = AppColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: AppColors.primary) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDone) ...[
            Icon(Icons.check, color: textColor, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.r12.copyWith(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ Painters ============

/// 뷰파인더 오버레이 - 프레임 외부를 반투명 어둡게
class _ViewfinderOverlayPainter extends CustomPainter {
  final Rect frameRect;

  _ViewfinderOverlayPainter({required this.frameRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.5);

    // 전체를 어둡게 칠한 뒤 프레임 영역만 투명하게 뚫기
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final framePath = Path()
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(16)));
    final overlayPath = Path()
      ..addRect(fullRect)
      ..addPath(framePath, Offset.zero);
    overlayPath.fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 코너 강조 테두리
class _CornerBorderPainter extends CustomPainter {
  final Color color;

  _CornerBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 30.0;
    const r = 16.0;

    // 좌상
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLen)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(cornerLen, 0),
      paint,
    );

    // 우상
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLen, 0)
        ..lineTo(size.width - r, 0)
        ..quadraticBezierTo(size.width, 0, size.width, r)
        ..lineTo(size.width, cornerLen),
      paint,
    );

    // 좌하
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLen)
        ..lineTo(0, size.height - r)
        ..quadraticBezierTo(0, size.height, r, size.height)
        ..lineTo(cornerLen, size.height),
      paint,
    );

    // 우하
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLen, size.height)
        ..lineTo(size.width - r, size.height)
        ..quadraticBezierTo(size.width, size.height, size.width, size.height - r)
        ..lineTo(size.width, size.height - cornerLen),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 사람 체형 윤곽선 (두꺼운 인체 형태)
class _BodyOutlinePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final bool isInFrame;

  _BodyOutlinePainter({
    required this.pose,
    required this.imageSize,
    this.isInFrame = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final color = isInFrame
        ? AppColors.primary.withValues(alpha: 0.8)
        : const Color(0xFFFF6B6B).withValues(alpha: 0.7);

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final limbPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final legPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 몸통
    final ls = _pt(PoseLandmarkType.leftShoulder, size);
    final rs = _pt(PoseLandmarkType.rightShoulder, size);
    final lh = _pt(PoseLandmarkType.leftHip, size);
    final rh = _pt(PoseLandmarkType.rightHip, size);

    if (ls != null && rs != null && lh != null && rh != null) {
      final path = Path()
        ..moveTo(ls.dx, ls.dy)
        ..lineTo(rs.dx, rs.dy)
        ..lineTo(rh.dx, rh.dy)
        ..lineTo(lh.dx, lh.dy)
        ..close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }

    // 머리
    final nose = _pt(PoseLandmarkType.nose, size);
    if (nose != null && ls != null && rs != null) {
      final midY = (ls.dy + rs.dy) / 2;
      final radius = ((midY - nose.dy).abs() * 0.5).clamp(12.0, 28.0);
      canvas.drawCircle(nose, radius, fillPaint);
      canvas.drawCircle(nose, radius, strokePaint);
    }

    // 팔
    _drawLimb(canvas, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, size, limbPaint);
    _drawLimb(canvas, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, size, limbPaint);
    _drawLimb(canvas, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, size, limbPaint);
    _drawLimb(canvas, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, size, limbPaint);

    // 다리
    _drawLimb(canvas, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, size, legPaint);
    _drawLimb(canvas, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, size, legPaint);
    _drawLimb(canvas, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, size, legPaint);
    _drawLimb(canvas, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, size, legPaint);

    // 관절
    final joints = [
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle,
    ];
    for (final type in joints) {
      final p = _pt(type, size);
      if (p != null) canvas.drawCircle(p, 5, jointPaint);
    }
  }

  void _drawLimb(Canvas canvas, PoseLandmarkType a, PoseLandmarkType b,
      Size size, Paint paint) {
    final pA = _pt(a, size);
    final pB = _pt(b, size);
    if (pA != null && pB != null) canvas.drawLine(pA, pB, paint);
  }

  Offset? _pt(PoseLandmarkType type, Size canvasSize) {
    final lm = pose.landmarks[type];
    if (lm == null) return null;
    return Offset(
      lm.x / imageSize.width * canvasSize.width,
      lm.y / imageSize.height * canvasSize.height,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
