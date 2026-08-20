import '../assets/body_assets.dart';
import '../course_generator/models/fatigue_entry.dart';
import '../course_generator/openai_client.dart';
import '../models/posture_result_model.dart';
import 'database_helper.dart';

/// 자세 측정 결과를 분석하여 근막이완이 필요한 부위를 추천하는 서비스.
///
/// [PostureResultModel]을 입력받아 OpenAI LLM을 통해
/// 풀어줘야 할 부위를 [FatigueEntry] 리스트로 반환한다.
/// 결과는 [CourseRequest]에 직접 연결할 수 있는 형태이다.
///
/// ```dart
/// final service = PostureToReleaseService();
/// final entries = await service.recommend(postureResult);
/// // entries를 CourseRequest.fatigueEntries에 바로 사용
/// ```
class PostureToReleaseService {
  PostureToReleaseService({
    OpenAiClient? openAiClient,
    DatabaseHelper? databaseHelper,
  })  : _openAiClient = openAiClient ?? OpenAiClient(),
        _databaseHelper = databaseHelper ?? DatabaseHelper();

  final OpenAiClient _openAiClient;
  final DatabaseHelper _databaseHelper;

  /// 유효한 (BodyFace, BodyPart) 조합 집합.
  /// front 전용: chest, abdomen, pelvis, shin, sole
  /// back 전용: upperBack, waist, hip, calf, heel
  /// 공용: neck, shoulder, arm, thigh
  static const Set<(BodyFace, BodyPart)> validCombinations = {
    // 전면
    (BodyFace.front, BodyPart.neck),
    (BodyFace.front, BodyPart.shoulder),
    (BodyFace.front, BodyPart.chest),
    (BodyFace.front, BodyPart.arm),
    (BodyFace.front, BodyPart.abdomen),
    (BodyFace.front, BodyPart.pelvis),
    (BodyFace.front, BodyPart.thigh),
    (BodyFace.front, BodyPart.shin),
    (BodyFace.front, BodyPart.sole),
    // 후면
    (BodyFace.back, BodyPart.neck),
    (BodyFace.back, BodyPart.shoulder),
    (BodyFace.back, BodyPart.arm),
    (BodyFace.back, BodyPart.upperBack),
    (BodyFace.back, BodyPart.waist),
    (BodyFace.back, BodyPart.hip),
    (BodyFace.back, BodyPart.thigh),
    (BodyFace.back, BodyPart.calf),
    (BodyFace.back, BodyPart.heel),
  };

  // ==================== PUBLIC API ====================

  /// 자세 측정 결과를 분석하여 이완이 필요한 부위를 추천한다.
  ///
  /// OpenAI LLM을 호출하여 자세 문제에 대응하는 부위와 심각도를 결정한다.
  /// AI 호출 실패 시 규칙 기반 fallback 매핑을 사용한다.
  Future<List<FatigueEntry>> recommend(PostureResultModel result) async {
    if (result.issues.isEmpty) return [];

    try {
      final responseJson = await _openAiClient.chatCompletion(
        systemPrompt: _buildSystemPrompt(),
        userPrompt: _buildUserPrompt(result),
        jsonSchema: _buildResponseSchema(),
      );
      return _parseResponse(responseJson);
    } catch (_) {
      // AI 호출 실패 시 규칙 기반 fallback
      return _fallbackRecommend(result);
    }
  }

  /// DB에서 최신 측정 결과를 가져와 추천한다.
  ///
  /// 측정 결과가 없으면 빈 리스트를 반환한다.
  Future<List<FatigueEntry>> recommendFromLatest(int userId) async {
    final result = await _databaseHelper.getLatestPostureResult(userId);
    if (result == null) return [];
    return recommend(result);
  }

  /// 리소스 정리.
  void dispose() {
    _openAiClient.dispose();
  }

  // ==================== PROMPT BUILDING ====================

  String _buildSystemPrompt() {
    return '당신은 근막이완(Self-Myofascial Release) 전문 운동처방사입니다.\n'
        '사용자의 자세 분석 결과를 보고, 근막이완으로 풀어줘야 할 부위를 추천합니다.\n'
        '\n'
        '## 부위 체계\n'
        '\n'
        '각 부위는 face(앞/뒤)와 part(구역)의 조합으로 표현됩니다.\n'
        '\n'
        '### 유효한 조합\n'
        '- front 전용 part: chest, abdomen, pelvis, shin, sole\n'
        '- back 전용 part: upperBack, waist, hip, calf, heel\n'
        '- 공용 part (front/back 모두 가능): neck, shoulder, arm, thigh\n'
        '\n'
        '## 추천 규칙\n'
        '\n'
        '1. 자세 문제의 원인이 되는 근육(단축/긴장된 근육)을 이완 대상으로 선택한다.\n'
        '2. 직접적 원인 부위뿐 아니라, 연쇄적으로 영향받는 부위도 포함한다.\n'
        '3. level(1~10)은 해당 부위의 이완 필요 정도이다:\n'
        '   - 9~10: 매우 심각, 즉시 이완 필요\n'
        '   - 7~8: 심각, 우선 이완 권장\n'
        '   - 5~6: 보통, 이완 필요\n'
        '   - 3~4: 경미, 보조 이완 권장\n'
        '   - 1~2: 미약, 예방 차원 이완\n'
        '4. 자세 점수(score)가 낮을수록 전반적으로 높은 level을 부여한다.\n'
        '5. 최소 2개, 최대 6개의 부위를 추천한다.\n'
        '\n'
        '## 자세 문제 → 이완 부위 참고 가이드\n'
        '\n'
        '- 거북목/머리 전방 이동: back-neck, back-shoulder, front-chest\n'
        '- 어깨 높이 차이: 높은 쪽 back-shoulder, back-neck\n'
        '- 어깨 전방활주(둥근 어깨): front-chest, back-shoulder, back-upperBack\n'
        '- 골반 기울기: front-pelvis, back-hip, back-waist\n'
        '- 몸통 기울기: back-waist, front-abdomen\n'
        '- 머리 좌우 편위: back-neck, front-neck\n'
        '- 무릎 비대칭/과신전: front-thigh, back-thigh, back-calf\n'
        '\n'
        '이 가이드는 참고용이며, 전문 지식을 바탕으로 종합적으로 판단하세요.\n'
        '\n'
        '## 응답 형식\n'
        '\n'
        '반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트는 포함하지 마세요.';
  }

  String _buildUserPrompt(PostureResultModel result) {
    final buffer = StringBuffer();

    buffer.writeln('## 자세 측정 결과');
    buffer.writeln();
    buffer.writeln('### 자세 점수: ${result.score}/100');
    buffer.writeln();

    buffer.writeln('### 감지된 문제');
    if (result.issues.isEmpty) {
      buffer.writeln('- 감지된 문제 없음');
    } else {
      for (final issue in result.issues) {
        buffer.writeln('- $issue');
      }
    }
    buffer.writeln();

    buffer.writeln('### 관절 각도 데이터');
    if (result.angles.isEmpty) {
      buffer.writeln('- 데이터 없음');
    } else {
      for (final entry in result.angles.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value.toStringAsFixed(1)}');
      }
    }
    buffer.writeln();

    if (result.summary != null && result.summary!.isNotEmpty) {
      buffer.writeln('### 종합 평가');
      buffer.writeln(result.summary);
      buffer.writeln();
    }

    buffer.writeln('## 지시');
    buffer.writeln();
    buffer.writeln('위 자세 분석 결과를 바탕으로, 근막이완이 필요한 부위를 추천해주세요.');
    buffer.writeln('각 부위의 face와 part는 반드시 유효한 조합이어야 합니다.');

    return buffer.toString();
  }

  // ==================== RESPONSE SCHEMA ====================

  Map<String, dynamic> _buildResponseSchema() {
    return {
      'name': 'release_recommendation',
      'strict': true,
      'schema': {
        'type': 'object',
        'properties': {
          'recommendations': {
            'type': 'array',
            'description': '이완이 필요한 부위 목록 (2~6개)',
            'items': {
              'type': 'object',
              'properties': {
                'face': {
                  'type': 'string',
                  'description': '앞/뒤 (front 또는 back)',
                  'enum': ['front', 'back'],
                },
                'part': {
                  'type': 'string',
                  'description': '부위 구역',
                  'enum': [
                    'neck',
                    'shoulder',
                    'chest',
                    'arm',
                    'abdomen',
                    'pelvis',
                    'thigh',
                    'shin',
                    'sole',
                    'upperBack',
                    'waist',
                    'hip',
                    'calf',
                    'heel',
                  ],
                },
                'level': {
                  'type': 'integer',
                  'description': '이완 필요 정도 (1~10, 10이 가장 심각)',
                },
                'reason': {
                  'type': 'string',
                  'description': '이 부위를 추천하는 이유 (한국어, 1문장)',
                },
              },
              'required': ['face', 'part', 'level', 'reason'],
              'additionalProperties': false,
            },
          },
        },
        'required': ['recommendations'],
        'additionalProperties': false,
      },
    };
  }

  // ==================== RESPONSE PARSING ====================

  List<FatigueEntry> _parseResponse(Map<String, dynamic> json) {
    final rawList = json['recommendations'] as List<dynamic>? ?? [];
    final entries = <FatigueEntry>[];

    for (final raw in rawList) {
      final map = raw as Map<String, dynamic>;
      final faceStr = map['face'] as String?;
      final partStr = map['part'] as String?;
      final level = map['level'] as int? ?? 3;

      if (faceStr == null || partStr == null) continue;

      final face = _parseFace(faceStr);
      final part = _parsePart(partStr);
      if (face == null || part == null) continue;

      // 유효하지 않은 조합은 건너뜀
      if (!validCombinations.contains((face, part))) continue;

      entries.add(FatigueEntry(
        face: face,
        part: part,
        level: level.clamp(1, 10),
      ));
    }

    return entries;
  }

  BodyFace? _parseFace(String value) {
    switch (value) {
      case 'front':
        return BodyFace.front;
      case 'back':
        return BodyFace.back;
      default:
        return null;
    }
  }

  BodyPart? _parsePart(String value) {
    for (final part in BodyPart.values) {
      if (part.name == value) return part;
    }
    return null;
  }

  // ==================== FALLBACK (규칙 기반) ====================

  /// AI 호출 실패 시 사용하는 규칙 기반 매핑.
  /// 자세 문제(issue) → 이완 부위 매핑 테이블을 사용한다.
  List<FatigueEntry> _fallbackRecommend(PostureResultModel result) {
    final entries = <(BodyFace, BodyPart, int)>{};

    for (final issue in result.issues) {
      final mappings = _issueMappings[issue];
      if (mappings == null) continue;
      for (final m in mappings) {
        entries.add(m);
      }
    }

    // score 기반 level 보정: 점수가 낮을수록 level을 올린다
    final scoreBoost = result.score < 50
        ? 2
        : result.score < 70
            ? 0
            : -2;

    return entries
        .map((e) => FatigueEntry(
              face: e.$1,
              part: e.$2,
              level: (e.$3 + scoreBoost).clamp(1, 10),
            ))
        .toList();
  }

  /// issue 문자열 → (face, part, baseLevel) 매핑 테이블.
  static const Map<String, List<(BodyFace, BodyPart, int)>> _issueMappings = {
    '거북목': [
      (BodyFace.back, BodyPart.neck, 8),
      (BodyFace.back, BodyPart.shoulder, 6),
      (BodyFace.front, BodyPart.chest, 6),
    ],
    '머리 전방 이동': [
      (BodyFace.back, BodyPart.neck, 8),
      (BodyFace.back, BodyPart.shoulder, 6),
    ],
    '어깨 높이 차이': [
      (BodyFace.back, BodyPart.shoulder, 8),
      (BodyFace.back, BodyPart.neck, 6),
    ],
    '어깨 전방활주': [
      (BodyFace.front, BodyPart.chest, 8),
      (BodyFace.back, BodyPart.shoulder, 8),
      (BodyFace.back, BodyPart.upperBack, 6),
    ],
    '골반 기울기': [
      (BodyFace.front, BodyPart.pelvis, 8),
      (BodyFace.back, BodyPart.hip, 8),
      (BodyFace.back, BodyPart.waist, 6),
    ],
    '몸통 기울기': [
      (BodyFace.back, BodyPart.waist, 8),
      (BodyFace.front, BodyPart.abdomen, 6),
    ],
    '머리 좌우 편위': [
      (BodyFace.back, BodyPart.neck, 8),
      (BodyFace.front, BodyPart.neck, 6),
    ],
    '무릎 비대칭': [
      (BodyFace.front, BodyPart.thigh, 8),
      (BodyFace.back, BodyPart.thigh, 6),
    ],
    '무릎 과신전': [
      (BodyFace.front, BodyPart.thigh, 8),
      (BodyFace.back, BodyPart.thigh, 6),
      (BodyFace.back, BodyPart.calf, 6),
    ],
  };
}
