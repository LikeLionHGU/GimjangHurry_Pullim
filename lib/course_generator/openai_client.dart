import 'dart:convert';

import 'package:http/http.dart' as http;

import 'env_loader.dart';

/// OpenAI Chat Completions API 호출을 담당하는 클라이언트.
///
/// API 키 로드 순서:
/// 1. 시스템 환경변수 `OPENAI_API_KEY`
/// 2. 프로젝트 루트 `.env` 파일의 `OPENAI_API_KEY`
class OpenAiClient {
  OpenAiClient({
    http.Client? httpClient,
    this.model = 'gpt-4o',
  }) : _httpClient = httpClient ?? http.Client();

  static const _baseUrl = 'https://api.openai.com/v1/chat/completions';

  final http.Client _httpClient;
  final String model;

  /// API 키를 가져온다. 환경변수 → .env 순서. 없으면 예외를 던진다.
  String get _apiKey => EnvLoader.require('OPENAI_API_KEY');

  /// Chat Completions API를 호출하고 응답 JSON을 반환한다.
  ///
  /// [systemPrompt]: 시스템 메시지.
  /// [userPrompt]: 유저 메시지.
  /// [jsonSchema]: structured output을 위한 JSON schema.
  ///
  /// 반환값은 응답의 content를 파싱한 Map.
  Future<Map<String, dynamic>> chatCompletion({
    required String systemPrompt,
    required String userPrompt,
    required Map<String, dynamic> jsonSchema,
  }) async {
    final requestBody = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'response_format': {
        'type': 'json_schema',
        'json_schema': jsonSchema,
      },
      'temperature': 0.7,
    };

    final response = await _httpClient.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      _handleError(response);
    }

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = responseJson['choices'] as List<dynamic>;

    if (choices.isEmpty) {
      throw OpenAiException('OpenAI 응답에 choices가 비어있습니다.');
    }

    final message = choices[0]['message'] as Map<String, dynamic>;
    final content = message['content'] as String?;

    if (content == null || content.isEmpty) {
      throw OpenAiException('OpenAI 응답의 content가 비어있습니다.');
    }

    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw OpenAiException(
        'OpenAI 응답 JSON 파싱 실패: ${e.message}\nContent: $content',
      );
    }
  }

  /// HTTP 에러 응답을 처리한다.
  Never _handleError(http.Response response) {
    final statusCode = response.statusCode;
    String message;

    try {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      final error = errorJson['error'] as Map<String, dynamic>?;
      message = error?['message'] as String? ?? response.body;
    } catch (_) {
      message = response.body;
    }

    switch (statusCode) {
      case 401:
        throw OpenAiException('인증 실패: API 키가 유효하지 않습니다. ($message)');
      case 429:
        throw OpenAiException('요청 한도 초과: 잠시 후 다시 시도해주세요. ($message)');
      case 500:
      case 502:
      case 503:
        throw OpenAiException('OpenAI 서버 오류 ($statusCode): $message');
      default:
        throw OpenAiException('HTTP $statusCode 오류: $message');
    }
  }

  /// 리소스 정리.
  void dispose() {
    _httpClient.close();
  }
}

/// OpenAI API 관련 예외.
class OpenAiException implements Exception {
  const OpenAiException(this.message);

  final String message;

  @override
  String toString() => 'OpenAiException: $message';
}
