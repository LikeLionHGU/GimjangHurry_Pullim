// 온보딩에서 사용자가 등록한 도구 목록을 로컬(SharedPreferences)에
// 저장하고 조회하는 서비스 레이어.
// UI(화면)와 데이터 영속화(저장소) 사이의 중간 계층 역할을 한다.

import 'package:shared_preferences/shared_preferences.dart';

/// 도구 등록 정보를 SharedPreferences에 저장/조회하는 서비스.
class ToolRegistrationService {
  static const _keyRegisteredTools = 'registered_tool_indexes';
  static const _keyOnboardingComplete = 'onboarding_complete';

  /// 등록된 도구 인덱스 목록을 저장한다.
  Future<void> saveRegisteredTools(List<int> indexes) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = indexes.map((i) => i.toString()).toList();
    await prefs.setStringList(_keyRegisteredTools, stringList);
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
