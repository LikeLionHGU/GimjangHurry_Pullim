import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
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

  /// 이름 기반 등록 (첫 접속 시 이름 입력)
  Future<void> login(String name, String email) async {
    final userId = await _db.insertUser(UserModel(
      name: name,
      email: email,
    ));
    final user = UserModel(userId: userId, name: name, email: email);

    _currentUser = user;
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_user_id', user.userId!);

    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }
}
