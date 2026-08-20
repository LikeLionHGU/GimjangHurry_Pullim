import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_colors.dart';
import 'constants/app_theme.dart';
import 'constants/app_typography.dart';
import 'providers/app_provider.dart';
import 'screens/main_shell.dart';
import 'screens/onboard/onboarding_screen.dart';
import 'course_generator/env_loader.dart';
import 'services/tool_registration_service.dart';

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

    while (provider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (!mounted) return;

    Widget destination;
    if (!provider.isLoggedIn) {
      destination = const OnboardingScreen();
    } else {
      final toolService = ToolRegistrationService();
      final userName = provider.currentUser?.name ?? '';
      final onboardingDone = await toolService.isOnboardingCompleteForUser(userName);
      if (onboardingDone) {
        destination = const MainShell();
      } else {
        destination = const OnboardingIntroScreen();
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF010101),
              Color(0xFF010101),
              Color(0xFF161D02),
            ],
            stops: [0.0, 0.0, 1.0],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                ),
                Text(
                  'PULLIM',
                  style: AppTypography.b20.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
