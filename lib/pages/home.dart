import 'package:flutter/material.dart';
import '../components/bottom_nav.dart';
import '../components/header.dart';

import 'profile.dart';
import 'post.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int currentIndex = 0;

  /// 页面列表
  late final List<Widget> pages = [
    const _EmptyPage(title: "Board"),

    const _EmptyPage(title: "Active"),

    /// POST PAGE
    PostPage(
      onPosted: () {
        setState(() {
          currentIndex = 0;
        });
      },
    ),

    /// PROFILE
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),

      /// 当前页面
      body: Column(
        children: [
          /// Profile 页面不显示 Header
          if (currentIndex != 3) const HomeHeader(),

          /// 页面内容
          Expanded(child: pages[currentIndex]),
        ],
      ),

      /// 底部导航栏
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

/// 临时空页面
class _EmptyPage extends StatelessWidget {
  final String title;

  const _EmptyPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF020617),

      child: Center(
        child: Text(
          "$title Page",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
