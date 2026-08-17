import '../assets/body_assets.dart';
import '../assets/move_assets.dart';
import '../assets/tool_assets.dart';
import 'models/course_request.dart';

/// 필터된 후보 동작과 입력 조건을 OpenAI API 호출용 프롬프트로 변환한다.
class PromptBuilder {
  const PromptBuilder();

  /// 시스템 프롬프트를 생성한다.
  String buildSystemPrompt() {
    return '당신은 근막이완(Self-Myofascial Release) 전문 운동처방사입니다.\n'
        '사용자의 피로 부위, 보유 도구, 가용 시간을 고려해 최적의 근막이완 코스를 편성합니다.\n'
        '\n'
        '## 코스 편성 규칙\n'
        '\n'
        '1. **자세 전환 최소화**: 같은 자세(posture)의 동작을 연속 배치하여 자세 전환 횟수를 줄인다.\n'
        '2. **피로도 비례 시간 배분**: 피로도가 높은 부위에 더 많은 시간(더 많은 동작 또는 더 긴 duration)을 배분한다.\n'
        '3. **시간 범위 준수**: 각 동작의 duration은 해당 동작의 time.min ~ time.max 범위 내에서 배정한다.\n'
        '4. **총 시간 준수**: 모든 step의 duration 합이 가용 시간을 초과하지 않아야 한다. 가용 시간의 90~100%를 채우는 것이 이상적이다.\n'
        '5. **동작 선택 이유**: 각 동작을 선택한 이유를 한국어로 간결하게 설명한다 (1~2문장).\n'
        '6. **코스 이름**: 코스의 목적을 나타내는 짧고 직관적인 한국어 이름을 생성한다 (예: "목·어깨 집중 이완", "전신 피로 해소 코스").\n'
        '7. **코스 요약**: 전체 코스의 목적과 흐름을 한국어로 2~3문장으로 요약한다.\n'
        '\n'
        '## 응답 형식\n'
        '\n'
        '반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트는 포함하지 마세요.\n'
        '도구 선택은 시스템이 자동으로 처리하므로, 응답에 도구 정보를 포함하지 마세요.';
  }

  /// 유저 프롬프트를 생성한다.
  String buildUserPrompt({
    required List<Move> candidates,
    required CourseRequest request,
  }) {
    final buffer = StringBuffer();

    // 1. 입력 조건
    buffer.writeln('## 입력 조건');
    buffer.writeln();
    buffer.writeln('### 피로 부위 (구역: 피로도 1~5)');
    for (final entry in request.fatigueEntries) {
      final bodyNames = entry.bodyIndexes
          .map((i) => kBodies[i]?.name ?? '$i')
          .join(', ');
      buffer.writeln('- ${entry.displayLabel}: 피로도 ${entry.level} → 포함 근육: $bodyNames');
    }
    buffer.writeln();

    buffer.writeln('### 보유 도구');
    for (final toolIndex in request.ownedTools) {
      final tool = kTools[toolIndex];
      buffer.writeln('- 도구 $toolIndex (${tool?.displayName ?? "알 수 없음"})');
    }
    buffer.writeln();

    buffer.writeln('### 가용 시간: ${request.availableTime}초 (${(request.availableTime / 60).toStringAsFixed(1)}분)');
    buffer.writeln();

    // 2. 후보 동작 목록
    buffer.writeln('## 후보 동작 목록');
    buffer.writeln();
    for (final move in candidates) {
      final bodyNames = move.body
          .map((i) => kBodies[i]?.name ?? '$i')
          .join(', ');
      buffer.writeln('### 동작 ${move.index}: ${move.name}');
      buffer.writeln('- 자세: ${move.posture.label}');
      buffer.writeln('- 부위: $bodyNames');
      buffer.writeln('- 시간 범위: ${move.time.min}~${move.time.max}초');
      buffer.writeln();
    }

    // 3. 지시
    buffer.writeln('## 지시');
    buffer.writeln();
    buffer.writeln('위 후보 동작들 중에서 적절한 동작을 선택하여 코스를 편성하세요.');
    buffer.writeln('가용 시간 ${request.availableTime}초에 맞추어 편성하되, 피로도가 높은 부위에 더 많은 시간을 배분하세요.');
    buffer.writeln('moveIndex에는 반드시 위 후보 동작 목록의 동작 번호를 사용하세요.');

    return buffer.toString();
  }

  /// OpenAI structured output용 JSON schema를 반환한다.
  Map<String, dynamic> buildResponseSchema() {
    return {
      'name': 'course_response',
      'strict': true,
      'schema': {
        'type': 'object',
        'properties': {
          'name': {
            'type': 'string',
            'description': '코스 이름 (한국어, 짧고 직관적으로. 예: "목·어깨 집중 이완")',
          },
          'steps': {
            'type': 'array',
            'description': '코스를 구성하는 동작 단계들 (순서대로)',
            'items': {
              'type': 'object',
              'properties': {
                'moveIndex': {
                  'type': 'integer',
                  'description': '동작 인덱스 (후보 목록의 동작 번호, 예: 1, 3, 19 등)',
                },
                'duration': {
                  'type': 'integer',
                  'description': '배정 시간(초). 해당 동작의 time.min~time.max 범위 내.',
                },
                'reason': {
                  'type': 'string',
                  'description': '이 동작을 선택한 이유 (한국어, 1~2문장)',
                },
              },
              'required': ['moveIndex', 'duration', 'reason'],
              'additionalProperties': false,
            },
          },
          'totalDuration': {
            'type': 'integer',
            'description': '총 소요 시간(초). 모든 step의 duration 합.',
          },
          'summary': {
            'type': 'string',
            'description': '코스 전체 요약 (한국어, 2~3문장)',
          },
        },
        'required': ['name', 'steps', 'totalDuration', 'summary'],
        'additionalProperties': false,
      },
    };
  }

  /// 프롬프트 전체를 빌드하여 (systemPrompt, userPrompt, schema) 튜플로 반환한다.
  ({String system, String user, Map<String, dynamic> schema}) build({
    required List<Move> candidates,
    required CourseRequest request,
  }) {
    return (
      system: buildSystemPrompt(),
      user: buildUserPrompt(candidates: candidates, request: request),
      schema: buildResponseSchema(),
    );
  }
}
