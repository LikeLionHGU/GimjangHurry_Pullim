// 온보딩에서 사용자가 등록한 도구 목록을 로컬에 저장하고 조회하는 서비스.

import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

/// 도구 등록 서비스.
class ToolRegistrationService {
  static const _keyRegisteredTools = 'registered_tool_indexes';
  static const _keyOnboardingPrefix = 'onboarding_complete_';

  final DatabaseHelper _db = DatabaseHelper();

  /// 현재 로그인된 사용자의 이메일을 기반으로 온보딩 키 생성
  String _onboardingKey(String? email) {
    if (email == null || email.isEmpty) return 'onboarding_complete_default';
    return '$_keyOnboardingPrefix$email';
  }

  /// 등록된 도구 인덱스 목록을 SharedPreferences + SQLite에 저장한다.
  Future<void> saveRegisteredTools(List<int> indexes) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = indexes.map((i) => i.toString()).toList();
    await prefs.setStringList(_keyRegisteredTools, stringList);

    // SQLite owned_tools 테이블에도 저장
    const userId = 1;
    final db = await _db.database;
    await db.delete('owned_tools', where: 'user_id = ?', whereArgs: [userId]);

    for (final toolIndex in indexes) {
      await db.insert('owned_tools', {
        'user_id': userId,
        'tool_id': toolIndex,
      });
    }
  }

  /// 저장된 등록 도구 인덱스 목록을 반환한다.
  Future<List<int>> getRegisteredTools() async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList(_keyRegisteredTools);
    if (stringList == null) return [];
    return stringList.map((s) => int.parse(s)).toList();
  }

  /// 해당 사용자의 온보딩이 완료되었는지 확인한다.
  Future<bool> isOnboardingCompleteForUser(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey(email)) ?? false;
  }

  /// 기존 호환: 기본 키로 체크 (로그인 전 호출용)
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    // 아무 사용자든 온보딩 완료한 적 있으면 true (하위 호환)
    return prefs.getBool('onboarding_complete') ?? false;
  }

  /// 해당 사용자의 온보딩 완료 플래그를 설정한다.
  Future<void> completeOnboardingForUser(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey(email), true);
    // 하위 호환용 글로벌 키도 설정
    await prefs.setBool('onboarding_complete', true);
  }

  /// 기존 호환: 글로벌 온보딩 완료
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }
}
