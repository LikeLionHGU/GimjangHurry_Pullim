import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  /// Google 로그인
  Future<User?> signInWithGoogle() async {
    try {
      // Google 로그인 플로우
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // 사용자가 취소

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase credential 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase 로그인
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      // 에러 발생 시 null 반환
      return null;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.disconnect(); // 계정 연결 해제 (다음 로그인 시 계정 선택 화면 표시)
    await _auth.signOut();
  }

  /// 현재 사용자 이름
  String? get displayName => currentUser?.displayName;

  /// 현재 사용자 이메일
  String? get email => currentUser?.email;
}
