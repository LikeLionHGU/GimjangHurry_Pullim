import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  bool _isLoading = true;
  bool _isLoggedIn = false;
  UserModel? _currentUser;
  int _currentNavIndex = 0;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  UserModel? get currentUser => _currentUser;
  int get currentNavIndex => _currentNavIndex;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');

      if (userId != null) {
        _currentUser = await _db.getUser(userId);
        _isLoggedIn = _currentUser != null;
      }
    } catch (_) {
      // 첫 실행 시 DB 초기화
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String name, String email) async {
    // 기존 유저 확인
    var user = await _db.getUserByEmail(email);

    if (user == null) {
      // 새 유저 생성
      final userId = await _db.insertUser(UserModel(
        name: name,
        email: email,
      ));
      user = UserModel(userId: userId, name: name, email: email);
    }

    _currentUser = user;
    _isLoggedIn = true;

    // 로그인 상태 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_user_id', user.userId!);

    notifyListeners();
  }

  Future<void> logout() async {
    // Google 로그인 연결 해제 + Firebase 로그아웃
    final authService = AuthService();
    await authService.signOut();

    _currentUser = null;
    _isLoggedIn = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');

    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }
}
