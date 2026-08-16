import 'package:flutter_dotenv/flutter_dotenv.dart';

/// .env 파일에서 환경변수를 로드하는 유틸리티.
///
/// flutter_dotenv을 사용하여 Flutter 앱(모바일/웹/데스크톱) 환경에서 동작한다.
/// .env 파일은 pubspec.yaml의 assets에 등록되어야 한다.
class EnvLoader {
  EnvLoader._();

  static bool _loaded = false;

  /// .env 파일을 로드한다. 여러 번 호출해도 한 번만 실행된다.
  /// Flutter 앱에서는 main() 또는 사용 전에 await로 호출해야 한다.
  static Future<void> load([String path = '.env']) async {
    if (_loaded) return;
    _loaded = true;
    await dotenv.load(fileName: path);
  }

  /// 동기적 로드 (이미 로드된 경우에만 안전).
  /// CLI 호환성을 위해 유지. 이미 load()가 호출된 상태에서만 사용한다.
  static void loadSync([String path = '.env']) {
    // flutter_dotenv는 비동기만 지원하므로, 이미 로드된 상태인지 확인.
    if (!_loaded) {
      throw EnvException(
        'EnvLoader.load()를 먼저 await로 호출해주세요.',
      );
    }
  }

  /// 키에 해당하는 값을 반환한다.
  static String? get(String key) {
    return dotenv.env[key];
  }

  /// 키에 해당하는 값을 반환하되, 없으면 예외를 던진다.
  static String require(String key) {
    final value = dotenv.env[key];
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
  String toString() => 'EnvException: \$message';
}
