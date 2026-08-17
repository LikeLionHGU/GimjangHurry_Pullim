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

  final toolService = ToolRegistrationService();
  final onboardingDone = await toolService.isOnboardingComplete();

  runApp(MyApp(showOnboarding: !onboardingDone));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.showOnboarding});

  final bool showOnboarding;

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
            // 온보딩 미완료 시 온보딩 화면 (서비스 소개 → 도구 등록)
            if (showOnboarding) {
              return const OnboardingScreen();
            }
            return const MainShell();
          },
        ),
      ),
    );
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
