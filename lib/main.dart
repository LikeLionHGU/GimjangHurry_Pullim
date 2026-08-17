import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_colors.dart';
import 'constants/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/main_shell.dart';
import 'screens/onboard/onboarding_screen.dart';
import 'course_generator/env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        home: const SplashScreen(),
      ),
    );
  }
}

/// 스플래시 화면: 로고 표시 후 자동으로 다음 화면으로 이동
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // 로고를 2초 보여준 후 이동
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final provider = context.read<AppProvider>();

    // Provider가 아직 로딩 중이면 완료될 때까지 대기
    while (provider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (!mounted) return;

    // DB에 사용자가 있으면 홈, 없으면 온보딩
    final destination = provider.isLoggedIn
        ? const MainShell()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'PULLIM',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
