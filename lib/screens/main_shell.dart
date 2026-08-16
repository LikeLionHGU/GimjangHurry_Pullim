import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../providers/app_provider.dart';
import 'home/home_screen.dart';
import 'library/library_screen.dart';
import 'mypage/mypage_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currentIndex = provider.currentNavIndex;

    final screens = [
      const HomeScreen(),
      const LibraryScreen(),
      const MypageScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => provider.setNavIndex(index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books),
              label: AppStrings.navLibrary,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: AppStrings.navMypage,
            ),
          ],
        ),
      ),
    );
  }
}
