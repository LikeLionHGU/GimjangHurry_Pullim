// 온보딩에서 사용자가 등록한 도구 목록을 DB에 저장하고 조회하는 서비스.
// 온보딩 완료 플래그만 SharedPreferences에 저장한다.

import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

/// 도구 등록 서비스.
class ToolRegistrationService {
  static const _keyOnboardingComplete = 'onboarding_complete';

  final DatabaseHelper _db = DatabaseHelper();

  /// 등록된 도구 인덱스 목록을 DB owned_tools 테이블에 저장한다.
  /// tool_assets의 인덱스(1~12)를 그대로 tool_id로 사용한다.
  Future<void> saveRegisteredTools(List<int> indexes) async {
    final db = await _db.database;

    // 기존 보유 도구 초기화 후 새로 등록 (단일 사용자, userId=1)
    const userId = 1;
    await db.delete('owned_tools', where: 'user_id = ?', whereArgs: [userId]);

    for (final toolIndex in indexes) {
      await db.insert('owned_tools', {
        'user_id': userId,
        'tool_id': toolIndex,
      });
    }
  }

  /// 저장된 등록 도구 인덱스 목록을 DB에서 반환한다. 없으면 빈 리스트.
  Future<List<int>> getRegisteredTools() async {
    final db = await _db.database;

    const userId = 1;
    final maps = await db.query(
      'owned_tools',
      columns: ['tool_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return maps.map((m) => m['tool_id'] as int).toList();
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
