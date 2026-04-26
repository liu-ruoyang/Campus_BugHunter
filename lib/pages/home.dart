import 'package:flutter/material.dart';
import '../components/bottom_nav.dart';
import 'profile.dart';
import '../components/header.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    _EmptyPage(title: "Board"),
    _EmptyPage(title: "Active"),
    _EmptyPage(title: "Post"),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),

      /// 当前页面
      body: Column(
        children: [
          if (currentIndex != 3) const HomeHeader(), // ❗ Profile=3

          Expanded(
            child: pages[currentIndex],
          ),
        ],
      ),

      /// 底部导航
      bottomNavigationBar: BottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}

/// 🔥 通用占位页面（以后直接替换）
class _EmptyPage extends StatelessWidget {
  final String title;

  const _EmptyPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container( // ✅ 不用 Scaffold
      color: const Color(0xFF020617),
      child: Center(
        child: Text(
          "$title Page",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}