import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
import 'course_generator/env_loader.dart';
import 'screens/body_selection_screen.dart';
import 'screens/tool_registration_screen.dart';
import 'services/tool_registration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일에서 API 키 로드
  await EnvLoader.load();

  final service = ToolRegistrationService();
  final onboardingDone = await service.isOnboardingComplete();

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
    return MaterialApp(
      title: '김장허리 풀림',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFBBFF00),
          secondary: const Color(0xFFBBFF00),
          surface: Colors.grey[900]!,
        ),
      ),
      // Named route '/'는 HomePage로 설정.
      // 온보딩 미완료 시 initialRoute를 '/onboarding'으로 변경.
      initialRoute: showOnboarding ? '/onboarding' : '/',
      routes: {
        '/': (context) => const HomePage(),
        '/onboarding': (context) => const ToolRegistrationScreen(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BodySelectionScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBBFF00),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '부위 선택하기',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
