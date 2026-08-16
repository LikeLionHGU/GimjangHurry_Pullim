import 'dart:io';

/// 프로젝트 루트의 `.env` 파일에서 환경변수를 로드하는 유틸리티.
///
/// 로드 순서:
/// 1. `.env` 파일이 있으면 파싱
/// 2. 시스템 환경변수(`Platform.environment`)가 우선 (덮어쓰기 안 함)
///
/// ```
/// // .env
/// OPENAI_API_KEY=sk-abc123...
/// ```
class EnvLoader {
  EnvLoader._();

  static final Map<String, String> _values = {};
  static bool _loaded = false;

  /// `.env` 파일을 로드한다. 여러 번 호출해도 한 번만 실행된다.
  static void load([String path = '.env']) {
    if (_loaded) return;
    _loaded = true;

    final file = File(path);
    if (!file.existsSync()) return;

    final lines = file.readAsLinesSync();
    for (final line in lines) {
      final trimmed = line.trim();
      // 빈 줄, 주석 건너뛰기
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final eqIndex = trimmed.indexOf('=');
      if (eqIndex <= 0) continue;

      final key = trimmed.substring(0, eqIndex).trim();
      var value = trimmed.substring(eqIndex + 1).trim();

      // 따옴표 제거
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }

      _values[key] = value;
    }
  }

  /// 키에 해당하는 값을 반환한다.
  /// 시스템 환경변수가 우선이고, 없으면 `.env` 파일 값을 반환한다.
  static String? get(String key) {
    return Platform.environment[key] ?? _values[key];
  }

  /// 키에 해당하는 값을 반환하되, 없으면 예외를 던진다.
  static String require(String key) {
    final value = get(key);
    if (value == null || value.isEmpty) {
      throw EnvException(
        '$key가 설정되지 않았습니다.\n'
        '.env 파일에 $key=... 을 추가하거나, '
        'export $key="..." 로 환경변수를 설정해주세요.',
      );
    }
    return value;
  }
}

/// 환경변수 관련 예외.
class EnvException implements Exception {
  const EnvException(this.message);
  final String message;

  @override
  String toString() => 'EnvException: $message';
}
