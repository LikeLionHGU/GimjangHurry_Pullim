// 온보딩에서 사용자가 등록한 도구 목록을 로컬에 저장하고 조회하는 서비스.
// SharedPreferences(온보딩 상태) + SQLite(도구 데이터) 이중 저장.

import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

/// 도구 등록 서비스.
class ToolRegistrationService {
  static const _keyRegisteredTools = 'registered_tool_indexes';
  static const _keyOnboardingComplete = 'onboarding_complete';

  final DatabaseHelper _db = DatabaseHelper();

  /// 등록된 도구 인덱스 목록을 SharedPreferences + SQLite에 저장한다.
  Future<void> saveRegisteredTools(List<int> indexes) async {
    // SharedPreferences에 저장 (기존 호환)
    final prefs = await SharedPreferences.getInstance();
    final stringList = indexes.map((i) => i.toString()).toList();
    await prefs.setStringList(_keyRegisteredTools, stringList);

    // SQLite owned_tools 테이블에도 저장
    // 사용자 ID는 1로 고정 (단일 사용자 로컬 앱)
    const userId = 1;

    // 기존 보유 도구 초기화 후 새로 등록
    final db = await _db.database;
    await db.delete('owned_tools', where: 'user_id = ?', whereArgs: [userId]);

    for (final toolIndex in indexes) {
      // tool_assets의 인덱스를 DB의 tool_id로 매핑
      // DB tools 테이블은 1~11 (폼롤러6 + 마사지볼5)
      // tool_assets는 1~12 (폼롤러6 + 마사지볼5 + 스틱1)
      // 직접 인덱스를 tool_id로 사용
      await db.insert('owned_tools', {
        'user_id': userId,
        'tool_id': toolIndex,
      });
    }
  }

  /// 저장된 등록 도구 인덱스 목록을 반환한다. 없으면 빈 리스트.
  Future<List<int>> getRegisteredTools() async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList(_keyRegisteredTools);
    if (stringList == null) return [];
    return stringList.map((s) => int.parse(s)).toList();
  }

  /// 온보딩(도구 등록)이 완료되었는지 확인한다.
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  /// 온보딩 완료 플래그를 설정한다.
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, true);
  }
}
