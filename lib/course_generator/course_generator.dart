import '../assets/move_assets.dart';
import 'models/course.dart';
import 'models/course_request.dart';
import 'move_filter.dart';
import 'openai_client.dart';
import 'prompt_builder.dart';
import 'response_parser.dart';

/// AI 기반 근막이완 코스 생성 엔진.
///
/// 로컬 필터링으로 후보 동작을 좁힌 뒤,
/// OpenAI LLM이 최종 동작 선택/순서/시간 배분/선택 이유를 결정한다.
///
/// ```dart
/// final generator = CourseGenerator();
/// final course = await generator.generateCourse(
///   CourseRequest(
///     fatigueMap: {23: 4, 25: 3, 35: 5},
///     ownedTools: [11, 7, 2],
///     availableTime: 1200,
///   ),
/// );
/// print(course.summary);
/// ```
class CourseGenerator {
  CourseGenerator({
    MoveFilter? moveFilter,
    PromptBuilder? promptBuilder,
    OpenAiClient? openAiClient,
    ResponseParser? responseParser,
  })  : _moveFilter = moveFilter ?? const MoveFilter(),
        _promptBuilder = promptBuilder ?? const PromptBuilder(),
        _openAiClient = openAiClient ?? OpenAiClient(),
        _responseParser = responseParser ?? const ResponseParser();

  final MoveFilter _moveFilter;
  final PromptBuilder _promptBuilder;
  final OpenAiClient _openAiClient;
  final ResponseParser _responseParser;

  /// 코스를 생성한다.
  ///
  /// 1. 입력 조건으로 후보 동작을 필터링
  /// 2. 후보 동작 + 조건을 프롬프트로 변환
  /// 3. OpenAI API 호출
  /// 4. 응답을 파싱하고 유효성 검증
  ///
  /// 후보 동작이 없으면 [NoCandidatesException]을 던진다.
  /// API 호출 실패 시 [OpenAiException]을 던진다.
  /// 유효성 검증 실패 시 [CourseValidationException]을 던진다.
  Future<Course> generateCourse(CourseRequest request) async {
    // 1. 후보 동작 필터링
    final candidates = _moveFilter.filterCandidates(request);

    if (candidates.isEmpty) {
      throw NoCandidatesException(
        '조건에 맞는 후보 동작이 없습니다.\n'
        '피로 부위: ${request.fatigueMap.keys.toList()}\n'
        '보유 도구: ${request.ownedTools}',
      );
    }

    // 2. 프롬프트 빌드
    final prompt = _promptBuilder.build(
      candidates: candidates,
      request: request,
    );

    // 3. OpenAI API 호출
    final responseJson = await _openAiClient.chatCompletion(
      systemPrompt: prompt.system,
      userPrompt: prompt.user,
      jsonSchema: prompt.schema,
    );

    // 4. 응답 파싱 및 유효성 검증
    final course = _responseParser.parseResponse(responseJson, request);

    return course;
  }

  /// 후보 동작만 반환한다 (디버깅/미리보기용).
  List<Move> previewCandidates(CourseRequest request) {
    return _moveFilter.filterCandidates(request);
  }

  /// 리소스 정리.
  void dispose() {
    _openAiClient.dispose();
  }
}

/// 조건에 맞는 후보 동작이 없을 때의 예외.
class NoCandidatesException implements Exception {
  const NoCandidatesException(this.message);

  final String message;

  @override
  String toString() => 'NoCandidatesException: $message';
}
