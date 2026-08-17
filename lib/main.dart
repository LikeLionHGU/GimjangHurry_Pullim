import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboard/onboarding_screen.dart';
import 'course_generator/env_loader.dart';
import 'services/tool_registration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await EnvLoader.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: MaterialApp(
        title: '풀림',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Consumer<AppProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const _SplashScreen();
            }
            if (!provider.isLoggedIn) {
              return const LoginScreen();
            }
            // 로그인 후 매번 온보딩 상태 체크
            return const _OnboardingChecker();
          },
        ),
      ),
    );
  }
}

/// 로그인 후 온보딩 완료 여부를 체크해서 적절한 화면을 보여주는 위젯
class _OnboardingChecker extends StatefulWidget {
  const _OnboardingChecker();

  @override
  State<_OnboardingChecker> createState() => _OnboardingCheckerState();
}

class _OnboardingCheckerState extends State<_OnboardingChecker> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final provider = context.read<AppProvider>();
    final email = provider.currentUser?.email;
    final toolService = ToolRegistrationService();
    final done = await toolService.isOnboardingCompleteForUser(email);
    if (mounted) {
      setState(() => _onboardingDone = done);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      // 아직 확인 중
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_onboardingDone!) {
      return const OnboardingScreen();
    }
    return const MainShell();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          '풀림',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
